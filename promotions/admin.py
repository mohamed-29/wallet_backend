from django.contrib import admin
from .models import Promotion, UserPromotion

@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ('code', 'promo_type', 'value', 'is_active', 'valid_until')
    list_filter = ('promo_type', 'is_active')
    search_fields = ('code',)

@admin.register(UserPromotion)
class UserPromotionAdmin(admin.ModelAdmin):
    list_display = ('user', 'promotion', 'is_used', 'used_at')
    list_filter = ('is_used', 'claimed_at')
    search_fields = ('user__username', 'promotion__code')
