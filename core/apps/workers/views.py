from django.db.models import Avg, Count, F, FloatField, Q
from django.db.models.functions import Coalesce
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.pagination import PageNumberPagination

from apps.orders.models import Order
from apps.ratings.models import Rating
from apps.users.models import User
from core.permissions import IsAdmin, IsWorker
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
    permission_classes = [IsAuthenticated, IsAdmin]

    def post(self, request):
        serializer = ServiceCategorySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ── Worker Profiles ───────────────────────────────────────────────────

class WorkerListView(APIView):
    """
    GET /api/workers/

    Returns available workers ranked by score (DB-level, paginated correctly).

    Optional query params:
        ?category=<id>             filter by service category ID
        ?search=<text>             match profession or username (case-insensitive)
        ?min_rating=<float>        only workers with average_rating >= n
        ?available=<true|false>    override the default availability filter
        ?ordering=<field>          one of: score (default), -score,
                                   rating, -rating, jobs, -jobs, recent
        ?page=<n>                  page number (default 1)
        ?page_size=<n>             results per page (default 10, max 50)

    Score formula: (average_rating × 0.6) + (completed_jobs × 0.4)
    """

    permission_classes = [AllowAny]

    ORDERING_MAP = {
        "score": "-score",
        "-score": "score",
        "rating": "-average_rating",
        "-rating": "average_rating",
        "jobs": "-completed_jobs",
        "-jobs": "completed_jobs",
        "recent": "-created_at",
    }

    def get(self, request):
        queryset = WorkerProfile.objects.select_related("user").filter(
            user__is_active=True,
            user__role=User.Role.WORKER,
        )

        available = request.query_params.get("available")
        if available is None or available.lower() in {"1", "true", "yes"}:
            queryset = queryset.filter(is_available=True)
        elif available.lower() in {"0", "false", "no"}:
            queryset = queryset.filter(is_available=False)

        category_id = request.query_params.get("category")
        if category_id:
            try:
                category = ServiceCategory.objects.get(pk=category_id)
            except ServiceCategory.DoesNotExist:
                return Response(
                    {"error": f"Category with id={category_id} does not exist."},
                    status=status.HTTP_404_NOT_FOUND,
                )
            queryset = queryset.filter(profession__iexact=category.name)

        search = request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(profession__icontains=search)
                | Q(user__username__icontains=search)
            )

        min_rating = request.query_params.get("min_rating")
        if min_rating:
            try:
                queryset = queryset.filter(average_rating__gte=float(min_rating))
            except ValueError:
                return Response(
                    {"error": "min_rating must be a number."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        # Annotate score at the DB level so ORDER BY + LIMIT/OFFSET stay consistent
        queryset = queryset.annotate(
            score=(F("average_rating") * 0.6) + (F("completed_jobs") * 0.4),
        )

        ordering_param = request.query_params.get("ordering", "score")
        ordering = self.ORDERING_MAP.get(ordering_param, "-score")
        queryset = queryset.order_by(ordering, "-id")

        paginator = WorkerPagination()
        page = paginator.paginate_queryset(queryset, request)

        serializer = WorkerProfileSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class WorkerStatsView(APIView):
    """GET /api/workers/<id>/stats/ — analytics for a single worker."""

    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            profile = WorkerProfile.objects.select_related("user").get(pk=pk)
        except WorkerProfile.DoesNotExist:
            return Response(
                {"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND,
            )

        worker_user = profile.user

        order_stats = Order.objects.filter(worker=worker_user).aggregate(
            total=Count("id"),
            accepted=Count("id", filter=Q(status=Order.ACCEPTED)),
            completed=Count("id", filter=Q(status=Order.COMPLETED)),
            rejected=Count("id", filter=Q(status=Order.REJECTED)),
        )

        rating_stats = Rating.objects.filter(worker=worker_user).aggregate(
            count=Count("id"),
            avg=Coalesce(Avg("stars"), 0.0, output_field=FloatField()),
        )

        # Star distribution (1-5)
        distribution = {str(i): 0 for i in range(1, 6)}
        for row in (
            Rating.objects.filter(worker=worker_user)
            .values("stars")
            .annotate(c=Count("id"))
        ):
            distribution[str(row["stars"])] = row["c"]

        total = order_stats["total"] or 0
        acceptance_rate = (
            round(((order_stats["accepted"] or 0) + (order_stats["completed"] or 0)) / total * 100, 1)
            if total else 0.0
        )

        return Response({
            "worker_id": profile.id,
            "username": worker_user.username,
            "profession": profile.profession,
            "experience_years": profile.experience_years,
            "is_available": profile.is_available,
            "orders": {
                "total": total,
                "accepted": order_stats["accepted"] or 0,
                "completed": order_stats["completed"] or 0,
                "rejected": order_stats["rejected"] or 0,
                "acceptance_rate": acceptance_rate,
            },
            "ratings": {
                "count": rating_stats["count"] or 0,
                "average": round(rating_stats["avg"] or 0, 2),
                "distribution": distribution,
            },
            "score": round(profile.calculate_score(), 2),
        })


class MyWorkerStatsView(APIView):
    """GET /api/workers/me/stats/ — performance summary for the
    currently-authenticated worker. Powers the dashboard card on the
    new mobile worker home screen.

    Returns counts (lifetime + this-month) for the things a worker
    actually cares about — completed jobs, pending requests, current
    average rating, last few customer reviews. There is no money
    figure: the platform takes a commission at order time but the
    job cash itself is settled in person.
    """

    permission_classes = [IsAuthenticated, IsWorker]

    def get(self, request):
        user = request.user
        profile = getattr(user, "worker_profile", None)
        if profile is None:
            return Response(
                {"error": "Set up your worker profile first."},
                status=status.HTTP_404_NOT_FOUND,
            )

        now = timezone.now()
        month_start = now.replace(
            day=1, hour=0, minute=0, second=0, microsecond=0,
        )

        all_orders = Order.objects.filter(worker=user)
        month_orders = all_orders.filter(created_at__gte=month_start)

        lifetime = all_orders.aggregate(
            total=Count("id"),
            completed=Count("id", filter=Q(status=Order.COMPLETED)),
            accepted=Count("id", filter=Q(status=Order.ACCEPTED)),
            pending=Count("id", filter=Q(status=Order.PENDING)),
            rejected=Count("id", filter=Q(status=Order.REJECTED)),
            cancelled=Count("id", filter=Q(status=Order.CANCELLED)),
        )
        this_month = month_orders.aggregate(
            total=Count("id"),
            completed=Count("id", filter=Q(status=Order.COMPLETED)),
        )

        recent_ratings = list(
            Rating.objects.filter(worker=user)
            .select_related("client")
            .order_by("-created_at")
            .values("stars", "review", "created_at", "client__username")[:5]
        )
        for r in recent_ratings:
            r["created_at"] = r["created_at"].isoformat()
            r["client_username"] = r.pop("client__username")

        return Response({
            "profile": {
                "id": profile.id,
                "profession": profile.profession,
                "profession_ar": profile.profession_ar,
                "is_available": profile.is_available,
                "is_verified": profile.is_verified,
                "average_rating": round(profile.average_rating or 0, 2),
            },
            "lifetime": {
                "orders": lifetime["total"] or 0,
                "completed_jobs": lifetime["completed"] or 0,
                "accepted_jobs": lifetime["accepted"] or 0,
                "pending_requests": lifetime["pending"] or 0,
                "rejected": lifetime["rejected"] or 0,
                "cancelled": lifetime["cancelled"] or 0,
            },
            "this_month": {
                "orders": this_month["total"] or 0,
                "completed_jobs": this_month["completed"] or 0,
            },
            "recent_ratings": recent_ratings,
        })


class WorkerCreateView(APIView):
    permission_classes = [IsAuthenticated, IsWorker]

    def post(self, request):
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
    permission_classes = [IsAuthenticated, IsWorker]

    def get(self, request):
        if not hasattr(request.user, "worker_profile"):
            return Response(
                {"error": "You do not have a worker profile yet."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(WorkerProfileSerializer(request.user.worker_profile).data)

    def patch(self, request):
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
