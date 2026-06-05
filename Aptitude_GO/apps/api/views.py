import json
import os
import io
import random
from django.shortcuts import get_object_or_404
from django.http import JsonResponse, HttpResponse, HttpResponseForbidden, Http404
from django.contrib.auth import login, logout, authenticate
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.db.models import Avg, Count, F, Q
from django.conf import settings
import fitz # PyMuPDF

from apps.users.models import CustomUser, Conversation, Message, Certificate, SiteSetting
from apps.tests.models import Category, Question, TestAttempt, Option
from gamification.models import StoreItem, UserItem, MonthlySpin
from events.models import Event, EventQuestion, EventRegistration

# ── HELPERS ─────────────────────────────────────────────────────────────────
def check_auth(request):
    """Helper to check if user is authenticated. Returns None or JsonResponse."""
    if not request.user.is_authenticated:
        return JsonResponse({'error': 'Unauthenticated'}, status=401)
    return None

def serialize_user(user):
    return {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'level': user.level,
        'exp': user.exp,
        'coins': user.coins,
        'lives': user.lives,
        'is_company': user.is_company,
        'current_status': user.current_status,
        'interested_field': user.interested_field,
        'organization': user.organization,
        'hiring_focus': user.hiring_focus,
        'linkedin_url': user.linkedin_url,
        'github_url': user.github_url,
        'avatar_url': user.avatar.url if user.avatar else None,
    }

# ── AUTHENTICATION & ONBOARDING APIs ────────────────────────────────────────
@csrf_exempt
def login_api(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    
    try:
        data = json.loads(request.body)
        username = data.get('username')
        password = data.get('password')
    except Exception:
        username = request.POST.get('username')
        password = request.POST.get('password')

    if not username or not password:
        return JsonResponse({'error': 'Username and password required'}, status=400)

    user = authenticate(request, username=username, password=password)
    if user is not None:
        if not user.is_active:
            return JsonResponse({'error': 'Account is inactive. Please verify your email first.'}, status=403)
        login(request, user)
        return JsonResponse({
            'success': True,
            'message': 'Logged in successfully',
            'user': serialize_user(user)
        })
    else:
        return JsonResponse({'error': 'Invalid username or password'}, status=400)

@csrf_exempt
def register_api(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    try:
        data = json.loads(request.body)
    except Exception:
        data = request.POST

    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    first_name = data.get('first_name', '')
    last_name = data.get('last_name', '')
    
    is_company = data.get('is_company', False)
    hiring_focus = data.get('hiring_focus', '')
    current_status = data.get('current_status', '')
    interested_field = data.get('interested_field', '')
    organization = data.get('organization', '')

    if not username or not email or not password:
        return JsonResponse({'error': 'Username, email and password are required'}, status=400)

    if CustomUser.objects.filter(username=username).exists():
        return JsonResponse({'error': 'Username already exists'}, status=400)
    
    if CustomUser.objects.filter(email=email).exists():
        return JsonResponse({'error': 'Email already exists'}, status=400)

    try:
        user = CustomUser.objects.create_user(
            username=username,
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name,
            is_company=is_company,
            hiring_focus=hiring_focus if is_company else '',
            current_status='' if is_company else current_status,
            interested_field='' if is_company else interested_field,
            organization=organization,
            is_active=False # Inactive until verified
        )
        
        # Send Verification Email (reusing helper from users views)
        from users.views import _send_verification_email
        origin = request.META.get('HTTP_ORIGIN') or request.META.get('HTTP_REFERER')
        _send_verification_email(request, user, return_url=origin)

        return JsonResponse({
            'success': True,
            'message': 'Registration successful. Please check your email to verify your account.'
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def resend_verification_api(request):
    """Resend the email verification link to an unverified account."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)
    try:
        data = json.loads(request.body)
    except Exception:
        data = request.POST
    email = data.get('email', '').strip()
    if not email:
        return JsonResponse({'error': 'Email is required'}, status=400)
    try:
        user = CustomUser.objects.get(email__iexact=email)
    except CustomUser.DoesNotExist:
        # Don't reveal whether the email exists
        return JsonResponse({'success': True, 'message': 'If that email is registered, a verification link has been sent.'})
    if user.is_active:
        return JsonResponse({'error': 'This account is already verified. You can log in.'}, status=400)
    from users.views import _send_verification_email
    origin = request.META.get('HTTP_ORIGIN') or request.META.get('HTTP_REFERER')
    _send_verification_email(request, user, return_url=origin)
    return JsonResponse({'success': True, 'message': 'Verification email sent. Please check your inbox.'})

@csrf_exempt
def logout_api(request):
    logout(request)
    return JsonResponse({'success': True, 'message': 'Logged out successfully'})

def auth_status_api(request):
    if request.user.is_authenticated:
        return JsonResponse({
            'authenticated': True,
            'user': serialize_user(request.user)
        })
    return JsonResponse({'authenticated': False}, status=401)

# ── PROFILE APIs ────────────────────────────────────────────────────────────
def profile_api(request, username=None):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if username:
        user = get_object_or_404(CustomUser, username=username)
    else:
        user = request.user

    # Fetch attempts data
    attempts = TestAttempt.objects.filter(user=user).order_by('completed_at')
    attempts_list = []
    for a in attempts:
        attempts_list.append({
            'id': a.id,
            'category_name': a.category.name if a.category else 'Solo Match',
            'score': a.score,
            'total_questions': a.total_questions,
            'coins_earned': a.coins_earned,
            'exp_earned': a.exp_earned,
            'mode': a.mode,
            'completed_at': a.completed_at.isoformat()
        })

    # Stats per category
    cat_stats = TestAttempt.objects.filter(user=user).values('category__name').annotate(
        avg_score=Avg('score'), count=Count('id')
    ).exclude(category__isnull=True)
    
    stats_list = []
    for stat in cat_stats:
        stats_list.append({
            'category_name': stat['category__name'],
            'avg_score': round(stat['avg_score'], 1),
            'count': stat['count']
        })

    # Certificates
    certificates_list = []
    for cert in user.certificates.all().order_by('-uploaded_at'):
        certificates_list.append({
            'id': cert.id,
            'title': cert.title,
            'file_url': cert.file.url,
            'uploaded_at': cert.uploaded_at.isoformat(),
            'is_image': cert.is_image
        })

    return JsonResponse({
        'user': serialize_user(user),
        'attempts': attempts_list,
        'category_stats': stats_list,
        'certificates': certificates_list
    })

@csrf_exempt
def edit_profile_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    try:
        data = json.loads(request.body)
    except Exception:
        data = request.POST

    user = request.user
    if 'first_name' in data: user.first_name = data.get('first_name')
    if 'last_name' in data: user.last_name = data.get('last_name')
    if 'linkedin_url' in data: user.linkedin_url = data.get('linkedin_url')
    if 'github_url' in data: user.github_url = data.get('github_url')
    if 'organization' in data: user.organization = data.get('organization')
    if 'interested_field' in data: user.interested_field = data.get('interested_field')
    if 'hiring_focus' in data: user.hiring_focus = data.get('hiring_focus')
    if 'current_status' in data: user.current_status = data.get('current_status')

    # Avatar upload
    if request.FILES.get('avatar'):
        user.avatar = request.FILES.get('avatar')

    user.save()
    return JsonResponse({
        'success': True,
        'message': 'Profile updated successfully',
        'user': serialize_user(user)
    })

@csrf_exempt
def upload_certificate_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    title = request.POST.get('title')
    file = request.FILES.get('file')

    if not title or not file:
        return JsonResponse({'error': 'Title and file are required'}, status=400)

    cert = Certificate.objects.create(
        user=request.user,
        title=title,
        file=file
    )
    return JsonResponse({
        'success': True,
        'message': 'Certificate uploaded successfully',
        'certificate': {
            'id': cert.id,
            'title': cert.title,
            'file_url': cert.file.url,
            'uploaded_at': cert.uploaded_at.isoformat()
        }
    })

@csrf_exempt
def delete_certificate_api(request, certificate_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    cert = get_object_or_404(Certificate, id=certificate_id, user=request.user)
    cert.delete()
    return JsonResponse({'success': True, 'message': 'Certificate deleted successfully'})

@csrf_exempt
def delete_account_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    user = request.user
    logout(request)
    user.delete()
    return JsonResponse({'success': True, 'message': 'Account permanently deleted'})

# ── PRACTICE & SOLO TEST APIs ───────────────────────────────────────────────
def practice_dashboard_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    core_slugs = [
        'general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 
        'verbal-ability', 'computer-fundamentals', 'programming-aptitude', 
        'debugging-and-code-logic', 'cognitive-ability', 'memory-and-attention'
    ]
    
    company_categories = Category.objects.exclude(slug__in=core_slugs).annotate(q_count=Count('questions')).filter(q_count__gt=0)
    general_categories = Category.objects.filter(slug__in=core_slugs).annotate(q_count=Count('questions')).filter(q_count__gt=0)
    
    # Priority sorting based on interest
    user_interests = request.user.interested_field.lower() if request.user.interested_field else ""
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
    def sort_key(c):
        try:
            return unique_priority_slugs.index(c.slug)
        except ValueError:
            return len(unique_priority_slugs)
    sorted_general.sort(key=sort_key)

    # Serialize
    def _ser_cat(c):
        return {
            'id': c.id,
            'name': c.name,
            'slug': c.slug,
            'description': c.description,
            'q_count': getattr(c, 'q_count', c.questions.count())
        }

    return JsonResponse({
        'general_categories': [_ser_cat(c) for c in sorted_general],
        'company_categories': [_ser_cat(c) for c in company_categories],
    })

def attempt_history_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    user = request.user
    attempts = TestAttempt.objects.filter(user=user).order_by('-completed_at')[:20]

    attempts_list = []
    for a in reversed(attempts):
        attempts_list.append({
            'id': a.id,
            'score': a.score,
            'total_questions': a.total_questions,
            'percentage': round((a.score / a.total_questions * 100), 1) if a.total_questions > 0 else 0,
            'category_name': a.category.name if a.category else 'General',
            'completed_at': a.completed_at.isoformat(),
        })

    return JsonResponse({'attempts': attempts_list})

def start_test_api(request, category_slug):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    user = request.user
    if user.lives < 1:
        return JsonResponse({'error': 'No lives remaining', 'lives': 0}, status=403)

    category = get_object_or_404(Category, slug=category_slug)
    all_questions = list(Question.objects.filter(category=category))
    
    if not all_questions:
        questions = []
    elif len(all_questions) >= 10:
        questions = random.sample(all_questions, 10)
    else:
        questions = all_questions[:]
        while len(questions) < 10:
            questions.append(random.choice(all_questions))
        random.shuffle(questions)

    # Store question ids in session (exactly like traditional views for validation if needed,
    # but we also return them directly in the response for state persistence).
    request.session['test_questions'] = [q.id for q in questions]
    request.session['test_category'] = category.slug

    # Serialize questions
    questions_data = []
    for idx, q in enumerate(questions, start=1):
        options = []
        for o in q.options.all():
            options.append({
                'id': o.id,
                'text': o.text,
            })
        questions_data.append({
            'id': q.id,
            'index': idx,
            'text': q.text,
            'time_limit': q.time_limit,
            'question_type': q.question_type,
            'is_coding': q.is_coding_problem,
            'options': options
        })

    return JsonResponse({
        'category': {
            'name': category.name,
            'slug': category.slug,
        },
        'questions': questions_data
    })

@csrf_exempt
def submit_test_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    try:
        data = json.loads(request.body)
        answers = data.get('answers', {}) # Dict of { question_id : answer_value } (e.g. MCQ Option ID or Coding text)
        category_slug = data.get('category_slug')
    except Exception:
        return JsonResponse({'error': 'Invalid payload'}, status=400)

    # Retrieve from session, or fallback to parameters if session is lost (important for API clients)
    question_ids = request.session.get('test_questions', [])
    if not question_ids:
        # Fallback to keys of answers dictionary if session not active
        try:
            question_ids = [int(k) for k in answers.keys()]
        except Exception:
            return JsonResponse({'error': 'No active test found and invalid keys provided'}, status=400)

    if not question_ids:
        return JsonResponse({'error': 'No questions to submit'}, status=400)

    results_details = []
    score = 0
    total = len(question_ids)

    for index, q_id in enumerate(question_ids, start=1):
        try:
            question = Question.objects.get(id=q_id)
        except Question.DoesNotExist:
            continue
        
        user_answer = answers.get(str(q_id)) or answers.get(q_id) # stringified index key or direct key

        if question.is_coding_problem:
            user_code = str(user_answer or '').strip()
            is_correct = bool(user_code) # Mark as correct if they typed something (consistent with Django codebase)
            results_details.append({
                'question_id': question.id,
                'question_text': question.text,
                'is_coding': True,
                'user_code': user_code,
                'is_correct': is_correct,
                'explanation': question.explanation
            })
            if is_correct:
                score += 1
        else:
            selected_option_id = user_answer
            selected_option = None
            if selected_option_id:
                try:
                    selected_option = Option.objects.get(id=int(selected_option_id))
                except Exception:
                    pass

            correct_option = question.options.filter(is_correct=True).first()
            is_correct = bool(selected_option and selected_option.is_correct)
            
            results_details.append({
                'question_id': question.id,
                'question_text': question.text,
                'is_coding': False,
                'selected_option': {
                    'id': selected_option.id,
                    'text': selected_option.text
                } if selected_option else None,
                'correct_option': {
                    'id': correct_option.id,
                    'text': correct_option.text
                } if correct_option else None,
                'is_correct': is_correct,
                'explanation': question.explanation
            })
            if is_correct:
                score += 1

    # Rewards logic
    coins = score * 10
    exp = score * 20

    user = request.user
    if user.lives > 0:
        user.lives -= 1

    user.coins += coins
    user.exp += exp
    new_level = 1 + (user.exp // 100)
    leveled_up = new_level > user.level
    user.level = new_level
    user.save()

    test_category_slug = category_slug or request.session.get('test_category')
    test_category = None
    if test_category_slug:
         test_category = Category.objects.filter(slug=test_category_slug).first()

    # Save attempt
    TestAttempt.objects.create(
        user=user,
        category=test_category,
        score=score,
        total_questions=total,
        coins_earned=coins,
        exp_earned=exp,
        mode='SOLO'
    )

    # Clean session
    if 'test_questions' in request.session: del request.session['test_questions']
    if 'test_category' in request.session: del request.session['test_category']

    return JsonResponse({
        'success': True,
        'score': score,
        'total': total,
        'coins_earned': coins,
        'exp_earned': exp,
        'leveled_up': leveled_up,
        'new_level': new_level,
        'lives_remaining': user.lives,
        'results': results_details
    })

def practice_arena_pdfs_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.user.is_company or request.user.is_superuser:
        return JsonResponse({'error': 'Practice Arena is for Candidates only.'}, status=403)

    pdf_list = []
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'practice_questions')
    
    if os.path.exists(pdf_dir):
        for filename in os.listdir(pdf_dir):
            if filename.lower().endswith('.pdf'):
                file_path = os.path.join(pdf_dir, filename)
                file_size = os.path.getsize(file_path)
                
                if file_size < 1024 * 1024:
                    size_str = f"{round(file_size / 1024, 1)} KB"
                else:
                    size_str = f"{round(file_size / (1024 * 1024), 1)} MB"
                
                pdf_list.append({
                    'name': filename,
                    'url': f"/api/tests/arena/practice/pdf/{filename}", # Proxy url to serve watermarked PDF
                    'size': size_str,
                })

    return JsonResponse({'pdfs': pdf_list})

def serve_pdf_api(request, filename):
    """
    Exposes the serve_watermarked_pdf functionality over API.
    Can be loaded directly into a PDF viewer on mobile.
    """
    # Bypass Django session authentication for downloading practice PDFs via API
    from apps.tests.views import _serve_pdf_helper
    return _serve_pdf_helper(request, filename, check_candidate=False)

# ── GAMIFICATION APIs ────────────────────────────────────────────────────────
def store_items_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    store_items = StoreItem.objects.all()
    user = request.user
    
    # User's current inventory
    inventory = UserItem.objects.filter(user=user)
    purchased_item_ids = [ui.item.id for ui in inventory]
    equipped_item_ids = [ui.item.id for ui in inventory if ui.is_equipped]

    items_list = []
    for item in store_items:
        items_list.append({
            'id': item.id,
            'name': item.name,
            'description': item.description,
            'cost': item.cost,
            'item_type': item.item_type,
            'image_url': item.image.url if item.image else None,
            'min_level_required': item.min_level_required,
            'is_purchased': item.id in purchased_item_ids,
            'is_equipped': item.id in equipped_item_ids
        })

    return JsonResponse({
        'coins': user.coins,
        'level': user.level,
        'items': items_list
    })

@csrf_exempt
def buy_item_api(request, item_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    item = get_object_or_404(StoreItem, id=item_id)
    user = request.user

    # Level requirement check
    if user.level < item.min_level_required:
        return JsonResponse({'error': f"Minimum level {item.min_level_required} required."}, status=400)

    # Already purchased check
    existing = UserItem.objects.filter(user=user, item=item).first()
    if existing:
        # Toggle equip status
        existing.is_equipped = not existing.is_equipped
        existing.save()
        return JsonResponse({
            'success': True,
            'message': 'Item equipped status toggled',
            'is_equipped': existing.is_equipped
        })

    # Balance check
    if user.coins < item.cost:
        return JsonResponse({'error': 'Insufficient coins.'}, status=400)

    # Deduct and save inventory
    user.coins -= item.cost
    user.save()

    new_ui = UserItem.objects.create(user=user, item=item, is_equipped=True)
    return JsonResponse({
        'success': True,
        'message': 'Item purchased successfully',
        'is_equipped': new_ui.is_equipped,
        'coins': user.coins
    })

def spin_wheel_status_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    user = request.user
    if user.is_company or user.is_superuser:
        return JsonResponse({'eligible': False, 'message': 'Only candidates can spin.'})

    now = timezone.now()
    has_spun_this_month = MonthlySpin.objects.filter(
        user=user,
        spin_date__year=now.year,
        spin_date__month=now.month
    ).exists()

    return JsonResponse({
        'eligible': not has_spun_this_month,
        'next_spin_month': (now.month % 12) + 1 if has_spun_this_month else now.month
    })

@csrf_exempt
def process_spin_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    # Reuses process_spin view directly
    from gamification.views import process_spin
    return process_spin(request)

# ── EVENTS APIs (STUDENTS & RECRUITERS) ──────────────────────────────────────
def events_dashboard_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    user = request.user
    now = timezone.now()

    if user.is_company:
        # Recruiter Created Events
        created_events = Event.objects.filter(recruiter=user).order_by('-created_at')
        events_list = []
        for ev in created_events:
            registrations_count = ev.registrations.count()
            completed_count = ev.registrations.exclude(completed_at__isnull=True).count()
            events_list.append({
                'id': ev.id,
                'title': ev.title,
                'description': ev.description,
                'category': ev.category.name if ev.category else 'General',
                'start_time': ev.start_time.isoformat(),
                'end_time': ev.end_time.isoformat(),
                'total_questions': ev.total_questions,
                'is_active': ev.is_active,
                'registrations_count': registrations_count,
                'completed_count': completed_count,
                'status': 'LIVE' if ev.is_live else ('UPCOMING' if ev.is_upcoming else 'ENDED')
            })
        return JsonResponse({'recruiter_events': events_list})
    else:
        # Student Available Events list
        all_events = Event.objects.filter(is_active=True).order_by('start_time')
        student_events = []
        
        # User's registrations
        registered_event_ids = EventRegistration.objects.filter(user=user).values_list('event_id', flat=True)
        completed_event_ids = EventRegistration.objects.filter(user=user, completed_at__isnull=False).values_list('event_id', flat=True)

        for ev in all_events:
            student_events.append({
                'id': ev.id,
                'title': ev.title,
                'description': ev.description,
                'category': ev.category.name if ev.category else 'General',
                'start_time': ev.start_time.isoformat(),
                'end_time': ev.end_time.isoformat(),
                'total_questions': ev.total_questions,
                'time_limit_seconds': ev.time_limit_seconds,
                'threshold_type': ev.threshold_type,
                'threshold_value': ev.threshold_value,
                'is_registered': ev.id in registered_event_ids,
                'is_completed': ev.id in completed_event_ids,
                'status': 'LIVE' if ev.is_live else ('UPCOMING' if ev.is_upcoming else 'ENDED')
            })
        return JsonResponse({'student_events': student_events})

@csrf_exempt
def create_event_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if not request.user.is_company:
        return JsonResponse({'error': 'Recruiters only'}, status=403)

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    try:
        data = json.loads(request.body)
    except Exception:
        data = request.POST

    title = data.get('title')
    category_id = data.get('category_id')
    description = data.get('description', '')
    start_time_str = data.get('start_time')
    end_time_str = data.get('end_time')
    total_questions = int(data.get('total_questions', 10))
    time_limit_seconds = int(data.get('time_limit_seconds', 600))
    threshold_type = data.get('threshold_type', 'TIME')
    threshold_value = int(data.get('threshold_value', 0))

    if not title or not category_id or not start_time_str or not end_time_str:
        return JsonResponse({'error': 'Title, category, start time and end time are required'}, status=400)

    try:
        category = Category.objects.get(id=category_id)
        start_time = timezone.datetime.fromisoformat(start_time_str)
        end_time = timezone.datetime.fromisoformat(end_time_str)
        
        event = Event.objects.create(
            title=title,
            recruiter=request.user,
            category=category,
            description=description,
            start_time=start_time,
            end_time=end_time,
            total_questions=total_questions,
            time_limit_seconds=time_limit_seconds,
            threshold_type=threshold_type,
            threshold_value=threshold_value
        )
        return JsonResponse({
            'success': True,
            'message': 'Event created successfully',
            'event_id': event.id
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@csrf_exempt
def register_event_api(request, event_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    event = get_object_or_404(Event, id=event_id, is_active=True)
    user = request.user

    # Level logic threshold check
    if event.threshold_type == 'LEVEL' and user.level < event.threshold_value:
        return JsonResponse({'error': f"Minimum level {event.threshold_value} required for this event."}, status=400)

    # Time logic (FCFS seat limit check)
    if event.threshold_type == 'TIME' and event.threshold_value > 0:
        if event.registrations.count() >= event.threshold_value:
            return JsonResponse({'error': 'Event seats are full.'}, status=400)

    registration, created = EventRegistration.objects.get_or_create(event=event, user=user)
    return JsonResponse({
        'success': True,
        'message': 'Registered for event successfully' if created else 'Already registered'
    })

def event_detail_api(request, event_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    event = get_object_or_404(Event, id=event_id)
    reg = EventRegistration.objects.filter(event=event, user=request.user).first()
    
    is_registered = reg is not None
    is_completed = reg.completed_at is not None if reg else False
    score = reg.score if reg else None

    # Fetch event questions (Only if registered, and event is live, and student hasn't finished)
    questions_list = []
    if is_registered and event.is_live and not is_completed:
        questions = event.questions.all()
        for idx, q in enumerate(questions, start=1):
            questions_list.append({
                'id': q.id,
                'index': idx,
                'text': q.text,
                'option_a': q.option_a,
                'option_b': q.option_b,
                'option_c': q.option_c,
                'option_d': q.option_d,
                'marks': q.marks
            })

    return JsonResponse({
        'event': {
            'id': event.id,
            'title': event.title,
            'description': event.description,
            'start_time': event.start_time.isoformat(),
            'end_time': event.end_time.isoformat(),
            'time_limit_seconds': event.time_limit_seconds,
            'is_live': event.is_live,
            'total_questions': event.total_questions,
        },
        'registration': {
            'is_registered': is_registered,
            'is_completed': is_completed,
            'score': score
        },
        'questions': questions_list
    })

@csrf_exempt
def submit_event_test_api(request, event_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    event = get_object_or_404(Event, id=event_id)
    reg = get_object_or_404(EventRegistration, event=event, user=request.user)

    if reg.completed_at:
        return JsonResponse({'error': 'You have already submitted this event test.'}, status=400)

    try:
        data = json.loads(request.body)
        answers = data.get('answers', {}) # format: { question_id : 'A'/'B'/'C'/'D' }
    except Exception:
        return JsonResponse({'error': 'Invalid payload'}, status=400)

    score = 0
    for q in event.questions.all():
        ans = answers.get(str(q.id)) or answers.get(q.id)
        if ans and ans.strip().upper() == q.correct_option:
            score += q.marks

    reg.score = score
    reg.completed_at = timezone.now()
    reg.save()

    return JsonResponse({
        'success': True,
        'message': 'Event test submitted successfully',
        'score': score
    })

def event_results_api(request, event_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    event = get_object_or_404(Event, id=event_id)
    registrations = event.registrations.exclude(completed_at__isnull=True).order_by('-score', 'completed_at')

    leaderboard = []
    for rank, reg in enumerate(registrations, start=1):
        leaderboard.append({
            'rank': rank,
            'username': reg.user.username,
            'score': reg.score,
            'time_taken_seconds': (reg.completed_at - reg.registered_at).total_seconds() if reg.completed_at else None,
            'level': reg.user.level
        })

    return JsonResponse({
        'event_title': event.title,
        'leaderboard': leaderboard
    })

# ── INBOX & CHAT APIs ────────────────────────────────────────────────────────
def inbox_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    conversations = Conversation.objects.filter(participants=request.user).order_by('-updated_at')
    conv_list = []
    
    for conv in conversations:
        other_user = conv.participants.exclude(id=request.user.id).first()
        last_msg = conv.messages.last()
        
        conv_list.append({
            'conversation_id': conv.id,
            'other_user': serialize_user(other_user) if other_user else None,
            'last_message': {
                'content': last_msg.content,
                'timestamp': last_msg.timestamp.isoformat(),
                'sender': last_msg.sender.username,
                'is_read': last_msg.is_read
            } if last_msg else None,
            'updated_at': conv.updated_at.isoformat()
        })

    return JsonResponse({'conversations': conv_list})

def chat_detail_api(request, conversation_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    conversation = get_object_or_404(Conversation, participants=request.user, id=conversation_id)
    other_user = conversation.participants.exclude(id=request.user.id).first()

    # Mark unread messages as read
    conversation.messages.filter(is_read=False).exclude(sender=request.user).update(is_read=True)

    messages = conversation.messages.all().order_by('timestamp')
    messages_list = []
    for msg in messages:
        messages_list.append({
            'id': msg.id,
            'content': msg.content,
            'timestamp': msg.timestamp.isoformat(),
            'sender': msg.sender.username,
            'is_read': msg.is_read
        })

    return JsonResponse({
        'conversation_id': conversation.id,
        'other_user': serialize_user(other_user) if other_user else None,
        'messages': messages_list
    })

@csrf_exempt
def send_message_api(request, conversation_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    conversation = get_object_or_404(Conversation, participants=request.user, id=conversation_id)
    
    try:
        data = json.loads(request.body)
        content = data.get('content')
    except Exception:
        content = request.POST.get('content')

    if not content:
        return JsonResponse({'error': 'Message content is required'}, status=400)

    msg = Message.objects.create(
        conversation=conversation,
        sender=request.user,
        content=content
    )
    conversation.updated_at = timezone.now()
    conversation.save()

    return JsonResponse({
        'success': True,
        'message': {
            'id': msg.id,
            'content': msg.content,
            'timestamp': msg.timestamp.isoformat(),
            'sender': msg.sender.username
        }
    })

# ── CUSTOM ADMIN APIs ────────────────────────────────────────────────────────
def admin_dashboard_stats_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if not request.user.is_superuser:
        return JsonResponse({'error': 'Admins only'}, status=403)

    from django.db.models.functions import TruncMonth

    total_users = CustomUser.objects.count()
    total_questions = Question.objects.count()
    total_tests_taken = TestAttempt.objects.count()
    total_items_sold = UserItem.objects.count()

    user_growth = CustomUser.objects.annotate(month=TruncMonth('date_joined')).values('month').annotate(count=Count('id')).order_by('month')
    growth_labels = [entry['month'].strftime('%b %Y') for entry in user_growth]
    growth_data = [entry['count'] for entry in user_growth]

    recent_users = CustomUser.objects.order_by('-date_joined')[:10]
    popular_items = StoreItem.objects.annotate(sold_count=Count('useritem')).order_by('-sold_count')[:5]
    categories = Category.objects.annotate(q_count=Count('questions')).order_by('-q_count')

    settings = SiteSetting.get_settings()

    return JsonResponse({
        'total_users': total_users,
        'total_questions': total_questions,
        'total_tests_taken': total_tests_taken,
        'total_items_sold': total_items_sold,
        'anti_malpractice_enabled': settings.anti_malpractice_enabled,
        'growth_chart': {
            'labels': growth_labels,
            'data': growth_data
        },
        'recent_users': [serialize_user(u) for u in recent_users],
        'popular_items': [{
            'name': item.name,
            'sold_count': item.sold_count
        } for item in popular_items],
        'categories': [{
            'name': c.name,
            'q_count': c.q_count
        } for c in categories]
    })

@csrf_exempt
def admin_toggle_malpractice_api(request):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if not request.user.is_superuser:
        return JsonResponse({'error': 'Admins only'}, status=403)

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    settings = SiteSetting.get_settings()
    settings.anti_malpractice_enabled = not settings.anti_malpractice_enabled
    settings.save()

    return JsonResponse({
        'success': True,
        'anti_malpractice_enabled': settings.anti_malpractice_enabled
    })

@csrf_exempt
def admin_delete_user_api(request, user_id):
    auth_err = check_auth(request)
    if auth_err: return auth_err

    if not request.user.is_superuser:
        return JsonResponse({'error': 'Admins only'}, status=403)

    if request.method != 'POST':
        return JsonResponse({'error': 'Only POST allowed'}, status=405)

    target_user = get_object_or_404(CustomUser, id=user_id)
    if target_user.id == request.user.id:
        return JsonResponse({'error': 'You cannot delete your own admin account.'}, status=400)

    username = target_user.username
    target_user.delete()
    return JsonResponse({
        'success': True,
        'message': f"User '{username}' was permanently deleted."
    })
