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
from decimal import Decimal, ROUND_HALF_UP


def _egp_to_cents(amount_egp):
    """Convert an EGP Decimal amount to integer cents."""
    return int((Decimal(amount_egp) * 100).quantize(Decimal('1'), rounding=ROUND_HALF_UP))


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

        ledger = (WalletLedger.objects
                  .select_related('wallet__user')
                  .order_by('-timestamp')[:15])
        activity = []
        for entry in ledger:
            meta = entry.metadata or {}
            source = meta.get('source', '')
            if entry.transaction_type == 'CREDIT':
                action, kind = 'Top-up', 'credit'
            elif source == 'dashboard_manual_drawdown':
                action, kind = 'Draw-down', 'debit'
            else:
                action, kind = 'Purchase', 'debit'
            activity.append({
                'timestamp': entry.timestamp,
                'username': entry.wallet.user.username,
                'action': action,
                'kind': kind,
                'amount': f"{entry.amount_cents / 100:.2f}",
                'admin': meta.get('admin', ''),
                'description': meta.get('description', ''),
            })
        context['recent_activity'] = activity
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
    amount_egp = forms.DecimalField(min_value=Decimal('0.01'), decimal_places=2, label="Amount (EGP)")
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
        amount = _egp_to_cents(form.cleaned_data['amount_egp'])

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

class DrawdownUserForm(forms.Form):
    amount_egp = forms.DecimalField(min_value=Decimal('0.01'), decimal_places=2, label="Amount (EGP)")
    description = forms.CharField(required=False, widget=forms.Textarea(attrs={'rows': 2}))

class DrawdownUserView(LoginRequiredMixin, StaffRequiredMixin, FormView):
    form_class = DrawdownUserForm
    template_name = 'dashboard/drawdown_user.html'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['target_user'] = get_object_or_404(MobileUser, pk=self.kwargs['pk'])
        return context

    def form_valid(self, form):
        from django.db import transaction

        user = get_object_or_404(MobileUser, pk=self.kwargs['pk'])
        amount = _egp_to_cents(form.cleaned_data['amount_egp'])

        with transaction.atomic():
            wallet, _ = Wallet.objects.get_or_create(user=user)
            wallet = Wallet.objects.select_for_update().get(id=wallet.id)

            if wallet.balance_cents < amount:
                messages.error(self.request, f"Failed: User only has {wallet.balance_cents/100:.2f} EGP in their wallet.")
                return redirect('dashboard:user-list')

            wallet.balance_cents -= amount
            wallet.save()

            WalletLedger.objects.create(
                wallet=wallet,
                transaction_type='DEBIT',
                amount_cents=amount,
                metadata={
                    'source': 'dashboard_manual_drawdown',
                    'admin': self.request.user.username,
                    'description': form.cleaned_data['description']
                }
            )

        messages.success(self.request, f"Successfully drew down {amount/100:.2f} EGP from {user.username}")
        return redirect('dashboard:user-list')

class SendNotificationForm(forms.Form):
    user = forms.ModelChoiceField(queryset=MobileUser.objects.all(), required=False, empty_label="--- Select a User ---", label="Target User")
    title = forms.CharField(max_length=255)
    body = forms.CharField(widget=forms.Textarea)
    broadcast = forms.BooleanField(required=False, label="Broadcast to ALL users")

    def clean(self):
        cleaned_data = super().clean()
        broadcast = cleaned_data.get('broadcast')
        user = cleaned_data.get('user')
        if not broadcast and not user:
            raise forms.ValidationError("You must select a user or choose broadcast.")
        return cleaned_data

class SendNotificationView(LoginRequiredMixin, StaffRequiredMixin, FormView):
    form_class = SendNotificationForm
    template_name = 'dashboard/send_notification.html'
    success_url = reverse_lazy('dashboard:home')

    def get_initial(self):
        initial = super().get_initial()
        user_id = self.request.GET.get('user')
        if user_id:
            initial['user'] = user_id
        return initial

    def form_valid(self, form):
        title = form.cleaned_data['title']
        body = form.cleaned_data['body']
        
        if form.cleaned_data['broadcast']:
            users = MobileUser.objects.all()
            for user in users:
                send_notification_task.delay(user.id, title, body)
            messages.success(self.request, f"Broadcast queued for {users.count()} users.")
        else:
            user = form.cleaned_data.get('user')
            send_notification_task.delay(user.id, title, body)
            messages.success(self.request, f"Notification queued for {user.username}.")
            
        return super().form_valid(form)
