import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from tests.models import Category, Question

def map_questions():
    # Targets
    tech_cat, _ = Category.objects.get_or_create(slug='technical-aptitude', defaults={'name': 'Technical Aptitude'})
    game_cat, _ = Category.objects.get_or_create(slug='game-based-aptitude', defaults={'name': 'Game-based Aptitude'})
    data_cat, _ = Category.objects.get_or_create(slug='data-driven-aptitude', defaults={'name': 'Data-driven Aptitude'})
    beh_cat, _ = Category.objects.get_or_create(slug='behavioral-aptitude', defaults={'name': 'Behavioral Aptitude'})

    # Mapping Logic
    # 1. Technical Aptitude: Fetch from Programming or Computer Fundamentals
    prog_questions = Question.objects.filter(category__slug='programming-aptitude')[:50]
    for q in prog_questions:
        q.category = tech_cat
        q.save()
    print(f"Mapped {prog_questions.count()} questions to Technical Aptitude")

    # 2. Game-based Aptitude: Fetch from Cognitive or Memory
    cog_questions = Question.objects.filter(category__slug='cognitive-ability')[:50]
    for q in cog_questions:
        q.category = game_cat
        q.save()
    print(f"Mapped {cog_questions.count()} questions to Game-based Aptitude")

    # 3. Data-driven Aptitude: Fetch from Quantitative
    quant_questions = Question.objects.filter(category__slug='quantitative-aptitude')[:50]
    for q in quant_questions:
        q.category = data_cat
        q.save()
    print(f"Mapped {quant_questions.count()} questions to Data-driven Aptitude")

    # 4. Behavioral Aptitude: Create samples if empty
    if beh_cat.questions.count() == 0:
        samples = [
            "How do you handle conflict in a team environment?",
            "Describe a time you failed and how you handled it.",
            "Tell us about a time you showed leadership.",
            "How do you prioritize multiple deadlines?",
            "What do you do if you disagree with your manager?"
        ]
        from tests.models import Option
        for text in samples:
            q = Question.objects.create(category=beh_cat, text=text, difficulty='MEDIUM')
            Option.objects.create(question=q, text="Answer with professionalism and logic.", is_correct=True)
            Option.objects.create(question=q, text="Avoid the situation.", is_correct=False)
            Option.objects.create(question=q, text="Shift blame to others.", is_correct=False)
            Option.objects.create(question=q, text="Wait for someone else to solve it.", is_correct=False)
        print("Created 5 sample behavioral questions")

if __name__ == "__main__":
    map_questions()
