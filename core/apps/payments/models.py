from django.db import models
from apps.orders.models import Order


class CommissionPayment(models.Model):
    """
    Tracks the Paymob commission payment for every order.

    Important:
        - Client and worker pay each other in CASH
        - Paymob is used ONLY to charge the platform commission (flat fee)

    Status flow:
        Order created  → AUTHORIZED  (card hold placed via Paymob)
        Worker accepts → CAPTURED    (commission actually charged)
        Worker rejects → VOIDED      (card hold released)
        Client cancels → VOIDED      (card hold released)
        Paymob error   → FAILED
    """

    # Status constants
    AUTHORIZED = "AUTHORIZED"
    CAPTURED   = "CAPTURED"
    VOIDED  = "VOIDED"
    FAILED  = "FAILED"

    STATUS_CHOICES = [
        (AUTHORIZED, "Authorized"),
        (CAPTURED,   "Captured"),
        (VOIDED,     "Voided"),
        (FAILED,     "Failed"),
    ]

    order = models.OneToOneField(
        Order,
        on_delete    = models.CASCADE,
        related_name = "commission_payment",  # access as: order.commission_payment
    )

    # The flat commission amount (e.g. 20 EGP)
    amount = models.DecimalField(max_digits=10, decimal_places=2)

    # IDs returned by Paymob — empty until Paymob responds
    paymob_order_id       = models.CharField(max_length=100, blank=True)
    paymob_transaction_id = models.CharField(max_length=100, blank=True)

    # The key the frontend uses to render the Paymob payment iframe
    # We never expose this in API list responses — it's sensitive
    payment_key = models.TextField(blank=True)

    payment_status = models.CharField(
        max_length=15,
        choices=STATUS_CHOICES,
        default=AUTHORIZED,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)  # auto-updates on every save()

    def __str__(self):
        return f"Commission #{self.id} | Order #{self.order_id} | {self.payment_status}"
