import logging
from datetime import datetime, timezone

from django.conf import settings
from django.db import transaction
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.payments.models import CommissionPayment
from apps.payments import paymob
from apps.users.models import User
from apps.workers.models import WorkerProfile
from .models import Order
from .serializers import OrderCreateSerializer, OrderSerializer

logger = logging.getLogger(__name__)

#Helper funcs

def now():
    return datetime.now(tz=timezone.utc)


def send_notification(user, title, message, notif_type=Notification.IN_APP):
    Notification.objects.create(
        user=user, title=title, message=message, type=notif_type,
    )


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

#orders views
class OrderListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role == User.Role.CLIENT:
            orders = Order.objects.filter(client=user)
        elif user.role == User.Role.WORKER:
            orders = Order.objects.filter(worker=user)
        else:
            orders = Order.objects.all()
        return Response(OrderSerializer(orders, many=True).data)

    @transaction.atomic
    def post(self, request):
        if request.user.role != User.Role.CLIENT:
            return Response(
                {"error": "Only clients can create orders."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = OrderCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        order = Order.objects.create(
            client=request.user,
            service_category=serializer.validated_data["service_category"],
            worker=serializer.validated_data.get("worker"),
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

        response_data = OrderSerializer(order).data
        response_data["payment_key"] = payment_key
        return Response(response_data, status=status.HTTP_201_CREATED)

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
        return Response(OrderSerializer(order).data)


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
        return Response(OrderSerializer(order).data)


class OrderCancelView(APIView):
    """POST /api/orders/{id}/cancel/ — client cancels the order"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        if request.user.role != User.Role.CLIENT:
            return Response(
                {"error": "Only clients can cancel orders."},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            # Filter by client so a client can never cancel someone else's order
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
        return Response(OrderSerializer(order).data)


class OrderCompleteView(APIView):
    """POST /api/orders/{id}/complete/ — worker marks the order as done"""
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk):
        if request.user.role != User.Role.WORKER:
            return Response(
                {"error": "Only workers can complete orders."},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            # Filter by worker so a worker can only complete their own assigned orders
            order = Order.objects.get(pk=pk, worker=request.user)
        except Order.DoesNotExist:
            return Response({"error": "Order not found."}, status=status.HTTP_404_NOT_FOUND)

        if order.status != Order.ACCEPTED:
            return Response(
                {"error": f"Cannot complete an order with status '{order.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Update order
        order.status   = Order.COMPLETED
        order.completed_at = now()
        order.save()

        # Update worker's completed jobs count
        profile = request.user.worker_profile
        profile.completed_jobs += 1
        profile.save()

        # Notify client to leave a rating
        send_notification(
            order.client,
            title      = "Job Completed ⭐",
            message    = f"Order #{order.id} is done! Please leave a rating for the worker.",
            notif_type = Notification.PUSH,
        )
        return Response(OrderSerializer(order).data)
