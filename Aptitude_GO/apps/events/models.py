import random
import string
from django.db import models
from django.conf import settings
from django.utils import timezone
from apps.tests.models import Category

class Event(models.Model):
    THRESHOLD_CHOICES = [
        ('TIME', 'Time Based (First Come First Serve)'),
        ('LEVEL', 'Level Based'),
    ]

    title = models.CharField(max_length=200)
    recruiter = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='created_events')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True)
    description = models.TextField(blank=True)
    
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    
    total_questions = models.IntegerField(default=10)
    time_limit_seconds = models.IntegerField(default=600)  # Total time for the event test
    
    threshold_type = models.CharField(max_length=10, choices=THRESHOLD_CHOICES, default='TIME')
    threshold_value = models.IntegerField(default=0, help_text="Level required or Max participants")
    
    access_code = models.CharField(max_length=12, unique=True, blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @staticmethod
    def generate_unique_code():
        """Generate a unique 8-character alphanumeric exam access code."""
        while True:
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            if not Event.objects.filter(access_code=code).exists():
                return code

    def save(self, *args, **kwargs):
        if not self.access_code:
            self.access_code = self.generate_unique_code()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.title

    @property
    def is_live(self):
        now = timezone.now()
        return self.start_time <= now <= self.end_time

    @property
    def is_upcoming(self):
        return timezone.now() < self.start_time

    @property
    def test_duration_minutes(self):
        """Total time allowed for the test itself."""
        if self.time_limit_seconds <= 0:
            return 0
        return (self.time_limit_seconds + 59) // 60

    @property
    def event_duration_minutes(self):
        """Total window of time the event is available (End - Start)."""
        if not self.start_time or not self.end_time:
            return 0
        diff = self.end_time - self.start_time
        return int(diff.total_seconds() // 60)

    @property
    def duration_minutes(self):
        """Alias for backward compatibility with templates until updated."""
        return self.test_duration_minutes

class EventQuestion(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='questions')
    text = models.TextField()
    option_a = models.CharField(max_length=255)
    option_b = models.CharField(max_length=255)
    option_c = models.CharField(max_length=255)
    option_d = models.CharField(max_length=255)
    
    CORRECT_CHOICES = [
        ('A', 'Option A'),
        ('B', 'Option B'),
        ('C', 'Option C'),
        ('D', 'Option D'),
    ]
    correct_option = models.CharField(max_length=1, choices=CORRECT_CHOICES)
    
    marks = models.IntegerField(default=1)

    def __str__(self):
        return f"{self.text[:50]} ({self.event.title})"

class EventRegistration(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='event_registrations')
    registered_at = models.DateTimeField(auto_now_add=True)
    score = models.IntegerField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = ('event', 'user')

    def __str__(self):
        return f"{self.user.username} - {self.event.title}"
