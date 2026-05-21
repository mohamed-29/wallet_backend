from django.urls import path
from django.contrib.auth import views as auth_views
from .views import DashboardHomeView, UserListView, ChargeUserView, DrawdownUserView, SendNotificationView

app_name = 'dashboard'

urlpatterns = [
    path('login/', auth_views.LoginView.as_view(template_name='dashboard/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='dashboard:login'), name='logout'),
    path('', DashboardHomeView.as_view(), name='home'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/charge/', ChargeUserView.as_view(), name='charge-user'),
    path('users/<int:pk>/drawdown/', DrawdownUserView.as_view(), name='drawdown-user'),
    path('notifications/send/', SendNotificationView.as_view(), name='send-notification'),
]
