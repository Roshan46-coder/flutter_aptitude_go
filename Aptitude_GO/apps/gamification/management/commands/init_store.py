from django.core.management.base import BaseCommand
from gamification.models import StoreItem

class Command(BaseCommand):
    help = 'Initialize default store items'

    def handle(self, *args, **kwargs):
        items = [
            {
                'name': 'Life Refill',
                'description': 'Instantly refill your lives to 5. Get back in the game!',
                'cost': 100,
                'item_type': 'LIFE_REFILL',
                'min_level_required': 1
            },
            {
                'name': 'Golden Frame',
                'description': 'A shiny golden border for your profile picture.',
                'cost': 500,
                'item_type': 'FRAME',
                'min_level_required': 5
            },
            {
                'name': 'Pro Avatar',
                'description': 'Unlock the exclusive Pro avatar to show off your rank.',
                'cost': 1000,
                'item_type': 'AVATAR',
                'min_level_required': 10
            },
            {
                'name': 'Dark Theme Pack',
                'description': 'Unlock a special dark theme background.',
                'cost': 200,
                'item_type': 'THEME',
                'min_level_required': 2
            }
        ]

        created_count = 0
        for item_data in items:
            item, created = StoreItem.objects.get_or_create(
                name=item_data['name'],
                defaults=item_data
            )
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f'Created item: {item.name}'))
            else:
                self.stdout.write(f'Item already exists: {item.name}')

        self.stdout.write(self.style.SUCCESS(f'Successfully initialized store with {created_count} new items.'))
