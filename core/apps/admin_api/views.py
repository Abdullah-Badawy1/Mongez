import csv
from django.core.cache import cache
from django.db.models import Count, Sum, Q
from django.http import HttpResponse
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
from apps.notifications.services import notify
from apps.notifications.models import Notification


def admin_only(request):
    if request.user.role != User.Role.ADMIN:
        return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)


_DASHBOARD_STATS_CACHE_KEY = "admin_api:dashboard_stats:v1"
_DASHBOARD_STATS_TTL = 5  # seconds


class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        # Stats aggregate is identical for every admin so we cache it for a
        # few seconds. The dashboard polls every 10 s; with 5 s TTL the
        # query runs at most ~every other poll regardless of how many
        # admins are viewing. The cache is read-through — first request
        # after expiry takes the hit and warms it back up.
        stats = cache.get(_DASHBOARD_STATS_CACHE_KEY)
        if stats is None:
            captured_payments = CommissionPayment.objects.filter(
                payment_status=CommissionPayment.CAPTURED,
            )
            stats = {
                "total_users": User.objects.count(),
                "total_clients": User.objects.filter(role=User.Role.CLIENT).count(),
                "total_workers": User.objects.filter(role=User.Role.WORKER).count(),
                "total_categories": ServiceCategory.objects.count(),
                "total_orders": Order.objects.count(),
                "total_payments": CommissionPayment.objects.count(),
                "total_revenue": captured_payments.aggregate(Sum("amount"))["amount__sum"] or 0,
                "orders_by_status": list(
                    Order.objects.values("status")
                    .annotate(count=Count("id"))
                    .order_by("status"),
                ),
            }
            cache.set(_DASHBOARD_STATS_CACHE_KEY, stats, _DASHBOARD_STATS_TTL)

        # Recent orders are not cached — they're per-request shape (URLs in
        # serializer depend on `request`) and we always want them fresh.
        recent_orders = Order.objects.select_related(
            "client", "worker", "service_category",
        ).order_by("-created_at")[:10]
        from apps.orders.serializers import OrderSerializer
        orders_data = OrderSerializer(
            recent_orders, many=True, context={"request": request},
        ).data

        return Response({"stats": stats, "recent_orders": orders_data})


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

        previous_status = order.status
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

        # Fan out to the affected client (and worker, if assigned) so the
        # mobile sees the dashboard action immediately via the notification
        # poll + the order-list poll, instead of only via the order poll.
        # We mark it PUSH so FCM fires too when FCM_SERVER_KEY is set.
        if previous_status != new_status:
            payload = {
                "order_id": order.id,
                "status": new_status,
                "changed_by": "admin",
            }
            title = f"Order #{order.id} — {new_status.lower()}"
            message = f"An administrator updated your order to {new_status}."
            if order.client_id:
                notify(
                    order.client, title, message,
                    notif_type=Notification.PUSH, data=payload,
                )
            if order.worker_id and order.worker_id != order.client_id:
                notify(
                    order.worker, title,
                    f"An administrator updated this order to {new_status}.",
                    notif_type=Notification.PUSH, data=payload,
                )

        from apps.orders.serializers import OrderSerializer
        return Response(OrderSerializer(order, context={"request": request}).data)


class AdminWorkerListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        search = request.query_params.get("search", "")
        status_filter = (request.query_params.get("status") or "").lower()

        queryset = User.objects.filter(role=User.Role.WORKER)
        if search:
            queryset = queryset.filter(
                Q(username__icontains=search) | Q(phone__icontains=search)
            )

        # `?status=complete`   → only workers who finished AddService
        # `?status=incomplete` → registered worker accounts without a profile
        # (anything else)      → both
        if status_filter == "complete":
            queryset = queryset.filter(worker_profile__isnull=False)
        elif status_filter == "incomplete":
            queryset = queryset.filter(worker_profile__isnull=True)

        # Counts for the dashboard banner — cheap on this scale.
        complete_count = User.objects.filter(
            role=User.Role.WORKER, worker_profile__isnull=False,
        ).count()
        incomplete_count = User.objects.filter(
            role=User.Role.WORKER, worker_profile__isnull=True,
        ).count()

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
                # WorkerProfile.profession is a free-text trade label
                # ("Plumber", "Electrician", …) — the dashboard treats
                # it the same way an old `category.name` was used.
                "profession": profile.profession if profile else "",
                "profession_ar": profile.profession_ar if profile else "",
                "description": profile.bio if profile else "",
                "description_ar": profile.bio_ar if profile else "",
                "experience_years": profile.experience_years if profile else 0,
                "average_rating": profile.average_rating if profile else 0.0,
                "completed_jobs": profile.completed_jobs if profile else 0,
                "accept_rate": profile.accept_rate if profile else 0.0,
                "is_available": profile.is_available if profile else False,
                "is_verified": profile.is_verified if profile else False,
                "score": round(profile.calculate_score(), 2) if profile else 0.0,
                "created_at": profile.created_at.isoformat() if profile and profile.created_at else u.date_joined.isoformat(),
                "has_profile": profile is not None,
            })

        return Response({
            "count": total,
            "page": page,
            "page_size": page_size,
            "complete_count": complete_count,
            "incomplete_count": incomplete_count,
            "results": results,
        })


class AdminWorkerDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)
        try:
            profile = WorkerProfile.objects.select_related("user").get(pk=pk)
        except WorkerProfile.DoesNotExist:
            return Response({"error": "Worker not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(WorkerProfileSerializer(profile, context={"request": request}).data)


class AdminRatingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.ADMIN:
            return Response({"error": "Admin access required."}, status=status.HTTP_403_FORBIDDEN)

        from apps.ratings.serializers import AdminRatingSerializer
        ratings = (
            Rating.objects
            .select_related(
                "client", "worker", "worker__worker_profile",
                "order", "order__service_category",
            )
            .all()
            .order_by("-created_at")
        )
        return Response(
            AdminRatingSerializer(ratings, many=True, context={"request": request}).data,
        )


# ── CSV exports ────────────────────────────────────────────────────────
# Used by the admin dashboard's "Export CSV" buttons. Each view streams
# a UTF-8 CSV with a BOM so Excel opens Arabic text correctly. Volumes
# are small (a few thousand rows at this stage), so we materialize the
# CSV in one HttpResponse instead of streaming.

def _csv_response(filename):
    response = HttpResponse(content_type="text/csv; charset=utf-8")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    # BOM so Excel detects UTF-8 (otherwise Arabic shows as mojibake).
    response.write("﻿")
    return response


def _require_admin(request):
    if request.user.role != User.Role.ADMIN:
        return Response(
            {"error": "Admin access required."},
            status=status.HTTP_403_FORBIDDEN,
        )
    return None


class AdminOrdersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("orders.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "status", "urgency", "category", "category_ar",
            "client_username", "client_name", "client_phone",
            "worker_username", "worker_name", "worker_phone",
            "address", "latitude", "longitude",
            "commission", "created_at", "accepted_at",
            "completed_at", "cancelled_at",
        ])
        qs = (
            Order.objects
            .select_related("client", "worker", "service_category")
            .order_by("-created_at")
        )
        for o in qs.iterator(chunk_size=500):
            cat = o.service_category
            writer.writerow([
                o.id, o.status, o.urgency,
                cat.name if cat else "",
                cat.name_ar if cat else "",
                o.client.username if o.client_id else "",
                (o.client.name_ar or o.client.get_full_name() or "") if o.client_id else "",
                o.client.phone if o.client_id else "",
                o.worker.username if o.worker_id else "",
                (o.worker.name_ar or o.worker.get_full_name() or "") if o.worker_id else "",
                o.worker.phone if o.worker_id else "",
                o.address_text or "",
                o.latitude if o.latitude is not None else "",
                o.longitude if o.longitude is not None else "",
                o.commission,
                o.created_at.isoformat() if o.created_at else "",
                o.accepted_at.isoformat() if o.accepted_at else "",
                o.completed_at.isoformat() if o.completed_at else "",
                o.cancelled_at.isoformat() if o.cancelled_at else "",
            ])
        return response


class AdminWorkersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("workers.csv")
        writer = csv.writer(response)
        writer.writerow([
            "user_id", "username", "name", "phone", "email",
            "governorate", "city", "is_active",
            "profession", "profession_ar", "experience_years",
            "average_rating", "completed_jobs", "accept_rate",
            "is_available", "is_verified", "is_featured",
            "hourly_rate", "minimum_charge", "currency",
            "date_joined", "profile_created_at",
        ])
        qs = (
            User.objects.filter(role=User.Role.WORKER)
            .select_related("worker_profile")
            .order_by("-date_joined")
        )
        for u in qs.iterator(chunk_size=500):
            p = getattr(u, "worker_profile", None)
            writer.writerow([
                u.id, u.username,
                u.name_ar or u.get_full_name() or "",
                u.phone, u.email, u.governorate, u.city, u.is_active,
                p.profession if p else "",
                p.profession_ar if p else "",
                p.experience_years if p else "",
                p.average_rating if p else "",
                p.completed_jobs if p else "",
                p.accept_rate if p else "",
                p.is_available if p else "",
                p.is_verified if p else "",
                p.is_featured if p else "",
                p.hourly_rate if p and p.hourly_rate is not None else "",
                p.minimum_charge if p and p.minimum_charge is not None else "",
                p.currency if p else "",
                u.date_joined.isoformat() if u.date_joined else "",
                p.created_at.isoformat() if p and p.created_at else "",
            ])
        return response


class AdminUsersCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("users.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "username", "name", "email", "phone",
            "role", "governorate", "city", "address",
            "is_active", "is_staff", "date_joined", "last_login",
        ])
        qs = User.objects.order_by("-date_joined")
        for u in qs.iterator(chunk_size=500):
            writer.writerow([
                u.id, u.username,
                u.name_ar or u.get_full_name() or "",
                u.email, u.phone, u.role,
                u.governorate, u.city, u.address,
                u.is_active, u.is_staff,
                u.date_joined.isoformat() if u.date_joined else "",
                u.last_login.isoformat() if u.last_login else "",
            ])
        return response


class AdminCategoriesCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("categories.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "name", "name_ar", "icon", "image",
            "description", "description_ar",
            "worker_count", "active_worker_count",
        ])
        # Category list is tiny (tens of rows). One small count query per
        # row is fine and keeps the code readable — annotating across the
        # free-text profession field would need a Subquery wrapper that
        # earns nothing at this scale.
        for c in ServiceCategory.objects.order_by("name").iterator(chunk_size=500):
            worker_count = WorkerProfile.objects.filter(
                profession__iexact=c.name,
            ).count()
            active_worker_count = WorkerProfile.objects.filter(
                profession__iexact=c.name,
                is_available=True,
            ).count()
            image_url = ""
            if c.image:
                try:
                    image_url = request.build_absolute_uri(c.image.url)
                except Exception:
                    image_url = c.image.name
            writer.writerow([
                c.id, c.name, c.name_ar, c.icon, image_url,
                c.description, c.description_ar,
                worker_count, active_worker_count,
            ])
        return response


class AdminPaymentsCSVView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        denied = _require_admin(request)
        if denied is not None:
            return denied
        response = _csv_response("payments.csv")
        writer = csv.writer(response)
        writer.writerow([
            "id", "order_id", "amount", "payment_status",
            "paymob_order_id", "paymob_transaction_id",
            "created_at", "updated_at",
        ])
        qs = (
            CommissionPayment.objects.select_related("order")
            .order_by("-created_at")
        )
        for p in qs.iterator(chunk_size=500):
            writer.writerow([
                p.id, p.order_id,
                p.amount,
                p.payment_status,
                p.paymob_order_id or "",
                p.paymob_transaction_id or "",
                p.created_at.isoformat() if p.created_at else "",
                p.updated_at.isoformat() if p.updated_at else "",
            ])
        return response
