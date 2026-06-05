import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
sys.path.append(r'd:\aptitude preparation plaform')
django.setup()

from users.models import CustomUser

users = CustomUser.objects.all()
print('--- USERS ---')
for u in users:
    print(f"User: {u.username}, interested_field: '{u.interested_field}'")
