from django import template
from gamification.models import UserItem

register = template.Library()

@register.simple_tag
def get_equipped_frame(user):
    if not user.is_authenticated:
        return None
    user_item = UserItem.objects.filter(user=user, item__item_type='FRAME', is_equipped=True).first()
    return user_item.item if user_item else None
