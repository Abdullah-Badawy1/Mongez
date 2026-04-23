from rest_framework import serializers
from apps.users.models import User
from apps.users.serializers import UserSerializer
from apps.workers.models import ServiceCategory, WorkerProfile
from apps.workers.serializers import ServiceCategorySerializer
from .models import Order


class OrderSerializer(serializers.ModelSerializer):
    
    client = UserSerializer(read_only=True)
    worker = UserSerializer(read_only=True)
    service_category = ServiceCategorySerializer(read_only=True)
    commission_payment = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            "id",
            "client",
            "worker",
            "service_category",
            "commission",
            "status",
            "created_at",
            "accepted_at",
            "completed_at",
            "cancelled_at",
            "commission_payment",
        ]

    def get_commission_payment(self, order):
        try:
            p = order.commission_payment
            return {
                "amount": str(p.amount),
                "payment_status": p.payment_status,
                "paymob_order_id": p.paymob_order_id,
                "paymob_transaction_id": p.paymob_transaction_id,
            }
        except Exception:
            return None


class OrderCreateSerializer(serializers.ModelSerializer):
    
    service_category = serializers.PrimaryKeyRelatedField(
        queryset=ServiceCategory.objects.all(),
    )
    worker_id = serializers.PrimaryKeyRelatedField(
        queryset   = User.objects.filter(role=User.Role.WORKER),
        source = "worker",
        required = False,
        allow_null = True,
    )

    class Meta:
        model  = Order
        fields = ["service_category", "worker_id"]

    def validate(self, attrs):
        """Validate worker against category when worker_id is provided."""
        worker = attrs.get("worker")
        service_category = attrs.get("service_category")

        if worker is None:
            return attrs

        if not hasattr(worker, "worker_profile"):
            raise serializers.ValidationError(
                {"worker_id": "This worker does not have a profile yet."}
            )

        profile = worker.worker_profile

        if not profile.is_available:
            raise serializers.ValidationError(
                {"worker_id": "This worker is not currently available."}
            )

        if profile.profession.lower() != service_category.name.lower():
            raise serializers.ValidationError(
                {
                    "worker_id": (
                        f"Worker's profession '{profile.profession}' does not match "
                        f"the selected category '{service_category.name}'."
                    )
                }
            )

        return attrs
