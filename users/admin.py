from django.contrib import admin
from .models import MobileUser

@admin.register(MobileUser)
class MobileUserAdmin(admin.ModelAdmin):
    list_display = ('username', 'phone_number', 'email', 'is_staff', 'is_active')
    search_fields = ('username', 'phone_number', 'email')
    list_filter = ('is_staff', 'is_superuser', 'is_active')
