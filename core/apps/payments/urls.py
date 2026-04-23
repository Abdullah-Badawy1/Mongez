from django.urls import path
from . import views

urlpatterns = [
    # Paymob calls this URL automatically after every payment event
    path("payments/webhook/", views.PaymobWebhookView.as_view(), name="paymob-webhook"),
]
