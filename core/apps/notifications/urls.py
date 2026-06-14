from django.urls import path
from . import views

urlpatterns = [
    path("notifications/",
         views.NotificationListView.as_view(),
         name="notification-list"),
    path("notifications/unread-count/",
         views.NotificationUnreadCountView.as_view(),
         name="notification-unread-count"),
    path("notifications/read-all/",
         views.NotificationMarkAllReadView.as_view(),
         name="notification-read-all"),
    path("notifications/devices/",
         views.DeviceTokenRegisterView.as_view(),
         name="notification-device-register"),
    path("notifications/<int:pk>/read/",
         views.NotificationMarkReadView.as_view(),
         name="notification-read"),
]
