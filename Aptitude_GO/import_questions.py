import os
import json
import csv
import django
import sys
import argparse
import traceback
import re

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category, Question, Option

def clean_text(text):
    if not text:
        return ""
    # Remove surrounding whitespace and any trailing commas
    return text.strip().strip(',').strip()

def get_or_create_category(name):
    slug = name.lower().replace(' ', '-')
    category, _ = Category.objects.get_or_create(
        name=name,
        defaults={'slug': slug}
    )
    return category

def create_question(category, text, difficulty, explanation, options_data):
    # Normalized text for duplicate check (case insensitive, stripped)
    normalized_text = clean_text(text).lower()
    
    # Check if a question with similar text exists in this category
    # (Since we can't search by function easily, we rely on text matching)
    # To be safe, we check exact match first, then maybe strict containment
    
    if Question.objects.filter(text__iexact=clean_text(text), category=category).exists():
        # print(f"Duplicate found: {text[:30]}...")
        return False

    question = Question.objects.create(
        category=category,
        text=clean_text(text),
        difficulty=difficulty,
        explanation=clean_text(explanation)
    )

    for opt in options_data:
        Option.objects.create(
            question=question,
            text=clean_text(opt['text']),
            is_correct=opt['is_correct']
        )
    return True

def import_json(file_path):
    print(f"Reading JSON from {file_path}...")
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error reading JSON file: {e}")
        return

    count_created = 0
    count_dupe = 0
    for item in data:
        cat_name = item.get('category', 'General Aptitude')
        category = get_or_create_category(cat_name)
        
        options = item.get('options', [])
        
        if create_question(
            category, 
            item.get('text'), 
            item.get('difficulty', 'MEDIUM').upper(), 
            item.get('explanation', ''), 
            options
        ):
            count_created += 1
        else:
            count_dupe += 1

    print(f"JSON Import complete. Added: {count_created}, Duplicates Skipped: {count_dupe}")

def import_csv(file_path):
    print(f"Reading CSV from {file_path}...")
    try:
        # Pre-read to detect format manually
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            first_line = f.readline()
        
        delimiter = ','
        if ';' in first_line and 'Option A' in first_line:
            delimiter = ';'
            print("Detected semicolon delimiter.")
        
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            reader = csv.DictReader(f, delimiter=delimiter, restval='')
            
            # Map headers to clean versions
            # Example: "Answer,,,,,,," -> "Answer"
            header_map = {}
            if reader.fieldnames:
                for h in reader.fieldnames:
                    clean_h = clean_text(h)
                    # Also handle if header itself has clutter
                    # If we find "Answer" inside the header, map it
                    if 'Question' in clean_h: header_map[h] = 'Question'
                    elif 'Option A' in clean_h: header_map[h] = 'Option A'
                    elif 'Option B' in clean_h: header_map[h] = 'Option B'
                    elif 'Option C' in clean_h: header_map[h] = 'Option C'
                    elif 'Option D' in clean_h: header_map[h] = 'Option D'
                    elif 'Answer' in clean_h: header_map[h] = 'Answer'
                    else: header_map[h] = clean_h

            is_standard_fmt = 'Question Text' in header_map.values()
            is_dataset_fmt = 'Question' in header_map.values() and 'Option A' in header_map.values()
            
            if not (is_standard_fmt or is_dataset_fmt):
                 # Try to guess based on content if headers failed
                 if 'Question' not in header_map.values():
                     print(f"Unknown CSV format. Headers map: {header_map}")
                     return

            count_created = 0
            count_dupe = 0
            
            for row_idx, row in enumerate(reader):
                # Access data using original keys but mapped logic
                def get_val(target_key):
                    # find the key in row that maps to target_key
                    for k, v in row.items():
                        if header_map.get(k) == target_key:
                            return v
                    return ''

                if is_dataset_fmt:
                    question_text = get_val('Question')
                    if not question_text: continue

                    # Use Category from CSV if available, else default
                    cat_val = get_val('Category')
                    cat_name = cat_val if cat_val else 'General Aptitude'
                    category = get_or_create_category(cat_name)
                    
                    difficulty = get_val('Difficulty') or 'MEDIUM'
                    difficulty = difficulty.upper()
                    
                    explanation = get_val('Explanation') or ''
                    
                    # Clean the answer key
                    raw_ans = get_val('Answer')
                    correct_ans_clean = clean_text(raw_ans)
                    correct_letter = correct_ans_clean.upper()
                    
                    # Handle "Option C" case
                    if len(correct_letter) > 1 and correct_letter.startswith('OPTION'):
                        correct_letter = correct_letter.split()[-1]
                    
                    options_data = []
                    mapping = {'A': 'Option A', 'B': 'Option B', 'C': 'Option C', 'D': 'Option D'}
                    
                    # First pass: collect options and try to find which one is the answer
                    # If correct_letter is A/B/C/D, easy.
                    # If not, try to match text.
                    
                    temp_options = [] # list of (letter, text)
                    for letter, key_name in mapping.items():
                        opt_text = get_val(key_name)
                        clean_opt = clean_text(opt_text)
                        temp_options.append((letter, clean_opt))
                    
                    # Determine which is correct
                    correct_index = -1
                    
                    # 1. Check strict letter match
                    if correct_letter in mapping:
                        # e.g. "B"
                        options_data = []
                        valid_options = True
                        for letter, text in temp_options:
                            if not text:
                                if letter == correct_letter: valid_options = False
                                continue
                            is_correct = (letter == correct_letter)
                            options_data.append({'text': text, 'is_correct': is_correct})
                    else:
                        # 2. Check text match
                        # We compare correct_ans_clean (case insensitive) with options
                        matched = False
                        options_data = []
                        valid_options = True
                        
                        # We need to build the list and mark one as correct
                        for letter, text in temp_options:
                            if not text: continue
                            
                            is_correct = False
                            # Compare text
                            if text.lower() == correct_ans_clean.lower():
                                is_correct = True
                                matched = True
                            
                            options_data.append({'text': text, 'is_correct': is_correct})
                        
                        if not matched:
                            # print(f"Warning: Could not match answer '{raw_ans}' to options for question: {question_text[:30]}...")
                            # Fallback: maybe it's just index? (unlikely if not A-D)
                            pass

                    if not options_data:
                        continue
                        
                else:
                    # Standard Format (implied clean headers usually)
                    cat_name = row.get('Category') or 'General Aptitude'
                    category = get_or_create_category(cat_name)
                    question_text = row.get('Question Text', '')
                    if not question_text: continue

                    difficulty = (row.get('Difficulty') or 'MEDIUM').upper()
                    explanation = row.get('Explanation', '')
                    correct_ans = clean_text(row.get('Correct Answer', ''))

                    options_data = []
                    for i in range(1, 5):
                        opt_text = row.get(f'Option {i}', '')
                        if not opt_text: continue
                        
                        is_correct = False
                        clean_opt = clean_text(opt_text)
                        if correct_ans == clean_opt:
                            is_correct = True
                        elif correct_ans.lower() in [f'option {i}', str(i), chr(64+i).lower()]:
                            is_correct = True
                        options_data.append({'text': clean_opt, 'is_correct': is_correct})

                if create_question(category, question_text, difficulty, explanation, options_data):
                    count_created += 1
                else:
                    count_dupe += 1
            
            print(f"CSV Import complete. Added: {count_created}, Duplicates Skipped: {count_dupe}")

    except Exception as e:
        print(f"Error reading CSV file {file_path}: {e}")
        import traceback
        traceback.print_exc()

def scan_and_import(target_dir=None):
    if target_dir:
        if os.path.isfile(target_dir):
             print(f"Importing single file: {target_dir}")
             if target_dir.endswith('.json'):
                import_json(target_dir)
             elif target_dir.endswith('.csv'):
                import_csv(target_dir)
             return

        scan_dirs = [target_dir]
    else:
        scan_dirs = [os.path.join(os.getcwd(), 'question_bank')]

    for d in scan_dirs:
        if not os.path.exists(d):
            print(f"Directory not found: {d}")
            continue
            
        print(f"Scanning directory: {d}")
        files = os.listdir(d)
        for filename in files:
            file_path = os.path.join(d, filename)
            if filename.endswith('.json'):
                import_json(file_path)
            elif filename.endswith('.csv'):
                import_csv(file_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Import questions from JSON or CSV.')
    parser.add_argument('directory', nargs='?', help='Directory or file path to scan')
    args = parser.parse_args()
    
    scan_and_import(args.directory)
