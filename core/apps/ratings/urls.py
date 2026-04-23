from django.urls import path
from . import views

urlpatterns = [
    path("ratings/", views.RatingCreateView.as_view(), name="rating-create"),
]
