from django.db import models

class VendingLocation(models.Model):
    name = models.CharField(max_length=255)
    building = models.CharField(max_length=255)
    floor = models.CharField(max_length=255)
    distance_text = models.CharField(max_length=50, help_text="e.g. 0.2 km")
    is_open = models.BooleanField(default=True)
    hours_text = models.CharField(max_length=100, help_text="e.g. Open 24/7")
    categories = models.JSONField(default=list, help_text="e.g. ['Snacks', 'Drinks']")
    machine_count = models.PositiveIntegerField(default=1)
    lat = models.FloatField()
    lng = models.FloatField()

    def __str__(self):
        return self.name
