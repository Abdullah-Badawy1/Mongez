from django.urls import path
from . import views

urlpatterns = [
    path("admin/dashboard/", views.AdminDashboardView.as_view(), name="admin-dashboard"),
    path("admin/users/", views.AdminUserListView.as_view(), name="admin-user-list"),
    path("admin/users/create/", views.AdminUserCreateView.as_view(), name="admin-user-create"),
    path("admin/users/<int:pk>/", views.AdminUserDetailView.as_view(), name="admin-user-detail"),
    path("admin/categories/<int:pk>/", views.AdminCategoryUpdateDeleteView.as_view(), name="admin-category-detail"),
    path("admin/payments/", views.AdminPaymentListView.as_view(), name="admin-payment-list"),
    path("admin/orders/<int:pk>/status/", views.AdminOrderStatusView.as_view(), name="admin-order-status"),
    path("admin/workers/", views.AdminWorkerListView.as_view(), name="admin-worker-list"),
    path("admin/workers/<int:pk>/", views.AdminWorkerDetailView.as_view(), name="admin-worker-detail"),
    path("admin/ratings/", views.AdminRatingListView.as_view(), name="admin-rating-list"),
    path("admin/export/orders.csv", views.AdminOrdersCSVView.as_view(), name="admin-export-orders"),
    path("admin/export/workers.csv", views.AdminWorkersCSVView.as_view(), name="admin-export-workers"),
    path("admin/export/users.csv", views.AdminUsersCSVView.as_view(), name="admin-export-users"),
    path("admin/export/payments.csv", views.AdminPaymentsCSVView.as_view(), name="admin-export-payments"),
]
