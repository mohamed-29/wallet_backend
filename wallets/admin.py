from django.contrib import admin
from .models import Wallet, WalletLedger
from django import forms
from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.urls import path

class TopUpForm(forms.Form):
    amount_cents = forms.IntegerField(min_value=1, help_text="Amount in cents (e.g. 500 for L.E. 5.00)")
    description = forms.CharField(required=False, widget=forms.TextInput(attrs={'placeholder': 'e.g. Manual Adjustment'}))

@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ('user', 'balance_display', 'balance_cents')
    search_fields = ('user__username', 'user__phone_number')
    readonly_fields = ('balance_display',)

    actions = ['manual_top_up']

    def manual_top_up(self, request, queryset):
        if 'apply' in request.POST:
            form = TopUpForm(request.POST)
            if form.is_valid():
                amount = form.cleaned_data['amount_cents']
                desc = form.cleaned_data['description']
                for wallet in queryset:
                    wallet.balance_cents += amount
                    wallet.save()
                    WalletLedger.objects.create(
                        wallet=wallet,
                        transaction_type='CREDIT',
                        amount_cents=amount,
                        metadata={'source': 'manual_admin', 'description': desc, 'admin_user': request.user.username}
                    )
                self.message_user(request, f"Successfully topped up {queryset.count()} wallets.")
                return HttpResponseRedirect(request.get_full_path())
        else:
            form = TopUpForm()

        return render(request, 'admin/wallets/wallet/manual_top_up.html', {
            'wallets': queryset,
            'form': form,
            'title': 'Manual Wallet Top-up'
        })
    
    manual_top_up.short_description = "Perform Manual Top-up"

@admin.register(WalletLedger)
class WalletLedgerAdmin(admin.ModelAdmin):
    list_display = ('wallet', 'transaction_type', 'amount_cents', 'timestamp')
    list_filter = ('transaction_type', 'timestamp')
    search_fields = ('wallet__user__username', 'wallet__user__phone_number')
    readonly_fields = ('wallet', 'transaction_type', 'amount_cents', 'timestamp', 'metadata')
