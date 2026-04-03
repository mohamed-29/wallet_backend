from django.urls import path
from .views import DashboardHomeView, UserListView, ChargeUserView, SendNotificationView

app_name = 'dashboard'

urlpatterns = [
    path('', DashboardHomeView.as_view(), name='home'),
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/charge/', ChargeUserView.as_view(), name='charge-user'),
    path('notifications/send/', SendNotificationView.as_view(), name='send-notification'),
]
