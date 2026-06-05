from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.http import JsonResponse
from django.utils import timezone
from .models import StoreItem, UserItem, MonthlySpin
import random

@login_required
def store_view(request):
    items = StoreItem.objects.all()
    # Get user inventory IDs
    inventory_ids = UserItem.objects.filter(user=request.user).values_list('item_id', flat=True)
    return render(request, 'gamification/store.html', {'items': items, 'inventory_ids': inventory_ids})

@login_required
def buy_item(request, item_id):
    if request.method == 'POST':
        item = get_object_or_404(StoreItem, id=item_id)
        user = request.user
        
        if user.coins >= item.cost:
            if item.item_type == 'LIFE_REFILL':
                if user.lives >= 5:
                    messages.warning(request, "Your lives are already full.")
                else:
                    user.coins -= item.cost
                    user.lives = 5
                    user.save()
                    messages.success(request, "Lives fully refilled!")
            else:
                if UserItem.objects.filter(user=user, item=item).exists():
                    messages.info(request, "You already own this item.")
                else:
                    user.coins -= item.cost
                    user.save()
                    UserItem.objects.create(user=user, item=item)
                    messages.success(request, f"Successfully purchased {item.name}!")
        else:
            messages.error(request, "Not enough coins.")
            
    return redirect('store')

@login_required
def reward_wheel_view(request):
    # Check if user has already spun this month
    now = timezone.now()
    has_spun = MonthlySpin.objects.filter(
        user=request.user,
        spin_date__year=now.year,
        spin_date__month=now.month
    ).exists()
    
    return render(request, 'gamification/reward_wheel.html', {'has_spun': has_spun})

@login_required
def process_spin(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Invalid request'}, status=400)
    
    user = request.user
    now = timezone.now()
    
    # Double check monthly restriction
    if MonthlySpin.objects.filter(
        user=user,
        spin_date__year=now.year,
        spin_date__month=now.month
    ).exists():
        return JsonResponse({'error': 'You have already used your monthly spin!'}, status=403)
    
    # Rewards mapping (matching the frontend wheel segments)
    # 0: +2 Life, 1: 20 Coins, 2: 30 Coins, 3: 50 Coins, 4: Golden Frame, 5: +1 Life
    rewards = [
        {'type': 'LIVES', 'value': 2, 'label': '+2 Life ❤️'},
        {'type': 'COINS', 'value': 20, 'label': '20 Coins 💰'},
        {'type': 'COINS', 'value': 30, 'label': '30 Coins 💰'},
        {'type': 'COINS', 'value': 50, 'label': '50 Coins 💰'},
        {'type': 'FRAME', 'value': 2, 'label': 'Golden Frame 🖼'}, # ID 2 is Golden Frame
        {'type': 'LIVES', 'value': 1, 'label': '+1 Life ❤️'},
    ]
    
    # Logic: Equal segments, so random index 0-5
    reward_index = random.randint(0, 5)
    reward = rewards[reward_index]
    
    # Record spin record first to lock it in
    MonthlySpin.objects.create(
        user=user,
        reward_type=reward['type'],
        reward_value=reward['value']
    )

    # Apply reward
    if reward['type'] == 'COINS':
        user.coins += reward['value']
    elif reward['type'] == 'LIVES':
        user.lives += reward['value']
        # Cap lives at 10
        if user.lives > 10: user.lives = 10
    elif reward['type'] == 'FRAME':
        # Find Golden Frame by name for robustness
        frame_item = StoreItem.objects.filter(name__icontains='Golden Frame').first()
        if not frame_item:
            # Fallback: create it if missing OR use the cost/type to identify
            frame_item = StoreItem.objects.filter(item_type='FRAME').first()
            
        if frame_item:
            # Auto-equip logic: unequip other frames and equip this one
            UserItem.objects.filter(user=user, item__item_type='FRAME').update(is_equipped=False)
            user_item, created = UserItem.objects.get_or_create(user=user, item=frame_item)
            user_item.is_equipped = True
            user_item.save()
    
    user.save()
    
    return JsonResponse({
        'success': True,
        'reward_index': reward_index,
        'reward_label': reward['label'],
        'new_coins': user.coins,
        'new_lives': user.lives
    })
