import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category

def add_new_categories():
    """Add new aptitude categories to the database"""
    
    categories_data = [
        {
            'name': 'Technical Aptitude',
            'slug': 'technical-aptitude',
            'description': 'Assess your technical problem-solving skills, coding logic, and software development concepts.'
        },
        {
            'name': 'Game-based Aptitude',
            'slug': 'game-based-aptitude',
            'description': 'Interactive challenges that test your strategic thinking, pattern recognition, and quick decision-making.'
        },
        {
            'name': 'Data-driven Aptitude',
            'slug': 'data-driven-aptitude',
            'description': 'Evaluate your ability to analyze data, interpret charts, and make data-informed decisions.'
        },
        {
            'name': 'Behavioral Aptitude',
            'slug': 'behavioral-aptitude',
            'description': 'Measure your soft skills, situational judgment, and workplace behavior competencies.'
        }
    ]
    
    for cat_data in categories_data:
        cat, created = Category.objects.get_or_create(
            slug=cat_data['slug'],
            defaults={
                'name': cat_data['name'],
                'description': cat_data['description']
            }
        )
        if created:
            print(f"✓ Created Category: {cat.name}")
        else:
            print(f"→ Category already exists: {cat.name}")
    
    print("\n✓ All categories processed successfully!")
    print(f"\nTotal categories in database: {Category.objects.count()}")
    
    # List all categories
    print("\nAll Categories:")
    for cat in Category.objects.all():
        print(f"  - {cat.name} ({cat.slug}) - {cat.questions.count()} questions")

if __name__ == '__main__':
    add_new_categories()
