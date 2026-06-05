import os
import django
from django.utils import timezone
from datetime import timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.test import RequestFactory
from django.contrib.auth import get_user_model
from events.models import Event, EventQuestion, EventRegistration
from events.views import take_event

User = get_user_model()

def test_question_limit():
    print("Testing Question Limit Logic...")
    
    # Setup data
    recruiter, _ = User.objects.get_or_create(username='test_recruiter_limit', defaults={'email': 'rec_l@example.com', 'is_company': True})
    student, _ = User.objects.get_or_create(username='test_student_limit', defaults={'email': 'stu_l@example.com'})
    
    # Event with limit 2, but 3 questions added
    event = Event.objects.create(
        title='Limit Test Event',
        recruiter=recruiter,
        start_time=timezone.now() - timedelta(minutes=10),
        end_time=timezone.now() + timedelta(hours=1),
        is_active=True,
        total_questions=2
    )
    
    # Create 3 questions
    q1 = EventQuestion.objects.create(event=event, text="Q1", option_a="A", option_b="B", option_c="C", option_d="D", correct_option="A", marks=1)
    q2 = EventQuestion.objects.create(event=event, text="Q2", option_a="A", option_b="B", option_c="C", option_d="D", correct_option="B", marks=1)
    q3 = EventQuestion.objects.create(event=event, text="Q3", option_a="A", option_b="B", option_c="C", option_d="D", correct_option="C", marks=1)
    
    EventRegistration.objects.create(event=event, user=student)
    
    # Test GET (Display)
    factory = RequestFactory()
    request = factory.get(f'/events/{event.id}/take/')
    request.user = student
    
    try:
        response = take_event(request, event.id)
        if response.status_code == 200:
            # We can check context data if available, but render returns HttpResponse.
            # So we check content roughly or we trust unit test logic.
            # Actually, let's verify logic by simulating POST which re-runs the query.
            pass
        else:
            print(f"FAIL: GET view returned status {response.status_code}")
            
    except Exception as e:
         print(f"FAIL: GET error: {e}")

    # Test POST (Scoring)
    # Correctly answer all 3 questions. Logic should only count first 2 (score 2).
    # If logic was wrong and included 3rd, score would be 3.
    data = {
        f'question_{q1.id}': 'A',
        f'question_{q2.id}': 'B',
        f'question_{q3.id}': 'C'
    }
    
    request = factory.post(f'/events/{event.id}/take/', data=data)
    request.user = student
    # Add message storage mock
    from django.contrib.messages.storage.fallback import FallbackStorage
    setattr(request, 'session', 'session')
    messages = FallbackStorage(request)
    setattr(request, '_messages', messages)
    
    try:
        response = take_event(request, event.id)
        if response.status_code == 302:
            reg = EventRegistration.objects.get(user=student, event=event)
            if reg.score == 2:
                print(f"PASS: Score is {reg.score} (Expected 2). Limit worked.")
            else:
                print(f"FAIL: Score is {reg.score} (Expected 2). Limit failed.")
        else:
            print(f"FAIL: POST view returned status {response.status_code}")
            
    except Exception as e:
        print(f"FAIL: POST error: {e}")
        import traceback
        traceback.print_exc()

    # Cleanup
    event.delete()
    recruiter.delete()
    student.delete()

if __name__ == '__main__':
    test_question_limit()
