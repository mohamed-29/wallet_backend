from django.views.generic import TemplateView, ListView, FormView
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.urls import reverse_lazy
from django.shortcuts import redirect, get_object_or_404
from django.contrib import messages
from users.models import MobileUser
from wallets.models import Wallet, WalletLedger
from orders.models import Order
from notifications.tasks import send_notification_task
from django import forms
from django.db.models import Sum

class StaffRequiredMixin(UserPassesTestMixin):
    def test_func(self):
        return self.request.user.is_staff

class DashboardHomeView(LoginRequiredMixin, StaffRequiredMixin, TemplateView):
    template_name = 'dashboard/home.html'

    def get_context_data(self, **kwargs):
        from decimal import Decimal
        context = super().get_context_data(**kwargs)
        context['total_users'] = MobileUser.objects.count()
        total_cents = Wallet.objects.aggregate(Sum('balance_cents'))['balance_cents__sum'] or 0
        context['total_balance_display'] = Decimal(total_cents) / Decimal(100)
        context['total_orders'] = Order.objects.count()
        context['recent_orders'] = Order.objects.order_by('-created_at')[:10]
        return context

class UserListView(LoginRequiredMixin, StaffRequiredMixin, ListView):
    model = MobileUser
    template_name = 'dashboard/user_list.html'
    context_object_name = 'mobile_users'
    paginate_by = 20

    def get_queryset(self):
        query = self.request.GET.get('q')
        if query:
            return MobileUser.objects.filter(phone_number__icontains=query) | \
                   MobileUser.objects.filter(username__icontains=query)
        return MobileUser.objects.all()

class ChargeUserForm(forms.Form):
    amount_cents = forms.IntegerField(min_value=1, label="Amount (Cents)")
    description = forms.CharField(required=False, widget=forms.Textarea(attrs={'rows': 2}))

class ChargeUserView(LoginRequiredMixin, StaffRequiredMixin, FormView):
    form_class = ChargeUserForm
    template_name = 'dashboard/charge_user.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['target_user'] = get_object_or_404(MobileUser, pk=self.kwargs['pk'])
        return context

    def form_valid(self, form):
        from django.db import transaction

        user = get_object_or_404(MobileUser, pk=self.kwargs['pk'])
        amount = form.cleaned_data['amount_cents']

        with transaction.atomic():
            wallet, _ = Wallet.objects.get_or_create(user=user)
            wallet = Wallet.objects.select_for_update().get(id=wallet.id)
            wallet.balance_cents += amount
            wallet.save()

            WalletLedger.objects.create(
                wallet=wallet,
                transaction_type='CREDIT',
                amount_cents=amount,
                metadata={
                    'source': 'dashboard_manual',
                    'admin': self.request.user.username,
                    'description': form.cleaned_data['description']
                }
            )

        messages.success(self.request, f"Successfully charged {amount/100:.2f} EGP to {user.username}")
        return redirect('dashboard:user-list')

class SendNotificationForm(forms.Form):
    title = forms.CharField(max_length=255)
    body = forms.CharField(widget=forms.Textarea)
    broadcast = forms.BooleanField(required=False, label="Broadcast to ALL users")

class SendNotificationView(LoginRequiredMixin, StaffRequiredMixin, FormView):
    form_class = SendNotificationForm
    template_name = 'dashboard/send_notification.html'
    success_url = reverse_lazy('dashboard:home')

    def form_valid(self, form):
        title = form.cleaned_data['title']
        body = form.cleaned_data['body']
        
        if form.cleaned_data['broadcast']:
            users = MobileUser.objects.all()
            for user in users:
                send_notification_task.delay(user.id, title, body)
            messages.success(self.request, f"Broadcast queued for {users.count()} users.")
        else:
            # Logic for specific user could be added here
            messages.warning(self.request, "Single user notification not yet implemented in this view.")
            
        return super().form_valid(form)
