from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.pagination import PageNumberPagination

from apps.users.models import User
from .models import ServiceCategory, WorkerProfile
from .serializers import (
    ServiceCategorySerializer,
    WorkerProfileSerializer,
    WorkerProfileWriteSerializer,
)


#  Pagination

class WorkerPagination(PageNumberPagination):
    """
    Pagination for the workers list.
    Default: 10 per page. Client can request up to 50 with ?page_size=N.
    """
    page_size = 10
    page_size_query_param = "page_size"   # ?page_size=20
    max_page_size = 50


#  Service Categories

class CategoryListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        categories = ServiceCategory.objects.all()
        return Response(ServiceCategorySerializer(categories, many=True).data)


class CategoryCreateView(APIView):
    """POST /api/categories/create/ — admin only"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response(
                {"error": "Only admins can create categories."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = ServiceCategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Worker Profiles ───────────────────────────────────────────────────

class WorkerListView(APIView):
    """
    GET /api/workers/

    Returns available workers, sorted by score descending.

    Optional query params:
        ?category=<id>      filter by service category ID
        ?search=<text>      filter by profession keyword (case-insensitive)
        ?page=<n>           page number (default 1)
        ?page_size=<n>      results per page (default 10, max 50)

    Score formula: (average_rating × 0.6) + (completed_jobs × 0.4)
    """
    
    permission_classes = [AllowAny]

    def get(self, request):
        queryset = WorkerProfile.objects.select_related("user").filter(
            user__is_active = True,
            user__role  = User.Role.WORKER,
            is_available  = True,
        )

        # ── Filter by category (optional) ────────────────────────────
        category_id = request.query_params.get("category")
        if category_id:
            try:
                category = ServiceCategory.objects.get(pk=category_id)
            except ServiceCategory.DoesNotExist:
                return Response(
                    {"error": f"Category with id={category_id} does not exist."},
                    status=status.HTTP_404_NOT_FOUND,
                )
            # Match workers whose profession matches the category name
            queryset = queryset.filter(profession__iexact=category.name)

        # ── Filter by search keyword (optional) ──────────────────────
        search = request.query_params.get("search")
        if search:
            queryset = queryset.filter(profession__icontains=search)

        
        sorted_workers = sorted(
            queryset,
            key=lambda p: p.calculate_score(),
            reverse=True,   # highest score first
        )

        # ── Paginate ──────────────────────────────────────────────────
        paginator = WorkerPagination()
        page  = paginator.paginate_queryset(sorted_workers, request)

        serializer = WorkerProfileSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class WorkerCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can create a worker profile."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = WorkerProfileWriteSerializer(
            data=request.data,
            context={"request": request},
        )
        if serializer.is_valid():
            profile = serializer.save()
            return Response(
                WorkerProfileSerializer(profile).data,
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class WorkerDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            worker = WorkerProfile.objects.select_related("user").get(pk=pk)
        except WorkerProfile.DoesNotExist:
            return Response(
                {"error": "Worker not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(WorkerProfileSerializer(worker).data)


class MyWorkerProfileView(APIView):
    """
    GET   /api/workers/me/ — see my own worker profile
    PATCH /api/workers/me/ — update my own worker profile
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers have a worker profile."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not hasattr(request.user, "worker_profile"):
            return Response(
                {"error": "You do not have a worker profile yet."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(WorkerProfileSerializer(request.user.worker_profile).data)

    def patch(self, request):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can update a worker profile."},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not hasattr(request.user, "worker_profile"):
            return Response(
                {"error": "You do not have a worker profile yet."},
                status=status.HTTP_404_NOT_FOUND,
            )
        serializer = WorkerProfileWriteSerializer(
            request.user.worker_profile,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        if serializer.is_valid():
            serializer.save()
            return Response(WorkerProfileSerializer(request.user.worker_profile).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
