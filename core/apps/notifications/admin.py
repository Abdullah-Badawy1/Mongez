from django.contrib import admin
from .models import DeviceToken, Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["id", "user", "title", "type", "is_read", "created_at"]
    list_filter = ["type", "is_read"]
    search_fields = ["user__username", "title"]
    readonly_fields = ["created_at"]


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ["id", "user", "platform", "is_active", "last_seen_at"]
    list_filter = ["platform", "is_active"]
    search_fields = ["user__username", "token"]
    readonly_fields = ["created_at", "last_seen_at"]
