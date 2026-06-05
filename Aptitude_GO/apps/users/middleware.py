from django.utils import timezone

class DailyLifeResetMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.user.is_authenticated:
            user = request.user
            now = timezone.now()
            
            # Reset if never refilled or last refill was before today (local date)
            # relying on Django's timezone handling (USE_TZ=True)
            # converting to local date might depend on TIME_ZONE setting (UTC default)
            
            should_refill = False
            if user.last_life_refill is None:
                should_refill = True
            else:
                # Compare dates
                # If using UTC, this resets at 00:00 UTC. 
                if user.last_life_refill.date() < now.date():
                    should_refill = True
            
            if should_refill:
                user.lives = 5
                user.last_life_refill = now
                user.save()
        
        response = self.get_response(request)
        return response
