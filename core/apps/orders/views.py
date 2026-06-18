import logging

from django.db.models import Q
from datetime import datetime, timezone

from django.conf import settings
from django.db import transaction
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.notifications.services import notify
from apps.payments.models import CommissionPayment
from apps.payments import paymob
from apps.users.models import User
from apps.workers.models import WorkerProfile
from core.permissions import IsClient, IsWorker
from core.throttling import OrderCreateThrottle
from .models import Order, OrderAttachment
from .serializers import (
    OrderAttachmentSerializer,
    OrderCreateSerializer,
    OrderSerializer,
)

logger = logging.getLogger(__name__)

#Helper funcs

def now():
    return datetime.now(tz=timezone.utc)


def send_notification(user, title, message, notif_type=Notification.IN_APP, data=None):
    """Thin wrapper kept for backwards-compat. Delegates to notifications.services.notify
    which also fans out to FCM device tokens when registered."""
    return notify(user=user, title=title, message=message, notif_type=notif_type, data=data)


def authorize_commission(order):
    amount = settings.COMMISSION_AMOUNT

    try:
        paymob_order_id, payment_key = paymob.authorize_commission(order)
        CommissionPayment.objects.create(
            order=order,
            amount=amount,
            paymob_order_id=paymob_order_id,
            payment_key=payment_key,
            payment_status=CommissionPayment.AUTHORIZED,
        )
        logger.info(f"Commission AUTHORIZED — Order #{order.id}")
        return payment_key

    except Exception as e:
        logger.error(f"Paymob authorization FAILED for Order #{order.id}: {e}")
        CommissionPayment.objects.create(
            order=order,
            amount=amount,
            payment_status=CommissionPayment.FAILED,
        )
        return None

_AUDIO_EXTS = {"mp3", "m4a", "aac", "wav", "ogg", "opus", "amr"}
_VIDEO_EXTS = {"mp4", "mov", "3gp", "webm", "mkv"}
_IMAGE_EXTS = {"jpg", "jpeg", "png", "webp", "gif", "heic"}
_MAX_ATTACHMENT_BYTES = 15 * 1024 * 1024  # 15 MB


def _attachment_kind(name: str) -> str:
    ext = name.rsplit(".", 1)[-1].lower() if "." in name else ""
    if ext in _AUDIO_EXTS:
        return OrderAttachment.KIND_AUDIO
    if ext in _VIDEO_EXTS:
        return OrderAttachment.KIND_VIDEO
    return OrderAttachment.KIND_IMAGE


#orders views
class OrderListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_throttles(self):
        if self.request.method == "POST":
            return [OrderCreateThrottle()]
        return super().get_throttles()

    def get(self, request):
        user = request.user
        base = Order.objects.select_related(
            "client", "worker", "service_category", "commission_payment",
        )
        if user.role == User.Role.CLIENT:
            orders = base.filter(client=user)
        elif user.role == User.Role.WORKER:
            # Workers see: jobs assigned to them AND any orders they
            # placed themselves (a plumber needs an electrician at home).
            # `__exact=user.id` keeps both filters indexable.
            orders = base.filter(
                Q(worker=user) | Q(client=user),
            ).distinct()
        else:
            orders = base.all()

        status_filter = request.query_params.get("status")
        if status_filter:
            orders = orders.filter(status=status_filter.upper())

        return Response(OrderSerializer(orders, many=True, context={"request": request}).data)

    @transaction.atomic
    def post(self, request):
        # Clients can always order. Workers can also place orders (e.g.
        # a plumber needs an electrician at home) — but they're not
        # allowed to order their OWN profession; that'd be self-dealing
        # since they'd just dispatch themselves and collect commission
        # on a no-op. Admins are never order-placers.
        if request.user.role == User.Role.ADMIN:
            return Response(
                {"error": "Admins can't place orders. Use a client account."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = OrderCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        vd = serializer.validated_data

        # Block same-profession orders for workers.
        if request.user.role == User.Role.WORKER:
            profile = getattr(request.user, "worker_profile", None)
            if profile is not None:
                requested_cat = vd["service_category"].name
                if (profile.profession or "").lower() == requested_cat.lower():
                    return Response(
                        {"service_category": [
                            f"You can't order a {requested_cat} service — "
                            "that's your own profession. Pick a different "
                            "category (e.g. an electrician can hire a "
                            "plumber, but not another electrician)."
                        ]},
                        status=status.HTTP_400_BAD_REQUEST,
                    )

        order = Order.objects.create(
            client=request.user,
            service_category=vd["service_category"],
            worker=vd.get("worker"),
            description=vd.get("description", ""),
            address_text=vd.get("address_text", ""),
            latitude=vd.get("latitude"),
            longitude=vd.get("longitude"),
            urgency=vd.get("urgency", Order.URGENCY_NORMAL),
            scheduled_for=vd.get("scheduled_for"),
        )

        # Optional multipart attachments — sent under keys: attachments,
        # photos, photo, audio. We validate sizes BEFORE the order is
        # saved so the client gets a clear 400; previously oversize
        # files were silently dropped after the order had already been
        # created, leaving an empty order with no explanation.
        files = []
        files += request.FILES.getlist("attachments")
        files += request.FILES.getlist("photos")
        files += request.FILES.getlist("photo")
        files += request.FILES.getlist("audio")
        for f in files:
            if f.size > _MAX_ATTACHMENT_BYTES:
                return Response(
                    {"attachments": [
                        f"'{f.name}' is {f.size // (1024*1024)} MB; max is "
                        f"{_MAX_ATTACHMENT_BYTES // (1024*1024)} MB per file.",
                    ]},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        for f in files:
            OrderAttachment.objects.create(
                order=order,
                kind=_attachment_kind(f.name),
                file=f,
                duration_seconds=request.data.get("duration_seconds") if _attachment_kind(f.name) == OrderAttachment.KIND_AUDIO else None,
            )

        payment_key = authorize_commission(order)

        available_workers = WorkerProfile.objects.select_related("user").filter(
            user__role=User.Role.WORKER,
            is_available=True,
            profession__iexact=order.service_category.name,
        )

        for wp in available_workers:
            if order.worker and order.worker == wp.user:
                title = "You Were Selected For an Order 🎯"
                message = (
                    f"A client chose you for a {order.service_category.name} "
                    f"order #{order.id}. Please accept or reject."
                )
            else:
                title = "New Order Available"
                message = f"New {order.service_category.name} order #{order.id} is available."

            send_notification(wp.user, title=title, message=message, notif_type=Notification.PUSH)

        response_data = OrderSerializer(order, context={"request": request}).data
        response_data["payment_key"] = payment_key
        return Response(response_data, status=status.HTTP_201_CREATED)


class OrderAttachmentUploadView(APIView):
    """POST /api/orders/<id>/attachments/ — add an attachment after order creation."""

    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, pk):
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.client != request.user:
            return Response(
                {"error": "Only the order client can add attachments."},
                status=status.HTTP_403_FORBIDDEN,
            )

        if order.status not in (Order.PENDING, Order.ACCEPTED):
            return Response(
                {"error": f"Cannot add attachments to a {order.status.lower()} order."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        files = list(request.FILES.values())
        if not files:
            return Response(
                {"error": "No file uploaded. Use multipart/form-data with a file field."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        created = []
        for f in files:
            if f.size > _MAX_ATTACHMENT_BYTES:
                return Response(
                    {"error": f"Attachment '{f.name}' exceeds 15MB."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            att = OrderAttachment.objects.create(
                order=order,
                kind=_attachment_kind(f.name),
                file=f,
                caption=request.data.get("caption", ""),
            )
            created.append(att)

        return Response(
            OrderAttachmentSerializer(created, many=True, context={"request": request}).data,
            status=status.HTTP_201_CREATED,
        )


class OrderDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            order = Order.objects.select_related(
                "client",
                "worker",
                "service_category",
            ).get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if request.user.role == User.Role.CLIENT and order.client != request.user:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if request.user.role == User.Role.WORKER and order.worker != request.user:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        return Response(OrderSerializer(order, context={"request": request}).data)


class OrderAcceptView(APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can accept orders."},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.PENDING:
            return Response(
                {"error": f"Cannot accept an order with status '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update order
        order.status = Order.ACCEPTED
        order.worker = request.user
        order.accepted_at = now()
        order.commission  = settings.COMMISSION_AMOUNT
        order.save()
        try:
            payment = order.commission_payment
            if (
                payment.payment_status == CommissionPayment.AUTHORIZED
                and payment.paymob_transaction_id
            ):
                paymob.capture_commission(payment.paymob_transaction_id, payment.amount)
                payment.payment_status = CommissionPayment.CAPTURED
                payment.save()
                logger.info(f"Commission CAPTURED — Order #{order.id}")
            else:
                logger.warning(
                    f"Order #{order.id} accepted but paymob_transaction_id is empty. "
                    "Capture skipped — handle manually."
                )
        except CommissionPayment.DoesNotExist:
            logger.warning(f"Order #{order.id} accepted but no CommissionPayment record found.")
        except Exception as e:
            # Never block order acceptance because of a Paymob failure
            logger.error(f"Paymob CAPTURE failed for Order #{order.id}: {e}")

        # Notify client
        send_notification(
            order.client,
            title = "Order Accepted ✅",
            message  = f"{request.user.username} accepted your order #{order.id}.",
            notif_type = Notification.PUSH,
        )
        return Response(OrderSerializer(order, context={"request": request}).data)


class OrderRejectView(APIView):
    """POST /api/orders/{id}/reject/ — worker rejects the order"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can reject orders."},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            order = Order.objects.get(pk=pk)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.PENDING:
            return Response(
                {"error": f"Cannot reject an order with status '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update order
        order.status       = Order.REJECTED
        order.cancelled_at = now()
        order.save()

        # Void commission via Paymob — release the card hold
        try:
            payment = order.commission_payment
            if (
                payment.payment_status == CommissionPayment.AUTHORIZED
                and payment.paymob_transaction_id
            ):
                paymob.void_commission(payment.paymob_transaction_id)
                payment.payment_status = CommissionPayment.VOIDED
                payment.save()
                logger.info(f"Commission VOIDED (rejected) — Order #{order.id}")
        except CommissionPayment.DoesNotExist:
            logger.warning(f"Order #{order.id} rejected but no CommissionPayment record found.")
        except Exception as e:
            logger.error(f"Paymob VOID failed for Order #{order.id}: {e}")

        # Notify client
        send_notification(
            order.client,
            title   = "Order Rejected ❌",
            message = f"Your order #{order.id} was rejected. We will try to find another worker.",
        )
        return Response(OrderSerializer(order, context={"request": request}).data)


class OrderCancelView(APIView):
    """POST /api/orders/{id}/cancel/ — the orderer cancels the order.

    "Orderer" is the user stored as `Order.client`. That's a real
    customer most of the time, but it can also be a worker who placed
    the order through the "Need a service?" flow on the worker home.
    """

    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        try:
            order = Order.objects.get(pk=pk, client=request.user)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.PENDING:
            return Response(
                {"error": f"Cannot cancel an order with status '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update order
        order.status = Order.CANCELLED
        order.cancelled_at = now()
        order.save()

        # Void commission via Paymob — only if it was AUTHORIZED
        try:
            payment = order.commission_payment
            if (
                payment.payment_status == CommissionPayment.AUTHORIZED
                and payment.paymob_transaction_id
            ):
                paymob.void_commission(payment.paymob_transaction_id)
                payment.payment_status = CommissionPayment.VOIDED
                payment.save()
                logger.info(f"Commission VOIDED (cancelled) — Order #{order.id}")
        except CommissionPayment.DoesNotExist:
            logger.warning(f"Order #{order.id} cancelled but no CommissionPayment record found.")
        except Exception as e:
            logger.error(f"Paymob VOID failed for Order #{order.id}: {e}")

        # Notify worker if one was assigned
        if order.worker:
            send_notification(
                order.worker,
                title   = "Order Cancelled",
                message = f"Order #{order.id} was cancelled by the client.",
            )
        return Response(OrderSerializer(order, context={"request": request}).data)


class OrderCompleteView(APIView):
    """POST /api/orders/{id}/complete/ — worker marks the job as
    physically done.

    This is the **first half** of the two-step completion handshake:
    the worker presses "Mark as finished", we move the order from
    ACCEPTED → WAITING_CONFIRMATION and ping the client. The order
    isn't actually COMPLETED yet — the client has to confirm, which
    bumps the worker's `completed_jobs` counter and triggers the
    "leave a rating" notification.
    """

    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can mark orders as finished."},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            order = Order.objects.get(pk=pk, worker=request.user)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.ACCEPTED:
            return Response(
                {"error": f"Cannot mark this order as finished from status '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        order.status = Order.WAITING_CONFIRMATION
        order.marked_finished_at = now()
        order.save(update_fields=["status", "marked_finished_at"])

        # Ping the client to confirm.
        send_notification(
            order.client,
            title=f"Order #{order.id} — please confirm it's done",
            message=(
                f"Your worker says the {order.service_category.name} job "
                "is finished. Open the order and tap Confirm to close it "
                "and leave a rating."
            ),
            notif_type=Notification.PUSH,
        )
        return Response(OrderSerializer(order, context={"request": request}).data)


class OrderConfirmCompletionView(APIView):
    """POST /api/orders/{id}/confirm-completion/ — client confirms
    the worker's "marked finished" claim.

    This is the **second half** of the two-step completion handshake.
    Only the order's `client` field owner can call it (which is also
    how a worker who placed an order can confirm — they're the
    client of that order). On success we bump the worker's
    `completed_jobs` counter and ask the client for a rating.
    """

    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        try:
            # Only the orderer can confirm — that's whoever is stored
            # as the order's `client`, regardless of role.
            order = Order.objects.select_related("worker", "service_category").get(
                pk=pk, client=request.user,
            )
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.WAITING_CONFIRMATION:
            return Response(
                {"error": (
                    f"Cannot confirm completion from status '{order.status}'. "
                    "The worker must mark the job as finished first."
                )},
                status=status.HTTP_400_BAD_REQUEST,
            )

        order.status = Order.COMPLETED
        order.completed_at = now()
        order.save(update_fields=["status", "completed_at"])

        # Now we can finally bump the worker's stats — done only on
        # the *client-confirmed* completion, not on the worker's
        # self-claim.
        if order.worker is not None:
            profile = getattr(order.worker, "worker_profile", None)
            if profile is not None:
                profile.completed_jobs = (profile.completed_jobs or 0) + 1
                profile.save(update_fields=["completed_jobs"])

            # Ask the worker to celebrate, prompt the client to rate.
            send_notification(
                order.worker,
                title=f"Order #{order.id} closed ✅",
                message=f"The client confirmed the {order.service_category.name} job is done.",
                notif_type=Notification.PUSH,
            )
        send_notification(
            request.user,
            title="Job confirmed — leave a rating?",
            message=f"Order #{order.id} is closed. Tap to leave a star rating for the worker.",
            notif_type=Notification.PUSH,
        )
        return Response(OrderSerializer(order, context={"request": request}).data)
