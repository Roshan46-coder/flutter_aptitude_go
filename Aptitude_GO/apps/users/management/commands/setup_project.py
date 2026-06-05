from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.contrib.auth import get_user_model
from apps.gamification.models import StoreItem
import subprocess
import os
import sys

class Command(BaseCommand):
    help = 'Sets up the project by running migrations, creating default data, superuser, and importing questions.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('--- Starting Project Setup ---'))

        # 1. Run Migrations
        self.stdout.write(self.style.WARNING('1. Running Database Migrations...'))
        try:
            call_command('migrate')
            self.stdout.write(self.style.SUCCESS('Migrations completed successfully.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Migration failed: {e}'))
            return

        # 2. Setup Superuser
        self.stdout.write(self.style.WARNING('\n2. Setting up Admin User...'))
        User = get_user_model()
        if not User.objects.filter(username='admin').exists():
            try:
                User.objects.create_superuser('admin', 'admin@example.com', 'admin')
                self.stdout.write(self.style.SUCCESS('Superuser created (admin/admin).'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Failed to create superuser: {e}'))
        else:
            self.stdout.write(self.style.SUCCESS('Superuser already exists. Skipping.'))

        # 3. Create Default Store Items
        self.stdout.write(self.style.WARNING('\n3. Creating Default Store Items...'))
        if StoreItem.objects.count() == 0:
            try:
                StoreItem.objects.create(name='Ninja Avatar', description='Cool Ninja profile picture', cost=200, item_type='AVATAR')
                StoreItem.objects.create(name='Gold Frame', description='Shiny gold profile border', cost=150, item_type='FRAME')
                StoreItem.objects.create(name='Extra Life', description='Refill one life instantly', cost=50, item_type='LIFE_REFILL')
                self.stdout.write(self.style.SUCCESS('Default store items generated.'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Failed to create store items: {e}'))
        else:
            self.stdout.write(self.style.SUCCESS(f'{StoreItem.objects.count()} store items already exist. Skipping.'))

        # 4. Execute Question Import Script
        self.stdout.write(self.style.WARNING('\n4. Importing Questions from CSV/JSON...'))
        script_path = os.path.join(os.getcwd(), 'import_questions.py')
        questions_dir = os.path.join(os.getcwd(), 'question_bank')
        
        if os.path.exists(script_path):
            try:
                self.stdout.write(f'Executing {script_path} for directory {questions_dir}...')
                # Use subprocess to run the import script in the same python environment
                result = subprocess.run(
                    [sys.executable, script_path, questions_dir], 
                    capture_output=True, 
                    text=True
                )
                if result.returncode == 0:
                     self.stdout.write(self.style.SUCCESS('Question import completed successfully.'))
                     # We can print standard output if we want verbose details:
                     # self.stdout.write(result.stdout)
                else:
                     self.stdout.write(self.style.ERROR(f'Question import script returned errors:\n{result.stderr}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Failed to run import script: {e}'))
        else:
            self.stdout.write(self.style.ERROR(f"Could not find import script at {script_path}"))

        self.stdout.write(self.style.SUCCESS('\n--- Setup Complete! Run `python manage.py runserver` to start ---'))
