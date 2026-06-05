from django import forms
from .models import Event, EventQuestion
from django.utils import timezone

class EventForm(forms.ModelForm):
    event_duration = forms.IntegerField(
        label="Event Availability (Minutes)", 
        min_value=5, 
        initial=60,
        help_text="How long the event link remains active"
    )

    class Meta:
        model = Event
        fields = [
            'title', 'category', 'description', 'start_time',
            'total_questions', 'time_limit_seconds', 'threshold_type', 'threshold_value'
        ]
        widgets = {
            'start_time': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
            'description': forms.Textarea(attrs={'rows': 3}),
        }

    def clean(self):
        cleaned_data = super().clean()
        start_time = cleaned_data.get('start_time')
        
        if start_time:
            if start_time < timezone.now():
                raise forms.ValidationError("Start time cannot be in the past.")
        
        return cleaned_data

    def save(self, commit=True):
        instance = super().save(commit=False)
        start = self.cleaned_data.get('start_time')
        duration = self.cleaned_data.get('event_duration')
        
        if start and duration:
            instance.end_time = start + timezone.timedelta(minutes=duration)
            
        if commit:
            instance.save()
        return instance

class EventQuestionForm(forms.ModelForm):
    class Meta:
        model = EventQuestion
        fields = ['text', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_option', 'marks']
        widgets = {
            'text': forms.Textarea(attrs={'rows': 2, 'placeholder': 'Enter question text...'}),
            'option_a': forms.TextInput(attrs={'placeholder': 'Option A'}),
            'option_b': forms.TextInput(attrs={'placeholder': 'Option B'}),
            'option_c': forms.TextInput(attrs={'placeholder': 'Option C'}),
            'option_d': forms.TextInput(attrs={'placeholder': 'Option D'}),
        }
