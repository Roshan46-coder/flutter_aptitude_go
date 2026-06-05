from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from apps.multiplayer.models import Match, MatchPlayer
import json
import random
from apps.tests.models import Category, Question

@login_required
def topic_select(request):
    """View to select a topic for multiplayer."""
    from django.utils.text import slugify
    import os
    from django.conf import settings

    # Dynamically find company slugs from the question_bank folder
    company_base_path = os.path.join(settings.BASE_DIR, 'question_bank', 'company_level_question')
    company_slugs = []
    
    if os.path.exists(company_base_path):
        company_slugs = [slugify(d) for d in os.listdir(company_base_path) 
                        if os.path.isdir(os.path.join(company_base_path, d))]
    
    if not company_slugs:
        company_slugs = ['accenture', 'cognizant', 'tata-elxsi', 'tcs', 'tcs-ninja', 'wipro-elite-nlth']

    # We only want general categories for VS Online, so we exclude company ones completely
    general_categories = Category.objects.exclude(slug__in=company_slugs)
    
    # Priority sorting based on user's interests
    user_interests = request.user.interested_field.lower() if hasattr(request.user, 'interested_field') and request.user.interested_field else ""
    
    priority_slugs = []
    if any(kw in user_interests for kw in ['software', 'it', 'tech', 'data', 'developer', 'computer', 'engineer']):
        priority_slugs.extend(['computer-fundamentals', 'programming-aptitude', 'debugging-and-code-logic', 'cognitive-ability'])
    if any(kw in user_interests for kw in ['management', 'mba', 'banking', 'business', 'finance', 'marketing', 'abroad']):
        priority_slugs.extend(['quantitative-aptitude', 'logical-reasoning', 'verbal-ability', 'memory-and-attention', 'cognitive-ability'])
    if any(kw in user_interests for kw in ['civil', 'defense', 'railway', 'general', 'government']):
        priority_slugs.extend(['general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 'verbal-ability', 'memory-and-attention'])

    unique_priority_slugs = []
    for slug in priority_slugs:
        if slug not in unique_priority_slugs:
            unique_priority_slugs.append(slug)
            
    sorted_general = list(general_categories)
    def sort_key(category):
        try:
            return unique_priority_slugs.index(category.slug)
        except ValueError:
            return len(unique_priority_slugs)
            
    sorted_general.sort(key=sort_key)
    
    user = request.user
    context = {
        'categories': sorted_general,
        'coins': user.coins,
        'lives': user.lives,
    }
    return render(request, 'multiplayer/topic_select.html', context)

@login_required
def matchmaking(request, topic):
    """View that shows the roulette animation and handles WS connection."""
    user = request.user
    
    if user.coins < 20 or user.lives < 1:
        messages.error(request, 'Insufficient coins (20) or lives (1) required to play VS Mode.')
        return redirect('multiplayer:topic_select')

    context = {
        'topic': topic,
        'coins': user.coins,
        'lives': user.lives,
    }
    return render(request, 'multiplayer/matchmaking.html', context)

@login_required
def game_room(request, match_id):
    """View for the actual 1v1 test interface."""
    match = get_object_or_404(Match, id=match_id)
    
    # Verify user is in this match
    if not MatchPlayer.objects.filter(match=match, user=request.user).exists():
        messages.error(request, "You are not a participant in this match.")
        return redirect('multiplayer:topic_select')
        
    if match.status == 'completed':
        return redirect('multiplayer:results', match_id=match.id)
        
    # Get opponent details for the UI
    opponent_entry = MatchPlayer.objects.filter(match=match).exclude(user=request.user).first()
    opponent = opponent_entry.user if opponent_entry else None
    
    # Pre-load Questions for the Game (5 random match questions)
    # The 'topic' on the Match model should ideally map to Category slug or name
    # Using topic fallback if exactly matched, otherwise any 10 questions
    category_slug = match.topic
    questions_query = Question.objects.filter(category__slug=category_slug)
    
    if not questions_query.exists():
        # Fallback to any questions if no category matches the slug exactly
        questions_query = Question.objects.all()
        
    all_questions = list(questions_query.prefetch_related('options'))
    
    # Select 10 questions for multiplayer
    selected_questions = random.sample(all_questions, min(len(all_questions), 10))
    
    # We pass the pure django objects so the template can iterate natively 
    # (questions.options.all, question.is_coding_problem)
        
    context = {
        'match': match,
        'opponent': opponent,
        'questions': selected_questions
    }
    return render(request, 'multiplayer/vs_interface.html', context)

@login_required
def results(request, match_id):
    """View to display match results and coin distribution."""
    match = get_object_or_404(Match, id=match_id)
    
    players = MatchPlayer.objects.filter(match=match).select_related('user')
    me = next((p for p in players if p.user == request.user), None)
    opponent = next((p for p in players if p.user != request.user), None)
    
    if not me:
        messages.error(request, "You are not a participant in this match.")
        return redirect('multiplayer:topic_select')
        
    context = {
        'match': match,
        'my_player': me,
        'opponent_player': opponent,
        'opponent': opponent.user if opponent else None,
        'my_score': me.score if me else 0,
        'opponent_score': opponent.score if opponent else 0,
        'is_winner': me.is_winner if me else False,
        'is_tie': match.winner is None and match.status == 'completed'
    }
    return render(request, 'multiplayer/results.html', context)
