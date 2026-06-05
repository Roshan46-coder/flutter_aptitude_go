import os
from django.core.management.base import BaseCommand, CommandError
from django.utils.text import slugify
from tests.models import Category, Question, Option


class Command(BaseCommand):
    help = 'Import programming coding problems from a directory structure: Company -> Que folders -> Problem Statement.txt + solution code'

    def add_arguments(self, parser):
        parser.add_argument('source_dir', type=str, help='Root directory containing company folders (e.g. Accenture, TCS, etc.)')

    def handle(self, *args, **options):
        source_dir = options['source_dir']

        if not os.path.isdir(source_dir):
            raise CommandError(f'Directory "{source_dir}" does not exist')

        count_created = 0
        count_skipped = 0
        errors = []

        # Walk each company folder
        for company_name in sorted(os.listdir(source_dir)):
            company_path = os.path.join(source_dir, company_name)
            if not os.path.isdir(company_path):
                continue

            self.stdout.write(f'\n--- Processing company: {company_name} ---')

            # Get or create category for this company
            category_slug = slugify(company_name)
            category, created = Category.objects.get_or_create(
                slug=category_slug,
                defaults={
                    'name': company_name,
                    'description': f'Programming questions from {company_name} interviews'
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'  Created category: {company_name}'))

            # Walk each question folder
            for que_folder in sorted(os.listdir(company_path)):
                que_path = os.path.join(company_path, que_folder)
                if not os.path.isdir(que_path):
                    continue

                # Read problem statement
                problem_file = os.path.join(que_path, 'Problem Statement.txt')
                if not os.path.exists(problem_file):
                    self.stdout.write(self.style.WARNING(f'  Skipping {que_folder}: No "Problem Statement.txt" found'))
                    count_skipped += 1
                    continue

                try:
                    with open(problem_file, 'r', encoding='utf-8', errors='replace') as f:
                        problem_text = f.read().strip()
                except Exception as e:
                    errors.append(f'{company_name}/{que_folder}: {e}')
                    count_skipped += 1
                    continue

                if not problem_text:
                    self.stdout.write(self.style.WARNING(f'  Skipping {que_folder}: Empty problem statement'))
                    count_skipped += 1
                    continue

                # Read solution code (look for .java, .c, .py, .cpp files)
                solution_text = ''
                for fname in os.listdir(que_path):
                    if fname.startswith('~$'):
                        continue  # skip temp files
                    ext = os.path.splitext(fname)[1].lower()
                    if ext in ['.java', '.c', '.py', '.cpp', '.cs', '.js']:
                        sol_path = os.path.join(que_path, fname)
                        try:
                            with open(sol_path, 'r', encoding='utf-8', errors='replace') as f:
                                code = f.read().strip()
                            lang = {'.java': 'java', '.c': 'c', '.py': 'python', '.cpp': 'cpp', '.cs': 'csharp', '.js': 'javascript'}.get(ext, '')
                            solution_text += f'\n\n--- Solution ({fname}) ---\n```{lang}\n{code}\n```'
                        except Exception:
                            pass

                # Build the question title from folder name
                title = que_folder.strip()
                # Full question text: title + problem
                full_text = f'[{company_name}] {title}\n\n{problem_text}'

                # Check for duplicates
                if Question.objects.filter(text=full_text).exists():
                    count_skipped += 1
                    continue

                # Create question
                question = Question.objects.create(
                    category=category,
                    text=full_text,
                    explanation=solution_text.strip() if solution_text else '',
                    difficulty='MEDIUM'
                )

                # Create a placeholder option (since model requires options for tests)
                # For coding problems, we create a single "See Explanation" option
                Option.objects.create(
                    question=question,
                    text='See solution in explanation',
                    is_correct=True
                )

                count_created += 1
                self.stdout.write(f'  Imported: {title}')

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(
            f'Import complete! Created {count_created} questions. Skipped {count_skipped}.'
        ))

        if errors:
            self.stdout.write(self.style.WARNING(f'\nErrors encountered:'))
            for e in errors:
                self.stdout.write(self.style.WARNING(f'  - {e}'))
