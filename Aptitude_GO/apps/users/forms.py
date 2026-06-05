from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth import get_user_model
from apps.users.models import Certificate

User = get_user_model()

class CustomUserCreationForm(UserCreationForm):
    class Meta:
        model = User
        fields = ('username', 'email')

    def clean_email(self):
        email = self.cleaned_data.get('email')
        if email and User.objects.filter(email__iexact=email).exists():
            raise forms.ValidationError("This email address is already in use. Please use a different email or log in.")
        return email

class CertificateForm(forms.ModelForm):
    class Meta:
        model = Certificate
        fields = ['title', 'file']

class UserUpdateForm(forms.ModelForm):
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'current_status', 'interested_field', 'organization', 'linkedin_url', 'github_url']
        labels = {
            'organization': 'Place of Work / College',
            'current_status': 'Current Job / Status',
            'interested_field': 'Field of Interest',
            'linkedin_url': 'LinkedIn Profile URL',
            'github_url': 'GitHub Profile URL'
        }

    def clean_email(self):
        email = self.cleaned_data.get('email')
        # Check if the email exists but belongs to a different user
        if email and User.objects.filter(email__iexact=email).exclude(pk=self.instance.pk).exists():
            raise forms.ValidationError("This email address is already registered to another account.")
        return email
