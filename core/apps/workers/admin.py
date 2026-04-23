from django.contrib import admin
from .models import ServiceCategory, WorkerProfile


@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ["id", "name"]
    search_fields = ["name"]


@admin.register(WorkerProfile)
class WorkerProfileAdmin(admin.ModelAdmin):
    list_display = ["user", "profession", "experience_years",
                        "average_rating", "completed_jobs", "is_available"]
    list_filter = ["is_available"]
    search_fields = ["user__username", "profession"]
    readonly_fields = ["average_rating", "completed_jobs", "created_at"]
