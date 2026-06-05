import os
import django
import sys
import csv
import re
import shutil

# Flush stdout to ensure we catch all output
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from django.apps import apps
from django.utils.text import slugify

Category = apps.get_model('tests', 'Category')
Question = apps.get_model('tests', 'Question')
Option = apps.get_model('tests', 'Option')

# Define file mappings and column indices based on inspection
# Assuming standard format: Question, A, B, C, D, Answer
# If headers exist, we use DictReader. If not, we use indexes.
# Let's assume headers based on file names "clean_..." usually implies headers.
# But I will check the output of the previous command first.
# Writing a robust script that can handle both.

FILES = [
    {'filename': 'logical_reasoning/logical_reasoning.csv', 'name': 'Logical Reasoning', 'slug': 'logical-reasoning'},
    {'filename': 'verbal_ability/verbal_ability.csv', 'name': 'Verbal Ability', 'slug': 'verbal-ability'},
    {'filename': 'quantitative_aptitude/quantitative_aptitude.csv', 'name': 'Quantitative Aptitude', 'slug': 'quantitative-aptitude'},
    {'filename': 'programming_aptitude/programming_aptitude.csv', 'name': 'Programming Aptitude', 'slug': 'programming-aptitude'},
    {'filename': 'computer_fundamentals/computer_fundamentals.csv', 'name': 'Computer Fundamentals', 'slug': 'computer-fundamentals'},
    {'filename': 'debugging_and_code_logic/debugging_and_code_logic.csv', 'name': 'Debugging and Code Logic', 'slug': 'debugging-and-code-logic'},
    {'filename': 'cognitive_ability/cognitive_ability.csv', 'name': 'Cognitive Ability', 'slug': 'cognitive-ability'},
    {'filename': 'memory_and_attention/memory_and_attention.csv', 'name': 'Memory and Attention', 'slug': 'memory-and-attention'},
    {'filename': 'clean_general_aptitude_dataset/clean_general_aptitude_dataset.csv', 'name': 'General Aptitude', 'slug': 'general-aptitude'},
]

def clean_text(text):
    return text.strip() if text else ""

def import_csv(file_info):
    csv_path = os.path.join('question_bank', file_info['filename'])
    if not os.path.exists(csv_path):
        print(f"File not found: {csv_path}")
        return

    print(f"Importing {file_info['name']} from {file_info['filename']}...")
    
    category, _ = Category.objects.get_or_create(
        slug=file_info['slug'],
        defaults={'name': file_info['name'], 'description': f"Practice {file_info['name']} questions."}
    )

    with open(csv_path, 'r', encoding='utf-8', errors='ignore') as f:
        # Check first line to see if it's a header
        first_line = f.readline()
        f.seek(0)
        
        has_header = "Question" in first_line and "Option" in first_line
        
        reader = csv.reader(f, delimiter=';')
        
        if has_header:
            next(reader) # Skip header

        count = 0
        for row in reader:
            if len(row) < 6: # Need at least Q, A, B, C, D, Ans
                continue
                
            question_text = clean_text(row[0])
            
            # Auto-handle images 
            images = re.findall(r"src=['\"]images/(.*?)['\"]", question_text)
            for img_file in images:
                src_img_path = os.path.join(os.path.dirname(csv_path), 'images', img_file)
                dest_dir = os.path.join(django.conf.settings.MEDIA_ROOT, 'question_images')
                os.makedirs(dest_dir, exist_ok=True)
                dest_path = os.path.join(dest_dir, img_file)
                
                if os.path.exists(src_img_path):
                    shutil.copy2(src_img_path, dest_path)
                
                media_url = getattr(django.conf.settings, 'MEDIA_URL', '/media/')
                question_text = question_text.replace(f"images/{img_file}", f"{media_url}question_images/{img_file}")

            option_a = clean_text(row[1])
            option_b = clean_text(row[2])
            option_c = clean_text(row[3])
            option_d = clean_text(row[4])
            # The answer column might contain trailing commas like "B,,,,,,,,"
            raw_answer = row[5]
            if ',' in raw_answer:
                answer = clean_text(raw_answer.split(',')[0])
            else:
                answer = clean_text(raw_answer)

            if not question_text:
                continue
                
            # Skip if only header-like text (e.g. repetition in file)
            if question_text.lower() == "question":
                continue

            if not question_text or not answer:
                continue

            # Check if question exists
            if Question.objects.filter(category=category, text=question_text).exists():
                continue

            question = Question.objects.create(
                category=category,
                text=question_text,
                difficulty='MEDIUM'
            )

            # Map Answer to Option
            # Normalize answer: 'Option A' -> 'A', 'a' -> 'A'
            normalized_ans = answer.upper().replace('OPTION', '').strip()
            
            options_data = [
                ('A', option_a),
                ('B', option_b),
                ('C', option_c),
                ('D', option_d)
            ]

            correct_found = False
            for label, text in options_data:
                is_correct = False
                if label == normalized_ans:
                    is_correct = True
                    correct_found = True
                elif text == answer: # Full text match
                    is_correct = True
                    correct_found = True
                
                Option.objects.create(question=question, text=text, is_correct=is_correct)

            # If no correct option marked by label, try fuzzy match or default to none (log it)
            if not correct_found:
                # Fallback: maybe answer is an index?
                # For now, just logging.
                pass
                
            count += 1
            if count % 50 == 0:
                print(f"  Imported {count} questions...")

    print(f"Finished {file_info['name']}: {count} questions imported.\n")

for f in FILES:
    import_csv(f)
