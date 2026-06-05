import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from gamification.models import StoreItem

print(f"\nTotal store items: {StoreItem.objects.count()}\n")
for item in StoreItem.objects.all():
    print(f"✓ {item.name} - {item.cost} coins - {item.item_type}")
    print(f"  {item.description}\n")
