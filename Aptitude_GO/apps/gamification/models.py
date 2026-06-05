from django.db import models
from django.conf import settings

class StoreItem(models.Model):
    ITEM_TYPES = [
        ('AVATAR', 'Avatar'),
        ('FRAME', 'Profile Frame'),
        ('THEME', 'Background Theme'),
        ('BADGE', 'Profile Badge'),
        ('LIFE_REFILL', 'Life Refill'),
    ]
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    cost = models.PositiveIntegerField()
    item_type = models.CharField(max_length=20, choices=ITEM_TYPES)
    image = models.ImageField(upload_to='store_items/', null=True, blank=True)
    min_level_required = models.PositiveIntegerField(default=1)

    def __str__(self):
        return self.name

class UserItem(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='inventory')
    item = models.ForeignKey(StoreItem, on_delete=models.CASCADE)
    purchased_at = models.DateTimeField(auto_now_add=True)
    is_equipped = models.BooleanField(default=False)

    class Meta:
        unique_together = ('user', 'item')

    def __str__(self):
        return f"{self.user.username} - {self.item.name}"

class MonthlySpin(models.Model):
    REWARD_TYPES = [
        ('COINS', 'Coins'),
        ('LIVES', 'Lives'),
        ('FRAME', 'Golden Frame'),
    ]
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='monthly_spins')
    spin_date = models.DateTimeField(auto_now_add=True)
    reward_type = models.CharField(max_length=10, choices=REWARD_TYPES)
    reward_value = models.IntegerField()  # Number of coins/lives or StoreItem ID

    class Meta:
        ordering = ['-spin_date']

    def __str__(self):
        return f"{self.user.username} - {self.reward_type} ({self.reward_value}) on {self.spin_date.strftime('%Y-%m')}"
