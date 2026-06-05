import json
import csv
import os
from django.core.management.base import BaseCommand, CommandError
from django.utils.text import slugify
from tests.models import Category, Question, Option

class Command(BaseCommand):
    help = 'Import questions from a JSON or CSV file'

    def add_arguments(self, parser):
        parser.add_argument('file_path', type=str, help='Path to the file (JSON or CSV)')

    def handle(self, *args, **options):
        file_path = options['file_path']
        _, ext = os.path.splitext(file_path)
        ext = ext.lower()

        if not os.path.exists(file_path):
            raise CommandError(f'File "{file_path}" does not exist')

        data = []
        
        # JSON PARSING
        if ext == '.json':
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
            except json.JSONDecodeError:
                raise CommandError('Invalid JSON file')
        
        # CSV PARSING
        elif ext == '.csv':
            try:
                with open(file_path, 'r', encoding='utf-8-sig') as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        # Map CSV columns to our structure
                        # Expected headers: Category, Question, Option A, Option B, Option C, Option D, Correct Answer, Explanation, Difficulty
                        
                        # Flexible header matching
                        row_lower = {k.lower().strip(): v for k, v in row.items() if k}
                        
                        category = row_lower.get('category', 'General')
                        text = row_lower.get('question')
                        
                        if not text: continue

                        # Collect options
                        opts = []
                        # Look for option columns
                        for key, val in row_lower.items():
                            if key.startswith('option') and val and val.strip():
                                opts.append({'text': val.strip(), 'is_correct': False})
                        
                        # Mark correct answer
                        correct_val = row_lower.get('correct answer', '').strip()
                        correct_found = False
                        
                        # Case 1: Correct Answer is "A", "B" etc.
                        if len(correct_val) == 1 and correct_val.isalpha():
                            idx = ord(correct_val.upper()) - 65 # A=0, B=1
                            if 0 <= idx < len(opts):
                                opts[idx]['is_correct'] = True
                                correct_found = True
                        
                        # Case 2: Correct Answer is the full text
                        if not correct_found:
                            for opt in opts:
                                if opt['text'].lower() == correct_val.lower():
                                    opt['is_correct'] = True
                                    correct_found = True
                                    break
                        
                        # Case 3: Default to first if not found (fallback)
                        if not correct_found and opts:
                            opts[0]['is_correct'] = True

                        data.append({
                            'category': category,
                            'text': text,
                            'difficulty': row_lower.get('difficulty', 'MEDIUM'),
                            'explanation': row_lower.get('explanation', ''),
                            'options': opts
                        })
            except Exception as e:
                raise CommandError(f'Error reading CSV: {str(e)}')
        
        else:
            raise CommandError('Unsupported file extension. Use .json or .csv')

        if not isinstance(data, list):
            raise CommandError('Data root must be a list of questions')

        count_created = 0
        count_skipped = 0

        for item in data:
            category_name = item.get('category')
            text = item.get('text')
            explanation = item.get('explanation', '')
            difficulty = item.get('difficulty', 'MEDIUM').upper()
            if difficulty not in ['EASY', 'MEDIUM', 'HARD']:
                difficulty = 'MEDIUM'
                
            opts = item.get('options', [])

            if not category_name or not text or not opts:
                self.stdout.write(self.style.WARNING(f'Skipping invalid item: {text[:30]}...'))
                continue

            # Check if question exists (simple duplicate check)
            if Question.objects.filter(text=text).exists():
                count_skipped += 1
                continue

            # Get or Create Category
            category_slug = slugify(category_name)
            category, _ = Category.objects.get_or_create(
                slug=category_slug,
                defaults={'name': category_name}
            )

            # Create Question
            question = Question.objects.create(
                category=category,
                text=text,
                explanation=explanation,
                difficulty=difficulty
            )

            # Create Options
            for opt in opts:
                Option.objects.create(
                    question=question,
                    text=opt.get('text'),
                    is_correct=opt.get('is_correct', False)
                )

            count_created += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully imported {count_created} questions. Skipped {count_skipped} duplicates.'))
