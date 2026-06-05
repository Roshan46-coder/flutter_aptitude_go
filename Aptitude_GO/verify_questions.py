import os
import django
import sys

# Flush stdout to ensure we catch all output
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.apps import apps
Category = apps.get_model('tests', 'Category')
Question = apps.get_model('tests', 'Question')

print(f"{'Category':<30} {'Questions Count':<15}")
print("-" * 45)

for category in Category.objects.all():
    count = Question.objects.filter(category=category).count()
    print(f"{category.name[:28]:<30} {count:<15}")
