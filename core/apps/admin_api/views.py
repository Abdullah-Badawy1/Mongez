from django.db.models import Count, Sum, Q
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from apps.users.models import User
from apps.users.serializers import UserSerializer, RegisterSerializer
from apps.workers.models import ServiceCategory, WorkerProfile
from apps.workers.serializers import ServiceCategorySerializer, WorkerProfileSerializer
from apps.orders.models import Order
from apps.payments.models import CommissionPayment
from apps.ratings.models import Rating
from apps.ratings.serializers import RatingSerializer


def admin_only(request):
    if request.user.role != User.Role.ADMIN:
        return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)


class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        total_users = User.objects.count()
        total_clients = User.objects.filter(role=User.Role.CLIENT).count()
        total_workers = User.objects.filter(role=User.Role.WORKER).count()
        total_categories = ServiceCategory.objects.count()
        total_orders = Order.objects.count()
        total_payments = CommissionPayment.objects.count()
        captured_payments = CommissionPayment.objects.filter(payment_status=CommissionPayment.CAPTURED)
        total_revenue = captured_payments.aggregate(Sum("amount"))["amount__sum"] or 0

        orders_by_status = (
            Order.objects.values("status")
            .annotate(count=Count("id"))
            .order_by("status")
        )

        recent_orders = Order.objects.select_related("client", "worker", "service_category").order_by("-created_at")[:10]
        from apps.orders.serializers import OrderSerializer
        orders_data = OrderSerializer(recent_orders, many=True, context={"request": request}).data

        return Response({
            "stats": {
                "total_users": total_users,
                "total_clients": total_clients,
                "total_workers": total_workers,
                "total_categories": total_categories,
                "total_orders": total_orders,
                "total_payments": total_payments,
                "total_revenue": total_revenue,
                "orders_by_status": orders_by_status,
            },
            "recent_orders": orders_data,
        })


class AdminUserListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        search = request.query_params.get("search", "")
        role = request.query_params.get("role", "")
        queryset = User.objects.all()
        if search:
            queryset = queryset.filter(Q(username__icontains=search) | Q(phone__icontains=search) | Q(email__icontains=search))
        if role:
            queryset = queryset.filter(role=role)

        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 20))
        start = (page - 1) * page_size
        end = start + page_size
        total = queryset.count()
        users = queryset.order_by("-date_joined")[start:end]

        return Response({
            "count": total,
            "page": page,
            "page_size": page_size,
            "results": UserSerializer(users, many=True, context={"request": request}).data,
        })


class AdminUserCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        serializer = RegisterSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            user = serializer.save()
            return Response(UserSerializer(user, context={"request": request}).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class AdminUserDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(UserSerializer(user, context={"request": request}).data)

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        allowed_fields = ["username", "phone", "email", "address", "role", "is_active", "profile_image"]
        data = {k: v for k, v in request.data.items() if k in allowed_fields}
        for key, value in data.items():
            setattr(user, key, value)
        user.save()
        return Response(UserSerializer(user, context={"request": request}).data)

    def delete(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)
        user.delete()
        return Response({"message": "User deleted."}, status=status.HTTP_204_NO_CONTENT)


class AdminCategoryUpdateDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            category = ServiceCategory.objects.get(pk=pk)
        except ServiceCategory.DoesNotExist:
            return Response({"error": "Category not found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = ServiceCategorySerializer(category, data=request.data, partial=True, context={"request": request})
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            category = ServiceCategory.objects.get(pk=pk)
        except ServiceCategory.DoesNotExist:
            return Response({"error": "Category not found."}, status=status.HTTP_404_NOT_FOUND)
        category.delete()
        return Response({"message": "Category deleted."}, status=status.HTTP_204_NO_CONTENT)


class AdminPaymentListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        payments = CommissionPayment.objects.select_related("order").all().order_by("-created_at")
        data = []
        for p in payments:
            data.append({
                "id": p.id,
                "order_id": p.order_id,
                "amount": str(p.amount),
                "payment_status": p.payment_status,
                "paymob_transaction_id": p.paymob_transaction_id,
                "created_at": p.created_at,
                "updated_at": p.updated_at,
            })
        return Response(data)


class AdminOrderStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            order = Order.objects.select_related("client", "worker", "service_category").get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        new_status = request.data.get("status")
        valid_statuses = [s[0] for s in Order.STATUS_CHOICES]
        if new_status not in valid_statuses:
            return Response({"error": f"Invalid status. Must be one of: {', '.join(valid_statuses)}"}, status=status.HTTP_400_BAD_REQUEST)

        order.status = new_status
        now = timezone.now()
        if new_status == Order.ACCEPTED and not order.accepted_at:
            order.accepted_at = now
        elif new_status == Order.COMPLETED and not order.completed_at:
            order.completed_at = now
            if order.worker:
                profile = WorkerProfile.objects.filter(user=order.worker).first()
                if profile:
                    profile.completed_jobs += 1
                    profile.save(update_fields=["completed_jobs"])
        elif new_status == Order.CANCELLED and not order.cancelled_at:
            order.cancelled_at = now
        order.save()

        from apps.orders.serializers import OrderSerializer
        return Response(OrderSerializer(order, context={"request": request}).data)


class AdminWorkerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        search = request.query_params.get("search", "")
        queryset = User.objects.filter(role=User.Role.WORKER)
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) | Q(phone__icontains=search)
            )

        page = int(request.query_params.get("page", 1))
        page_size = int(request.query_params.get("page_size", 50))
        start = (page - 1) * page_size
        end = start + page_size
        total = queryset.count()
        users = queryset.order_by("-date_joined")[start:end]

        results = []
        for u in users:
            profile = getattr(u, "worker_profile", None)
            results.append({
                "id": profile.id if profile else None,
                "user": UserSerializer(u, context={"request": request}).data,
                "category": ServiceCategorySerializer(profile.category).data if profile and profile.category else None,
                "description": profile.description if profile else "",
                "experience_years": profile.experience_years if profile else 0,
                "average_rating": profile.average_rating if profile else 0.0,
                "completed_jobs": profile.completed_jobs if profile else 0,
                "is_available": profile.is_available if profile else False,
                "score": round(profile.calculate_score(), 2) if profile else 0.0,
                "created_at": profile.created_at.isoformat() if profile and profile.created_at else u.date_joined.isoformat(),
                "has_profile": profile is not None,
            })

        return Response({
            "count": total,
            "page": page,
            "page_size": page_size,
            "results": results,
        })


class AdminWorkerDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            profile = WorkerProfile.objects.select_related("user", "category").get(pk=pk)
        except WorkerProfile.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(WorkerProfileSerializer(profile, context={"request": request}).data)


class AdminRatingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        ratings = Rating.objects.select_related("client", "worker", "order").all().order_by("-created_at")
        return Response(RatingSerializer(ratings, many=True, context={"request": request}).data)
