from django.contrib import admin
from .models import Favorite


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display  = ["id", "client", "worker", "created_at"]
    search_fields = ["client__username", "worker__username"]
