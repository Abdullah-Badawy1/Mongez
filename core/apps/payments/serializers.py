from rest_framework import serializers
from .models import CommissionPayment


class CommissionPaymentSerializer(serializers.ModelSerializer):
   
    #Used to show payment info inside order responses.
    
    class Meta:
        model = CommissionPayment
        fields = [
            "id",
            "amount",
            "paymob_order_id",
            "paymob_transaction_id",
            "payment_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields
