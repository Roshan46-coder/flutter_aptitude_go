import os
import django
import shutil

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()
from tests.models import Question
Question.objects.filter(category__name='Cognitive Ability').delete()

img_dir = r"d:\aptitude preparation plaform\question_bank\cognitive_ability\images"
if os.path.exists(img_dir):
    shutil.rmtree(img_dir)
os.makedirs(img_dir)

csv_path = r"d:\aptitude preparation plaform\question_bank\cognitive_ability\cognitive_ability.csv"
if os.path.exists(csv_path):
    os.remove(csv_path)
print("Wiped old SVGs, DB rows, and CSV.")
