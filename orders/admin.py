from django.contrib import admin
from .models import Order

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('device_order_id', 'user', 'machine_id', 'slot', 'amount_paid_cents', 'status', 'created_at')
    list_filter = ('status', 'created_at', 'machine_id')
    search_fields = ('device_order_id', 'user__username', 'machine_id')
    readonly_fields = ('device_order_id', 'created_at', 'updated_at')
