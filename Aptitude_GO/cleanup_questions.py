import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Question

def delete_bad_questions():
    questions = Question.objects.all()
    count = 0
    for q in questions:
        if q.options.filter(is_correct=True).count() == 0:
            print(f"Deleting bad question: {q.id} - {q.text[:30]}...")
            q.delete()
            count += 1
    print(f"Deleted {count} questions.")

if __name__ == "__main__":
    delete_bad_questions()
