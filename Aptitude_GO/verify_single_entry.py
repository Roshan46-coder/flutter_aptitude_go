import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.test import RequestFactory
from django.contrib.auth import get_user_model
from events.models import Event, EventRegistration
from events.views import event_detail

User = get_user_model()

def test_single_entry_restriction():
    print("Testing Single Entry Restriction...")
    
    # Setup data
    recruiter, _ = User.objects.get_or_create(username='test_recruiter_single', defaults={'email': 'rec_s@example.com', 'is_company': True})
    student, _ = User.objects.get_or_create(username='test_student_single', defaults={'email': 'stu_s@example.com'})
    
    event = Event.objects.create(
        title='Single Entry Test Event',
        recruiter=recruiter,
        start_time=timezone.now() - timedelta(minutes=10), # Started 10 mins ago
        end_time=timezone.now() + timedelta(hours=1),
        is_active=True,
        total_questions=5
    )
    
    # Register and Complete
    reg = EventRegistration.objects.create(
        event=event,
        user=student,
        score=5,
        completed_at=timezone.now()
    )
    
    # Create request
    factory = RequestFactory()
    request = factory.get(f'/events/{event.id}/')
    request.user = student
    
    try:
        response = event_detail(request, event.id)
        if response.status_code == 200:
            content = response.content.decode()
            
            if 'Event Completed!' in content:
                print("PASS: 'Event Completed!' message found.")
            else:
                print("FAIL: 'Event Completed!' message NOT found.")
                
            if 'START TEST' not in content:
                print("PASS: 'START TEST' button is hidden.")
            else:
                 # Check if it's hidden via display:none or actually not rendered.
                 # My edit put it in an {% else %} block, so it should be absent from HTML entirely if checking raw string,
                 # unless I missed something in template logic.
                 # Ah, wait. The `start-btn-container` div is `display: none` by default and toggled by JS.
                 # BUT the *content* inside is what I changed.
                 # The "START TEST" text should be in the `else` block of `{% if registration.completed_at %}`.
                 print("FAIL: 'START TEST' button/text found in response.")
        else:
            print(f"FAIL: View returned status {response.status_code}")
            
    except Exception as e:
        print(f"FAIL: Error executing view: {e}")
        
    # Cleanup
    event.delete()
    recruiter.delete()
    student.delete()

if __name__ == '__main__':
    test_single_entry_restriction()
