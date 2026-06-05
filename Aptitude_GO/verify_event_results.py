import os
import django
from django.conf import settings
from django.utils import timezone
from datetime import timedelta

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from events.models import Event
from events.forms import EventForm
from django.contrib.auth import get_user_model

User = get_user_model()

def test_delisting_logic():
    print("Testing Automatic Delisting Logic...")
    
    # Create a dummy recruiter
    recruiter, _ = User.objects.get_or_create(username='test_recruiter', defaults={'email': 'test@example.com', 'is_company': True})
    
    # Simulate form data
    start_time = timezone.now() + timedelta(hours=1)
    form_data = {
        'title': 'Test Event',
        'description': 'Test Description',
        'start_time': start_time,
        'event_duration': 60, # 60 minutes
        'total_questions': 10,
        'time_limit_seconds': 600,
        'threshold_type': 'TIME',
        'threshold_value': 0
    }
    
    form = EventForm(data=form_data)
    if form.is_valid():
        event = form.save(commit=False)
        event.recruiter = recruiter
        event.save()
        
        expected_end_time = start_time + timedelta(minutes=60)
        
        # Check if end_time matches
        # Note: Database might lose some microsecond precision, so we check equality roughly or exactly
        if abs((event.end_time - expected_end_time).total_seconds()) < 1:
             print(f"PASS: End time calculated correctly. Start: {start_time}, Duration: 60m, End: {event.end_time}")
        else:
             print(f"FAIL: End time mismatch. Expected {expected_end_time}, got {event.end_time}")
             
        # Cleanup
        event.delete()
    else:
        print(f"FAIL: Form validation failed: {form.errors}")

def test_results_url():
    print("\nTesting Results URL Resolution...")
    from django.urls import reverse, resolve
    
    try:
        url = reverse('event_results', args=[1])
        print(f"PASS: URL reversed to {url}")
        
        match = resolve(url)
        if match.view_name == 'event_results':
             print("PASS: URL resolving to correct view name")
        else:
             print(f"FAIL: URL resolved to {match.view_name}")
    except Exception as e:
        print(f"FAIL: URL resolution error: {e}")

def test_results_view_content():
    print("\nTesting Results View Content...")
    from django.test import RequestFactory
    from events.views import event_results
    from events.models import EventRegistration
    
    # Setup data
    recruiter, _ = User.objects.get_or_create(username='test_recruiter_view', defaults={'email': 'rec@example.com', 'is_company': True})
    student, _ = User.objects.get_or_create(username='test_student_view', defaults={'email': 'stu@example.com'})
    
    event = Event.objects.create(
        title='View Test Event',
        recruiter=recruiter,
        start_time=timezone.now() + timedelta(hours=1),
        end_time=timezone.now() + timedelta(hours=2),
        is_active=True
    )
    
    EventRegistration.objects.create(
        event=event,
        user=student,
        score=85,
        completed_at=timezone.now()
    )
    
    # Create request
    factory = RequestFactory()
    request = factory.get(f'/events/{event.id}/results/')
    request.user = recruiter
    
    try:
        response = event_results(request, event.id)
        if response.status_code == 200:
            print("PASS: View returned 200 OK")
            content = response.content.decode()
            if 'test_student_view' in content and '85' in content:
                print("PASS: View contains student username and score")
            else:
                print("FAIL: View missing data")
        else:
            print(f"FAIL: View returned status {response.status_code}")
            
    except Exception as e:
        print(f"FAIL: View execution error: {e}")
        
    # Cleanup
    event.delete()
    recruiter.delete()
    student.delete()

if __name__ == '__main__':
    test_delisting_logic()
    test_results_url()
    test_results_view_content()
