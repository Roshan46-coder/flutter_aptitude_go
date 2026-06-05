import os
import django
from django.utils import timezone
from datetime import timedelta
from dateutil import parser

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.contrib.auth import get_user_model
from events.models import Event
from events.forms import EventForm

User = get_user_model()

def debug_event_delisting():
    print("Debugging Event Delisting...")
    
    # 1. Create a Recruiter
    recruiter, _ = User.objects.get_or_create(username='debug_recruiter', defaults={'email': 'debug@example.com', 'is_company': True})
    
    # 2. Simulate User Input: Start time 15 mins ago, Duration 10 mins.
    # Should end 5 mins ago.
    # Note: EventForm expects start_time based on what DateTimeInput returns (usually aware or naive depending on settings).
    # Since we set TIME_ZONE = 'Asia/Kolkata', timezone.now() returns aware Time in UTC or Local?
    # timezone.now() is ALWAYS UTC if USE_TZ=True.
    
    now_utc = timezone.now()
    start_time_input = now_utc - timedelta(minutes=15)
    
    print(f"Current Time (UTC): {now_utc}")
    print(f"Input Start Time (UTC): {start_time_input}")
    
    # Creating event via Form to mimic view behavior perfectly
    form_data = {
        'title': 'Debug Event',
        'description': 'Debug Description',
        'start_time': start_time_input, # In a real form, this comes as string or datetime
        'event_duration': 10,
        'total_questions': 5,
        'time_limit_seconds': 600,
        'threshold_type': 'TIME',
        'threshold_value': 0,
        'category': ''
    }
    
    form = EventForm(data=form_data)
    # We might need to override the clean method or pass a valid category if required, let's see.
    # category is not required in my memory of the model, let's check field definition.
    # It says 'fields = [...]', category is foreign key.
    
    if form.is_valid():
        event = form.save(commit=False)
        event.recruiter = recruiter
        event.save()
        
        print(f"Event Created: {event.title}")
        print(f"Stored Start Time: {event.start_time}")
        print(f"Stored End Time: {event.end_time}")
        
        expected_end = start_time_input + timedelta(minutes=10)
        print(f"Expected End Time: {expected_end}")
        
        # Check Filter Logic
        # Filter is: end_time__gt=now
        is_visible = Event.objects.filter(id=event.id, end_time__gt=timezone.now()).exists()
        
        if is_visible:
            print("FAIL: Event is STILL VISIBLE in list (Delisting failed).")
            diff = event.end_time - timezone.now()
            print(f"Difference (End - Now): {diff}")
        else:
            print("PASS: Event is NOT VISIBLE (Delisting worked).")
            
        # Cleanup
        event.delete()
        recruiter.delete()
        
    else:
        print(f"Form Invalid: {form.errors}")
        # Try creating manually if form fails due to category
        if 'category' in form.errors:
             print("Skipping category validaton for debug...")
             # ... logic to create manually

if __name__ == '__main__':
    debug_event_delisting()
