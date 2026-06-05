from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.utils import timezone
from django.db.models import Count, Q
from .models import Event, EventQuestion, EventRegistration
from .forms import EventForm, EventQuestionForm
from django.forms import modelformset_factory

@login_required
def recruiter_dashboard(request):
    if not request.user.is_company:
        return redirect('home')
    
    events = Event.objects.filter(recruiter=request.user).order_by('-created_at')
    return render(request, 'events/recruiter_dashboard.html', {'events': events})

@login_required
def create_event(request):
    if not request.user.is_company:
        return redirect('home')

    if request.method == 'POST':
        form = EventForm(request.POST)
        if form.is_valid():
            event = form.save(commit=False)
            event.recruiter = request.user
            event.save()
            messages.success(request, 'Event created! Now add some questions.')
            return redirect('add_questions', event_id=event.id)
    else:
        form = EventForm()
    
    return render(request, 'events/create_event.html', {'form': form})

@login_required
def add_questions(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    
    if request.method == 'POST':
        form = EventQuestionForm(request.POST)
        if form.is_valid():
            question = form.save(commit=False)
            question.event = event
            question.save()
            messages.success(request, 'Question added successfully.')
            
            if 'save_and_add_another' in request.POST:
                return redirect('add_questions', event_id=event.id)
            else:
                return redirect('recruiter_events')
    else:
        form = EventQuestionForm()
    
    existing_questions = event.questions.all()
    
    return render(request, 'events/add_questions.html', {
        'form': form,
        'event': event,
        'existing_questions': existing_questions
    })

@login_required
def cancel_event(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    
    if event.is_live:
         messages.error(request, "Cannot cancel a live event.")
    else:
        event.delete()
        messages.success(request, "Event cancelled successfully.")
        
    return redirect('recruiter_events')

@login_required
def event_results(request, event_id):
    if not request.user.is_company:
        return redirect('home')
        
    event = get_object_or_404(Event, id=event_id, recruiter=request.user)
    registrations = EventRegistration.objects.filter(event=event).select_related('user').order_by('-score', 'completed_at')
    
    return render(request, 'events/event_results.html', {
        'event': event,
        'registrations': registrations
    })

# Student Views

@login_required
def event_list(request):
    now = timezone.now()
    # Events that are upcoming or currently live
    events = Event.objects.filter(is_active=True, end_time__gt=now).order_by('start_time')
    
    return render(request, 'events/event_list.html', {'events': events})

@login_required
def event_detail(request, event_id):
    event = get_object_or_404(Event, id=event_id)
    
    # Check if already registered
    registration = EventRegistration.objects.filter(user=request.user, event=event).first()
    is_registered = registration is not None
    
    if request.method == 'POST' and 'register' in request.POST:
        if not is_registered:
            # Check threshold
            if event.threshold_type == 'LEVEL':
               if request.user.level < event.threshold_value:
                   messages.error(request, f"You need to be at least level {event.threshold_value} to enter.")
                   return redirect('event_detail', event_id=event.id)
            elif event.threshold_type == 'TIME':
                # TIME = First Come First Serve = Max Participants
                current_registrations = EventRegistration.objects.filter(event=event).count()
                if event.threshold_value > 0 and current_registrations >= event.threshold_value:
                    messages.error(request, "Event is full. Max participants reached.")
                    return redirect('event_detail', event_id=event.id)
            
            # Life Deduction
            if not request.user.is_company and not request.user.is_superuser:
                if request.user.lives > 0:
                    request.user.lives -= 1
                    request.user.save()
                else:
                    messages.error(request, "You don't have enough lives to enter this event. Purchase more in the store.")
                    return redirect('store')
            
            EventRegistration.objects.create(user=request.user, event=event)
            messages.success(request, "Successfully registered for the event!")
            return redirect('event_detail', event_id=event.id)

    return render(request, 'events/event_detail.html', {
        'event': event, 
        'is_registered': is_registered,
        'registration': registration,
        'now': timezone.now()
    })

@login_required
def take_event(request, event_id):
    event = get_object_or_404(Event, id=event_id)
    # Ensure registration exists
    registration = get_object_or_404(EventRegistration, user=request.user, event=event)
    
    if not event.is_live:
         messages.error(request, "This event is not currently live.")
         return redirect('event_detail', event_id=event.id)
    
    if registration.completed_at:
        messages.info(request, "You have already completed this event.")
        return redirect('event_detail', event_id=event.id)

    if request.method == 'POST':
        score = 0
        questions = event.questions.all()[:event.total_questions]
        for q in questions:
            selected_option = request.POST.get(f'question_{q.id}')
            if selected_option and selected_option == q.correct_option:
                score += q.marks
        
        registration.score = score
        registration.completed_at = timezone.now()
        registration.save()
        
        messages.success(request, f"Event completed! You scored {score}.")
        return redirect('event_detail', event_id=event.id)

    questions = event.questions.all()[:event.total_questions]
    return render(request, 'events/take_event.html', {'event': event, 'questions': questions})
