from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from django.http import HttpResponseForbidden, HttpResponse, Http404
from django.conf import settings
from .models import Category, Question, TestAttempt, Option
from gamification.models import MonthlySpin
import random
import os
import io
import fitz  # PyMuPDF

@login_required
def practice_arena(request):
    # ACCESS CONTROL: Only allow users (role == "user")
    # In this system, role "user" is a candidate (not company, not superuser)
    if request.user.is_company or request.user.is_superuser:
        return HttpResponseForbidden("Access Denied: Practice Arena is for Candidates only.")

    pdf_list = []
    pdf_dir = os.path.join(settings.MEDIA_ROOT, 'practice_questions')
    
    if os.path.exists(pdf_dir):
        for filename in os.listdir(pdf_dir):
            if filename.lower().endswith('.pdf'):
                file_path = os.path.join(pdf_dir, filename)
                file_size = os.path.getsize(file_path)
                
                # Convert size to readable format
                if file_size < 1024 * 1024:
                    size_str = f"{round(file_size / 1024, 1)} KB"
                else:
                    size_str = f"{round(file_size / (1024 * 1024), 1)} MB"
                
                pdf_list.append({
                    'name': filename,
                    'url': f"{settings.MEDIA_URL}practice_questions/{filename}",
                    'size': size_str,
                })
    
    return render(request, 'tests/practice_arena.html', {'pdf_list': pdf_list})

@login_required
def arena_home(request):
    return render(request, 'tests/arena_home.html')

@login_required
def practice_dashboard(request):
    from django.db.models import Count
    from django.utils.text import slugify

    # Find categories that represent companies. A robust way is to check the imported slugs.
    # Since company categories were imported, we can define a base set, 
    # OR better yet, check the actual folders once, but fallback safely.
    # We will identify company categories as those NOT in the core aptitude list.
    core_slugs = [
        'general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 
        'verbal-ability', 'computer-fundamentals', 'programming-aptitude', 
        'debugging-and-code-logic', 'cognitive-ability', 'memory-and-attention'
    ]
    
    # All non-core categories with at least 1 question are assumed to be "Company Categories"
    company_categories = Category.objects.exclude(slug__in=core_slugs).annotate(q_count=Count('questions')).filter(q_count__gt=0)
    general_categories = Category.objects.filter(slug__in=core_slugs).annotate(q_count=Count('questions')).filter(q_count__gt=0)
    
    # Priority sorting based on user's interests
    user_interests = request.user.interested_field.lower() if request.user.is_authenticated and hasattr(request.user, 'interested_field') and request.user.interested_field else ""
    
    priority_slugs = []
    
    # Tech / IT / Software / Data / Engineering
    if any(kw in user_interests for kw in ['software', 'it', 'tech', 'data', 'developer', 'computer', 'engineer']):
        priority_slugs.extend(['computer-fundamentals', 'programming-aptitude', 'debugging-and-code-logic', 'cognitive-ability'])
        
    # Management / Banking / Study Abroad
    if any(kw in user_interests for kw in ['management', 'mba', 'banking', 'business', 'finance', 'marketing', 'abroad']):
        priority_slugs.extend(['quantitative-aptitude', 'logical-reasoning', 'verbal-ability', 'memory-and-attention', 'cognitive-ability'])
        
    # Civil Services / Defense / Railways / General
    if any(kw in user_interests for kw in ['civil', 'defense', 'railway', 'general', 'government']):
        priority_slugs.extend(['general-aptitude', 'logical-reasoning', 'quantitative-aptitude', 'verbal-ability', 'memory-and-attention'])

    # Remove duplicates preserving order
    unique_priority_slugs = []
    for slug in priority_slugs:
        if slug not in unique_priority_slugs:
            unique_priority_slugs.append(slug)
            
    # List conversion for custom sorting
    sorted_general = list(general_categories)
    
    def sort_key(category):
        try:
            return unique_priority_slugs.index(category.slug)
        except ValueError:
            return len(unique_priority_slugs) # Put it at the bottom if not prioritized
            
    sorted_general.sort(key=sort_key)
    
    # Check reward wheel eligibility
    user = request.user
    is_eligible_for_spin = user.is_authenticated and not user.is_company and not user.is_superuser
    show_wheel_modal = False
    
    if is_eligible_for_spin:
        now = timezone.now()
        has_spun_this_month = MonthlySpin.objects.filter(
            user=user,
            spin_date__year=now.year,
            spin_date__month=now.month
        ).exists()
        show_wheel_modal = not has_spun_this_month

    return render(request, 'tests/dashboard.html', {
        'categories': sorted_general,
        'company_categories': company_categories,
        'show_wheel_modal': show_wheel_modal,
    })

@login_required
def start_test(request, category_slug):
    user = request.user
    if user.lives < 1:
        return render(request, 'tests/no_lives.html')

    category = get_object_or_404(Category, slug=category_slug)
    # Get questions (target 10)
    all_questions = list(Question.objects.filter(category=category))
    
    if not all_questions:
        # Handle case with 0 questions gracefully (perhaps redirect or show empty)
        # For now, let's just return empty list to template, template handles it
        questions = []
    elif len(all_questions) >= 10:
        questions = random.sample(all_questions, 10)
    else:
        # Not enough questions, fill with duplicates
        questions = all_questions[:] # Start with all unique ones
        while len(questions) < 10:
            questions.append(random.choice(all_questions))
            
        # Shuffle to mix duplicates
        random.shuffle(questions)
    
    # Store questions in session - store separate entry for distinct indices if needed
    # But since we just need IDs for checking, and we allow duplicates, logic needs to be robust.
    # The submit view iterates over session['test_questions']. 
    # If we have [1, 2, 1], the submit view will check q_1, q_2, q_1. 
    # The form needs to handle this.
    # Actually, form input names usually use question ID. duplicate IDs in form will be tricky.
    # Better approach: Generate unique 'instance IDs' or just use list index in form.
    # Let's see submit_test. It gets `question_{q_id}`.
    # If we have duplicate Question 1, both inputs will be named `question_1`.
    # HTML form will send `question_1` twice? Or last one wins?
    # FIX: We should probably not allow exact duplicates if possible, or handle them.
    # User said "allow questions to repeat". 
    # To handle repeats in a form properly, we should use a custom index for the field name.
    # e.g. `question_{index}_{q_id}`.
    
    # Let's adjust the session storage to store full structure or just rely on list order.
    # For now, let's just save list of IDs.
    
    request.session['test_questions'] = [q.id for q in questions]
    request.session['test_category'] = category.slug
    
    # Pass 1-based index to template for identifying specific instance of a question
    # (Though template loop counter does this)
    
    return render(request, 'tests/test_interface.html', {'questions': questions, 'category': category})

@login_required
def submit_test(request):
    if request.method == 'POST':
        question_ids = request.session.get('test_questions', [])
        if not question_ids:
            return redirect('practice_dashboard')

        results_details = []
        score = 0
        total = len(question_ids)
        
        for index, q_id in enumerate(question_ids, start=1):
            try:
                question = Question.objects.get(id=q_id)
            except Question.DoesNotExist:
                continue
            
            if question.is_coding_problem:
                # Coding problem: get typed answer from textarea
                user_code = request.POST.get(f'code_answer_{index}', '').strip()
                
                results_details.append({
                    'question': question,
                    'is_coding': True,
                    'user_code': user_code,
                    'selected_option': None,
                    'correct_option': None,
                    'is_correct': bool(user_code),  # Mark as "attempted" if they typed something
                    'explanation': question.explanation,
                })
                if user_code:
                    score += 1  # Give credit for attempting coding problems
            else:
                # MCQ: get selected radio option
                selected_option_id = request.POST.get(f'answer_{index}')
                
                selected_option = None
                if selected_option_id:
                    selected_option = Option.objects.filter(id=selected_option_id).first()
                
                correct_option = question.options.filter(is_correct=True).first()
                
                is_correct = False
                if selected_option and selected_option.is_correct:
                    score += 1
                    is_correct = True
                
                results_details.append({
                    'question': question,
                    'is_coding': False,
                    'user_code': '',
                    'selected_option': selected_option,
                    'correct_option': correct_option,
                    'is_correct': is_correct,
                    'explanation': question.explanation,
                })
        
        # Calculate Rewards
        coins = score * 10
        exp = score * 20
        
        # Update User
        user = request.user
        if user.lives > 0:
            user.lives -= 1
        
        user.coins += coins
        user.exp += exp
        # specific level logic: level = 1 + exp // 100
        new_level = 1 + (user.exp // 100)
        leveled_up = new_level > user.level
        user.level = new_level
        user.save()
        
        # Save Attempt
        test_category_slug = request.session.get('test_category')
        test_category = None
        if test_category_slug:
             test_category = Category.objects.filter(slug=test_category_slug).first()

        TestAttempt.objects.create(
            user=user,
            category=test_category,
            score=score,
            total_questions=total,
            coins_earned=coins,
            exp_earned=exp,
            mode='SOLO'
        )
        
        del request.session['test_questions']
        
        # Use actual results length for total
        actual_total = len(results_details)
        
        context = {
            'score': score,
            'total': actual_total,
            'coins': coins,
            'exp': exp,
            'leveled_up': leveled_up,
            'new_level': new_level,
            'results_details': results_details
        }
        return render(request, 'tests/result.html', context)
    return redirect('practice_dashboard')


def _serve_pdf_helper(request, filename, check_candidate=True):
    # ── Access control: candidates only ──────────────────────────────────────
    if check_candidate and request.user.is_authenticated:
        if getattr(request.user, 'is_company', False) or request.user.is_superuser:
            return HttpResponseForbidden("Access Denied: Practice Arena is for Candidates only.")

    # ── Validate filename (no path traversal, must be a .pdf) ────────────────
    safe_filename = os.path.basename(filename)
    if not safe_filename.lower().endswith('.pdf'):
        raise Http404("Not a PDF file.")

    pdf_path = os.path.join(settings.MEDIA_ROOT, 'practice_questions', safe_filename)
    if not os.path.isfile(pdf_path):
        raise Http404("PDF not found.")

    # ── Locate watermark PNG (stored next to this views.py) ──────────────────
    wm_path = os.path.join(os.path.dirname(__file__), 'watermark.png')
    if not os.path.isfile(wm_path):
        # Fallback: serve the original PDF without watermark rather than crash
        with open(pdf_path, 'rb') as f:
            pdf_bytes = f.read()
        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        disposition = 'attachment' if request.GET.get('download') else 'inline'
        response['Content-Disposition'] = f'{disposition}; filename="{safe_filename}"'
        return response

    # ── Apply watermark with PyMuPDF ─────────────────────────────────────────
    try:
        doc = fitz.open(pdf_path)

        for page in doc:
            page_rect = page.rect  # fitz.Rect (x0, y0, x1, y1)

            # Place watermark at 50% of page width, centered (avoid edge-to-edge)
            wm_width  = page_rect.width  * 0.50
            wm_height = page_rect.height * 0.25   # preserve aspect ratio space

            x0 = (page_rect.width  - wm_width)  / 2
            y0 = (page_rect.height - wm_height) / 2
            wm_rect = fitz.Rect(x0, y0, x0 + wm_width, y0 + wm_height)

            # insert_image with alpha < 1 achieves the low-opacity look
            # overlay=False → drawn strictly *behind* existing content (background layer)
            page.insert_image(
                wm_rect,
                filename=wm_path,
                overlay=False,   # strictly background layer
                alpha=20,        # 20 / 255 ≈ 8% opacity
            )

        # ── Write to in-memory buffer and return ─────────────────────────────────
        buf = io.BytesIO()
        doc.save(buf, garbage=4, deflate=True)
        doc.close()
        buf.seek(0)

        disposition = 'attachment' if request.GET.get('download') else 'inline'
        response = HttpResponse(buf.read(), content_type='application/pdf')
        response['Content-Disposition'] = f'{disposition}; filename="{safe_filename}"'
        return response
    except Exception as e:
        # Fallback to serving the original PDF if fitz/watermarking fails
        with open(pdf_path, 'rb') as f:
            pdf_bytes = f.read()
        response = HttpResponse(pdf_bytes, content_type='application/pdf')
        disposition = 'attachment' if request.GET.get('download') else 'inline'
        response['Content-Disposition'] = f'{disposition}; filename="{safe_filename}"'
        return response


@login_required
def serve_watermarked_pdf(request, filename):
    """
    Dynamically overlay the Aptitude GO watermark on every page of a
    Practice-module PDF and stream the result.  The source file on disk is
    NEVER modified.
    """
    return _serve_pdf_helper(request, filename, check_candidate=True)
