from django.db import models
from django.conf import settings

class Match(models.Model):
    STATUS_CHOICES = (
        ('waiting', 'Waiting for Opponent'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled')
    )
    
    topic = models.CharField(max_length=100)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='waiting')
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)
    winner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='won_matches')
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Match {self.id} - {self.topic} ({self.status})"

class MatchPlayer(models.Model):
    match = models.ForeignKey(Match, on_delete=models.CASCADE, related_name='players')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='multiplayer_matches')
    score = models.IntegerField(default=0)
    finish_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, default='connected') # connected, disconnected, finished, forfeit
    is_winner = models.BooleanField(default=False)

    class Meta:
        unique_together = ('match', 'user')

    def __str__(self):
        return f"{self.user.username} in Match {self.match_id}"
