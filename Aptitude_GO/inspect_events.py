import os
import sys
import django
from django.utils import timezone
import pytz

# Flush stdout to ensure we catch all outputmy
sys.stdout.reconfigure(encoding='utf-8')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'aptitude_platform.settings')
django.setup()

from events.models import Event
from django.conf import settings

def inspect_events():
    with open('event_dump.txt', 'w', encoding='utf-8') as f:
        f.write(f"Timezone in Settings: {settings.TIME_ZONE}\n")
        try:
            f.write(f"Current Timezone (Active): {timezone.get_current_timezone_name()}\n")
        except Exception as e:
            f.write(f"Error getting current timezone: {e}\n")

        now = timezone.now()
        f.write(f"Current Time (UTC): {now}\n")
        f.write(f"Current Time (Local): {timezone.localtime(now)}\n")
        
        f.write("-" * 50 + "\n")
        f.write("Listing All Events:\n")
        
        events = Event.objects.all()
        for e in events:
            f.write(f"ID: {e.id} | Title: {e.title}\n")
            f.write(f"  Start (Stored/UTC): {e.start_time}\n")
            f.write(f"  Start (Local): {timezone.localtime(e.start_time)}\n")
            f.write(f"  End   (Stored/UTC): {e.end_time}\n")
            f.write(f"  End   (Local): {timezone.localtime(e.end_time)}\n")
            f.write(f"  Duration: {e.duration_minutes} mins\n")
            
            # Check logic
            is_end_gt_now = e.end_time > now
            f.write(f"  Is Active: {e.is_active}\n")
            f.write(f"  End > Now: {is_end_gt_now}\n")
            f.write(f"  Visible in List? {e.is_active and is_end_gt_now}\n")
            f.write("-" * 30 + "\n")
            
    print("Dumped to event_dump.txt")

if __name__ == '__main__':
    inspect_events()
