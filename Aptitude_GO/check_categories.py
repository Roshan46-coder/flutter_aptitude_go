import os
import django
import sys

# Flush stdout to ensure we catch all output
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.apps import apps
Category = apps.get_model('tests', 'Category')
from django.conf import settings
from django.utils.text import slugify

print(f"{'ID':<5} {'Name':<30} {'Slug':<30}")
print("-" * 65)
for c in Category.objects.all():
    print(f"{c.id:<5} {c.name[:28]:<30} {c.slug:<30}")

print("\n--- Checking Computed Company Slugs ---")
company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')
if os.path.exists(company_base_path):
    print(f"Directory found: {company_base_path}")
    for d in os.listdir(company_base_path):
        path = os.path.join(company_base_path, d)
        if os.path.isdir(path):
            print(f"Found Folder: {d} -> Slug: {slugify(d)}")
else:
    print(f"Directory NOT found: {company_base_path}")
