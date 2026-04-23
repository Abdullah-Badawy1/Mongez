from django.contrib import admin
from .models import CommissionPayment


@admin.register(CommissionPayment)
class CommissionPaymentAdmin(admin.ModelAdmin):
    list_display    = [
        "id", "order", "amount", "payment_status",
        "paymob_order_id", "paymob_transaction_id", "updated_at",
    ]
    list_filter     = ["payment_status"]
    search_fields   = ["order__id", "paymob_order_id", "paymob_transaction_id"]
    readonly_fields = [
        "paymob_order_id", "paymob_transaction_id",
        "payment_key", "created_at", "updated_at",
    ]

    def has_add_permission(self, request):
        # Payments are created Atuomatically code only
        return False
