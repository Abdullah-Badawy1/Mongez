"""
Paymob API Client
=================
This is the ONLY file that communicates with Paymob.
All other files call functions from here — never call Paymob directly elsewhere.

How Paymob payment creation works (3 steps):
    Step 1 → POST /auth/tokens          → get auth_token
    Step 2 → POST /ecommerce/orders     → get paymob_order_id
    Step 3 → POST /acceptance/payment_keys → get payment_key (for the frontend iframe)

Then later:
    Capture → charge the card  (when worker accepts)
    Void    → release the hold (when rejected or cancelled)
"""

import logging
import requests
from django.conf import settings

logger = logging.getLogger(__name__)
BASE_URL = "https://accept.paymob.com/api"


def get_auth_token():
    """
    Step 1: Authenticate with Paymob.
    Returns a short-lived token used in all other Paymob API calls.
    """
    response = requests.post(
        f"{BASE_URL}/auth/tokens",
        json={"api_key": settings.PAYMOB_API_KEY},
        timeout=15,
    )
    response.raise_for_status()
    return response.json()["token"]


def create_paymob_order(auth_token, amount_cents, our_order_id):
    """
    Step 2: Create an order record in Paymob.
    amount_cents  — amount in cents (20 EGP = 2000 cents)
    our_order_id  — our internal order id, saved in Paymob for reference
    Returns paymob_order_id as a string.
    """
    response = requests.post(
        f"{BASE_URL}/ecommerce/orders",
        json={
            "auth_token":        auth_token,
            "delivery_needed":   False,
            "amount_cents":      amount_cents,
            "currency":          "EGP",
            "merchant_order_id": str(our_order_id),
            "items":             [],  # no items — just a flat commission
        },
        timeout=15,
    )
    response.raise_for_status()
    return str(response.json()["id"])


def get_payment_key(auth_token, paymob_order_id, amount_cents, client):
    """
    Step 3: Get a payment_key that the frontend uses to show the Paymob iframe.
    Returns the payment_key string.
    """
    billing_data = {
        "apartment":       "NA",
        "email":           client.email or "NA",
        "floor":           "NA",
        "first_name":      client.username,
        "street":          client.address or "NA",
        "building":        "NA",
        "phone_number":    client.phone,
        "shipping_method": "NA",
        "postal_code":     "NA",
        "city":            "NA",
        "country":         "EG",
        "last_name":       "NA",
        "state":           "NA",
    }
    response = requests.post(
        f"{BASE_URL}/acceptance/payment_keys",
        json={
            "auth_token":     auth_token,
            "amount_cents":   amount_cents,
            "expiration":     3600,  # key is valid for 1 hour
            "order_id":       paymob_order_id,
            "billing_data":   billing_data,
            "currency":       "EGP",
            "integration_id": settings.PAYMOB_INTEGRATION_ID,
        },
        timeout=15,
    )
    response.raise_for_status()
    return response.json()["token"]


def authorize_commission(order):
    """
    Runs all 3 steps to authorize a commission payment.
    Called when a new order is created.

    Returns:
        (paymob_order_id, payment_key) — both strings

    Raises Exception if any Paymob API call fails.
    The caller must handle the exception.
    """
    amount_cents = int(settings.COMMISSION_AMOUNT * 100)  # convert EGP to cents

    auth_token = get_auth_token()
    paymob_order_id = create_paymob_order(auth_token, amount_cents, order.id)
    payment_key = get_payment_key(auth_token, paymob_order_id, amount_cents, order.client)

    return paymob_order_id, payment_key


def capture_commission(transaction_id, amount_egp):
    """
    Capture (actually charge) an authorized transaction.
    Called when a worker ACCEPTS an order.

    transaction_id — paymob_transaction_id saved from the webhook
    amount_egp     — commission amount in EGP
    """
    auth_token = get_auth_token()
    amount_cents = int(float(amount_egp) * 100)

    response = requests.post(
        f"{BASE_URL}/acceptance/capture",
        json={
            "auth_token":     auth_token,
            "transaction_id": int(transaction_id),
            "amount_cents":   amount_cents,
        },
        timeout=15,
    )
    response.raise_for_status()
    return response.json()


def void_commission(transaction_id):
    """
    Void (cancel/release) an authorized transaction.
    Called when a worker REJECTS or client CANCELS an order.

    transaction_id — paymob_transaction_id saved from the webhook
    """
    auth_token = get_auth_token()

    response = requests.post(
        f"{BASE_URL}/acceptance/void_refund/void",
        json={
            "auth_token":     auth_token,
            "transaction_id": int(transaction_id),
        },
        timeout=15,
    )
    response.raise_for_status()
    return response.json()
