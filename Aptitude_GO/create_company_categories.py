import os
import django
import sys
import json

# Flush stdout to ensure we catch all output
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.apps import apps
from django.conf import settings
from django.utils.text import slugify

Category = apps.get_model('tests', 'Category')
Question = apps.get_model('tests', 'Question')
Option = apps.get_model('tests', 'Option')

company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')

if not os.path.exists(company_base_path):
    print(f"Directory NOT found: {company_base_path}")
    sys.exit(1)

print(f"Scanning {company_base_path}...")

for d in os.listdir(company_base_path):
    path = os.path.join(company_base_path, d)
    if os.path.isdir(path):
        slug = slugify(d)
        name = d.replace('-', ' ').replace('_', ' ').title()
        
        category, created = Category.objects.get_or_create(slug=slug, defaults={'name': name, 'description': f'Practice questions for {name}'})
        
        if created:
            print(f"[CREATED] Category: {name} ({slug})")
        else:
            print(f"[EXISTS] Category: {name} ({slug})")
            
        # Check for questions in the folder (assuming JSON format based on typical structure, or just creating category is enough if import is separate)
        # The user just said "section is empty", so creating categories might be enough if questions are already there or if valid empty categories should show up.
        # But dashboard.html shows: {% for category in company_categories %} ...
        # If I fix the category existence, it should show up.
        # If questions are missing, it will show "0 Questions". I'll check that next.

print("\nDone.")
