import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Question, Option

def check_integrity():
    questions = Question.objects.all()
    count_bad = 0
    total = questions.count()
    
    print(f"Checking {total} questions for data integrity...")
    
    for q in questions:
        correct_opts = q.options.filter(is_correct=True)
        if correct_opts.count() == 0:
            print(f"[WARNING] Question ID {q.id} has NO correct option: '{q.text[:50]}...'")
            count_bad += 1
        elif correct_opts.count() > 1:
            print(f"[INFO] Question ID {q.id} has {correct_opts.count()} correct options.")

    if count_bad == 0:
        print("All questions have at least one correct option.")
    else:
        print(f"Found {count_bad} questions with no correct option.")

if __name__ == "__main__":
    check_integrity()
