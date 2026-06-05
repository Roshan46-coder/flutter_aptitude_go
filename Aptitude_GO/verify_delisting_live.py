import os
import django
from django.utils import timezone
from datetime import timedelta
from django.test import Client

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.contrib.auth import get_user_model
from events.models import Event

User = get_user_model()

def verify_delisting_live():
    print("Verifying Delisting Logic via Client...")
    
    # 1. Setup Candidate and Recruiter
    recruiter, _ = User.objects.get_or_create(username='verify_rec', defaults={'email': 'ver_rec@example.com', 'is_company': True})
    recruiter.set_password('password')
    recruiter.save()
    
    student, _ = User.objects.get_or_create(username='verify_stu', defaults={'email': 'ver_stu@example.com'})
    student.set_password('password')
    student.save()
    
    client = Client()
    client.force_login(student)
    
    # 2. Create an EXPIRED Event
    # Assuming the user meant: Event started 15 mins ago, duration 10 mins -> ended 5 mins ago.
    start_time = timezone.now() - timedelta(minutes=15)
    end_time = start_time + timedelta(minutes=10)
    
    expired_event = Event.objects.create(
        title='Expired Event',
        recruiter=recruiter,
        start_time=start_time,
        end_time=end_time,
        total_questions=5,
        time_limit_seconds=600
        # event_duration=10 # This field might not be in model but form uses it? No, model doesn't have it.
        # But we create via ORM here.
    )
    
    # 3. Create an ACTIVE Event
    active_event = Event.objects.create(
        title='Active Event',
        recruiter=recruiter,
        start_time=timezone.now() + timedelta(minutes=5),
        end_time=timezone.now() + timedelta(minutes=65),
         total_questions=5
    )
    
    # 4. Check Event List
    response = client.get('/events/') # Adjust URL if needed
    
    if response.status_code == 200:
        content = response.content.decode()
        
        if 'Expired Event' in content:
            print("FAIL: 'Expired Event' is VISIBLE.")
        else:
            print("PASS: 'Expired Event' is HIDDEN.")
            
        if 'Active Event' in content:
            print("PASS: 'Active Event' is VISIBLE.")
        else:
            print("FAIL: 'Active Event' is HIDDEN.")
    else:
        print(f"FAIL: Status code {response.status_code}")
        
    # Cleanup
    expired_event.delete()
    active_event.delete()
    recruiter.delete()
    student.delete()

if __name__ == '__main__':
    verify_delisting_live()
