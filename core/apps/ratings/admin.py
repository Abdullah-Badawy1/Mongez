from django.contrib import admin
from .models import Rating


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ["id", "client", "worker", "stars", "created_at"]
    list_filter = ["stars"]
    search_fields = ["client__username", "worker__username"]
    readonly_fields = ["client", "worker", "created_at"]
