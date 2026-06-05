
import os
import django
import sys

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category

# New descriptions
descriptions = {
    "General Aptitude": "Comprehensive assessment covering all aptitude areas including logic, math, and verbal skills.",
    "Verbal Ability": "Master English grammar, vocabulary, and comprehension.",
    "Quantitative Aptitude": "Solve numerical problems and data interpretation challenges.",
    "Logical Reasoning": "Sharpen your analytical thinking and puzzle-solving skills."
}

print("Updating Category Descriptions (Round 2)...")

for name, desc in descriptions.items():
    try:
        category = Category.objects.get(name=name)
        category.description = desc
        category.save()
        print(f"Updated description for: {name}")
    except Category.DoesNotExist:
        print(f"Category not found: {name}")

print("\nVerifying updates:")
for cat in Category.objects.all():
    print(f"- {cat.name}: {cat.description}")
