from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = [
        "username", "name_ar", "phone", "governorate", "city",
        "role", "is_active", "date_joined",
    ]
    list_filter = ["role", "is_active", "governorate"]
    search_fields = ["username", "name_ar", "phone", "email", "city"]
    fieldsets = UserAdmin.fieldsets + (
        ("Profile", {"fields": ("name_ar", "phone", "avatar", "role")}),
        ("Location", {"fields": ("governorate", "city", "address")}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ("Profile", {"fields": ("name_ar", "phone", "role")}),
        ("Location", {"fields": ("governorate", "city", "address")}),
    )
