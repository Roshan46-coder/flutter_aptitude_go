from django.db import models
from django.conf import settings

class Category(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = "Categories"

    def __str__(self):
        return self.name

class Question(models.Model):
    DIFFICULTY_CHOICES = [
        ('EASY', 'Easy'),
        ('MEDIUM', 'Medium'),
        ('HARD', 'Hard'),
    ]
    QUESTION_TYPE_CHOICES = [
        ('MCQ', 'Multiple Choice Question'),
        ('LOGICAL', 'Logical Reasoning'),
        ('CODING', 'Coding/Programming'),
    ]
    
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='questions')
    text = models.TextField()
    explanation = models.TextField(blank=True, help_text="Explanation for the correct answer")
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='MEDIUM')
    question_type = models.CharField(max_length=15, choices=QUESTION_TYPE_CHOICES, default='MCQ')
    time_limit = models.IntegerField(default=60, help_text="Time limit for this question in seconds")
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_coding_problem(self):
        """Coding problems have only 1 placeholder option; MCQs have 2+. Or explicitly Typed."""
        return self.question_type == 'CODING' or self.options.count() <= 1

    def __str__(self):
        return self.text[:50]

class Option(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='options')
    text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)

    def __str__(self):
        return self.text

class TestAttempt(models.Model):
    MODE_CHOICES = [
        ('SOLO', 'Solo'),
        ('MULTI', 'Multiplayer'),
        ('TOURNAMENT', 'Tournament'),
    ]
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='test_attempts')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True)
    score = models.IntegerField()
    total_questions = models.IntegerField()
    coins_earned = models.IntegerField(default=0)
    exp_earned = models.IntegerField(default=0)
    mode = models.CharField(max_length=20, choices=MODE_CHOICES, default='SOLO')
    completed_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.score}/{self.total_questions}"
