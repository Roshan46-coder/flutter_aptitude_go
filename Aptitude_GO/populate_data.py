import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category, Question, Option
from gamification.models import StoreItem

def populate():
    print("Populating data...")
    
    # Category
    cat, created = Category.objects.get_or_create(name="General Aptitude", slug="general-aptitude")
    if created:
        print("Created Category: General Aptitude")
    
    # Questions
    if not Question.objects.filter(category=cat).exists():
        for i in range(1, 6):
            q = Question.objects.create(category=cat, text=f"What is {i} + {i}?", difficulty='EASY')
            Option.objects.create(question=q, text=str(i+i), is_correct=True)
            Option.objects.create(question=q, text=str(i+i+1), is_correct=False)
            Option.objects.create(question=q, text=str(i*i+10), is_correct=False)
        print("Created 5 Questions")
    
    # Store Items
    if not StoreItem.objects.filter(item_type='LIFE_REFILL').exists():
        StoreItem.objects.create(
            name="Life Refill", 
            description="Refill your lives to 5 instantly.", 
            cost=50, 
            item_type='LIFE_REFILL'
        )
        print("Created Life Refill Item")
        
    if not StoreItem.objects.filter(name="Golden Frame").exists():
        StoreItem.objects.create(
            name="Golden Frame",
            description="A shiny golden frame for your avatar.",
            cost=200,
            item_type='FRAME'
        )
        print("Created Golden Frame Item")

    print("Data population complete.")

if __name__ == "__main__":
    populate()
