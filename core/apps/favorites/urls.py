from django.urls import path
from . import views
urlpatterns = [
    path("favorites/",          views.FavoriteListCreateView.as_view(), name="favorite-list-create"),
    path("favorites/<int:pk>/", views.FavoriteDeleteView.as_view(),     name="favorite-delete"),
]
