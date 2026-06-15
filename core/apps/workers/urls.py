from django.urls import path
from . import views

urlpatterns = [
    path("categories/",              views.CategoryListView.as_view(),    name="category-list"),
    path("categories/create/",       views.CategoryCreateView.as_view(),  name="category-create"),
    path("workers/",                 views.WorkerListView.as_view(),      name="worker-list"),
    path("workers/create/",          views.WorkerCreateView.as_view(),    name="worker-create"),
    path("workers/me/",              views.MyWorkerProfileView.as_view(), name="worker-me"),
    path("workers/me/stats/",        views.MyWorkerStatsView.as_view(),   name="worker-me-stats"),
    path("workers/<int:pk>/",        views.WorkerDetailView.as_view(),    name="worker-detail"),
    path("workers/<int:pk>/stats/",  views.WorkerStatsView.as_view(),     name="worker-stats"),
]
