from django import template
from apps.users.models import Message

register = template.Library()

@register.simple_tag
def has_unread_messages(user):
    if not user.is_authenticated:
        return False
    # Check if there are any unread messages in conversations where the user is a participant
    # and the message was NOT sent by the user.
    return Message.objects.filter(
        conversation__participants=user,
        is_read=False
    ).exclude(sender=user).exists()
