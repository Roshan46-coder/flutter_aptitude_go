import os
import django
from django.urls import reverse
from django.conf import settings

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

try:
    print("Attempting to reverse 'recruiter_dashboard'...")
    url = reverse('recruiter_dashboard')
    print(f"Success! URL: {url}")
except Exception as e:
    print(f"Caught expected exception: {e}")

try:
    print("\nAttempting to reverse 'recruiter_events'...")
    url = reverse('recruiter_events')
    print(f"Success! URL: {url}")
except Exception as e:
    print(f"Failed to reverse 'recruiter_events': {e}")
