from django.db import models
from django.contrib.auth.models import AbstractUser

class MobileUser(AbstractUser):
    phone_number = models.CharField(max_length=20, unique=True)
    language_preference = models.CharField(max_length=10, default='en')
    
    def __str__(self):
        return self.phone_number or self.username
