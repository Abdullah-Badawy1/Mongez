"""
Paymob Webhook View
===================
Paymob sends a POST request to this URL after every payment event.
We use it to:
    1. Verify the request is genuinely from Paymob using HMAC
    2. Save the paymob_transaction_id (needed for capture and void later)
    3. Update the payment_status in our database
"""

import hashlib
import hmac
import logging

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.conf import settings

from .models import CommissionPayment

logger = logging.getLogger(__name__)


def verify_hmac(data: dict, received_hmac: str) -> bool:
    """
    Verify that the webhook came from Paymob and not from someone else.
    Paymob signs the request with HMAC-SHA512 using our PAYMOB_HMAC_SECRET.
    We recompute the HMAC and compare it to what Paymob sent.
    """
    # Paymob uses these specific fields in this exact order to build the HMAC string
    fields = [
        "amount_cents", "created_at", "currency", "error_occured",
        "has_parent_transaction", "id", "integration_id", "is_3d_secure",
        "is_auth", "is_capture", "is_refunded", "is_standalone_payment",
        "is_voided", "order", "owner", "pending", "source_data.pan",
        "source_data.sub_type", "source_data.type", "success",
    ]

    # Build the string by concatenating all values in order
    message = ""
    for field in fields:
        if "." in field:
            # Handle nested fields like "source_data.pan"
            parts = field.split(".")
            value = data
            for part in parts:
                value = value.get(part, "") if isinstance(value, dict) else ""
        else:
            value = data.get(field, "")
        message += str(value)

    # Compute HMAC using SHA512
    computed = hmac.new(
        settings.PAYMOB_HMAC_SECRET.encode(),
        message.encode(),
        hashlib.sha512,
    ).hexdigest()

    return computed == received_hmac


class PaymobWebhookView(APIView):
    """
    POST /api/payments/webhook/

    Paymob calls this endpoint automatically after every transaction.
    We don't call this ourselves — Paymob does.

    You must register this URL in your Paymob dashboard under:
    Settings → Notifications → Transaction processed callback
    """
    permission_classes = [AllowAny]  # Paymob sends no authentication header

    def post(self, request):
        # Paymob sends the HMAC as a URL query parameter
        received_hmac = request.query_params.get("hmac", "")

        # The actual transaction data is inside "obj" in the request body
        obj = request.data.get("obj", {})
        if not obj:
            return Response({"error": "No data received."}, status=status.HTTP_400_BAD_REQUEST)

        # Step 1: verify HMAC — reject if it doesn't match
        if not verify_hmac(obj, received_hmac):
            logger.warning("Paymob webhook received with invalid HMAC — possible fraud attempt.")
            return Response({"error": "Invalid HMAC."}, status=status.HTTP_403_FORBIDDEN)

        # Step 2: extract the important values
        paymob_transaction_id = str(obj.get("id", ""))
        paymob_order_id = str(obj.get("order", {}).get("id", ""))
        is_success = obj.get("success", False)
        is_voided = obj.get("is_voided", False)
        is_capture = obj.get("is_capture", False)

        # Step 3: find our CommissionPayment using the Paymob order ID
        try:
            payment = CommissionPayment.objects.get(paymob_order_id=paymob_order_id)
        except CommissionPayment.DoesNotExist:
            logger.warning(f"Webhook: No CommissionPayment found for paymob_order_id={paymob_order_id}")
            return Response({"error": "Payment not found."}, status=status.HTTP_404_NOT_FOUND)

        # Step 4: save the transaction ID — we need it later for capture and void
        payment.paymob_transaction_id = paymob_transaction_id

        # Step 5: update status based on what Paymob reports
        if is_voided:
            payment.payment_status = CommissionPayment.VOIDED
        elif is_capture and is_success:
            payment.payment_status = CommissionPayment.CAPTURED
        elif is_success:
            payment.payment_status = CommissionPayment.AUTHORIZED
        else:
            payment.payment_status = CommissionPayment.FAILED

        payment.save()
        logger.info(
            f"Webhook processed: Order #{payment.order_id} "
            f"→ transaction={paymob_transaction_id} status={payment.payment_status}"
        )

        # Paymob expects a 200 OK response — otherwise it will retry
        return Response({"message": "Webhook received."})
