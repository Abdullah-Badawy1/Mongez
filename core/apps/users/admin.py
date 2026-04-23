from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display  = ["username", "phone", "address", "role", "is_active", "date_joined"]
    list_filter   = ["role", "is_active"]
    search_fields = ["username", "phone"]
    fieldsets = UserAdmin.fieldsets + (
        ("Extra Info", {"fields": ("phone", "address", "role")}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ("Extra Info", {"fields": ("phone", "address", "role")}),
    )
