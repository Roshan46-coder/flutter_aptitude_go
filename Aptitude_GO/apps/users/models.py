from django.contrib.auth.models import AbstractUser
from django.db import models

class CustomUser(AbstractUser):
    level = models.PositiveIntegerField(default=1)
    exp = models.PositiveIntegerField(default=0)
    coins = models.PositiveIntegerField(default=0)
    lives = models.PositiveIntegerField(default=5)
    last_life_refill = models.DateTimeField(null=True, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    
    # Onboarding Fields
    current_status = models.CharField(max_length=50, blank=True)
    interested_field = models.CharField(max_length=255, blank=True)
    organization = models.CharField(max_length=255, blank=True, help_text="Company Name, College, etc.")
    
    # Company Fields
    is_company = models.BooleanField(default=False)
    hiring_focus = models.CharField(max_length=255, blank=True)

    # Social Links
    linkedin_url = models.URLField(max_length=255, blank=True, null=True)
    github_url = models.URLField(max_length=255, blank=True, null=True)

    # Profile Data & Score
    profile_data = models.JSONField(default=dict, blank=True)
    profile_score = models.PositiveIntegerField(default=0)

    # Recruiter Profile Data
    recruiter_profile_data = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return self.username

class AIChatMessage(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='aptix_conversations')
    role = models.CharField(max_length=10, choices=[('user', 'User'), ('assistant', 'Assistant')])
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"{self.user.username} - {self.role} - {self.timestamp}"

class Conversation(models.Model):
    participants = models.ManyToManyField(CustomUser, related_name='conversations')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Conversation {self.id}"

class Message(models.Model):
    conversation = models.ForeignKey(Conversation, related_name='messages', on_delete=models.CASCADE)
    sender = models.ForeignKey(CustomUser, related_name='sent_messages', on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        return f"Message from {self.sender.username} at {self.timestamp}"

class Certificate(models.Model):
    user = models.ForeignKey(CustomUser, related_name='certificates', on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    file = models.FileField(upload_to='certificates/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} ({self.user.username})"

    @property
    def is_image(self):
        name = self.file.name.lower()
        return name.endswith('.jpg') or name.endswith('.jpeg') or name.endswith('.png') or name.endswith('.webp')

class SiteSetting(models.Model):
    anti_malpractice_enabled = models.BooleanField(default=True, help_text="Global toggle for anti-malpractice features across all tests.")
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return "Global Site Settings"

    @classmethod
    def get_settings(cls):
        setting, created = cls.objects.get_or_create(id=1)
        return setting
