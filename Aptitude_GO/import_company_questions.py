import os
import django
import sys
import re

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

total_imported = 0
total_skipped = 0

for company_dir in os.listdir(company_base_path):
    company_path = os.path.join(company_base_path, company_dir)
    if not os.path.isdir(company_path):
        continue

    slug = slugify(company_dir)
    # Auto-create category if missing
    category, cat_created = Category.objects.get_or_create(
        slug=slug, 
        defaults={'name': company_dir}
    )
    if cat_created:
        print(f"Created new Category: {category.name}")

    print(f"Processing {company_dir}...")
    
    for q_dir in os.listdir(company_path):
        q_path = os.path.join(company_path, q_dir)
        if not os.path.isdir(q_path):
            continue
            
        txt_path = os.path.join(q_path, 'Problem Statement.txt')
        if not os.path.exists(txt_path):
            print(f"  [SKIP] No 'Problem Statement.txt' in {q_dir}")
            continue

        with open(txt_path, 'r', encoding='utf-8', errors='ignore') as f:
            text = f.read()
            
        # Determine Question Type & Time Limit
        java_path = os.path.join(q_path, 'Main.java')
        explanation = ""
        
        q_type = 'LOGICAL'  # default fallback
        t_limit = 300       # 5 minutes
        
        if os.path.exists(java_path):
            # It's a Coding problem
            with open(java_path, 'r', encoding='utf-8', errors='ignore') as f:
                code = f.read()
                explanation = f"Reference Solution:\n\n```java\n{code}\n```"
            q_type = 'CODING'
            t_limit = 900 # 15 mins for coding
        else:
            # Let's check if there are options like A), B), C), D) or a), b), c) or 1., 2.
            # Convert to lower to find option indicators easily
            text_lower = text.lower()
            if 'a)' in text_lower or '(a)' in text_lower or 'option a' in text_lower or '\na.' in text_lower:
                q_type = 'MCQ'
                t_limit = 60 # 1 minute for MCQ

        # Check for absolute duplicate by exact text match
        if Question.objects.filter(category=category, text=text).exists():
            total_skipped += 1
            continue

        # Create the Question
        question = Question.objects.create(
            category=category,
            text=text,
            explanation=explanation,
            difficulty='MEDIUM',
            question_type=q_type,
            time_limit=t_limit
        )

        # Basic Option Generation for MCQs if needed
        if q_type == 'MCQ':
            # We don't have structured answers in these raw txt files, 
            # so we generate generic placeholder options for them to work in the test interface.
            # (Users typically type answer or assume generic A B C D)
            Option.objects.create(question=question, text='Option A')
            Option.objects.create(question=question, text='Option B')
            Option.objects.create(question=question, text='Option C')
            Option.objects.create(question=question, text='Option D', is_correct=True) # Fake correct answer

        print(f"  [IMPORTED] {q_dir} ({q_type})")
        total_imported += 1

print(f"\nTotal Questions Imported: {total_imported}")
print(f"Total Skipped (Duplicates): {total_skipped}")
print("Done.")
