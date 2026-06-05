from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model
from django.db.models import Q

UserModel = get_user_model()

class EmailOrUsernameModelBackend(ModelBackend):
    """
    Custom authentication backend that allows logging in with either
    a username or an email address.
    """
    def authenticate(self, request, username=None, password=None, **kwargs):
        if username is None:
            username = kwargs.get(UserModel.USERNAME_FIELD)
        try:
            # Case insensitive search for username or email
            user = UserModel.objects.filter(
                Q(username__iexact=username) | Q(email__iexact=username)
            ).first()
        except UserModel.DoesNotExist:
            return None
        
        if user and user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None

    def user_can_authenticate(self, user):
        """
        Allow inactive users to be returned by authenticate() so that the view
        can check user.is_active and return a specific 'Account is inactive' error
        instead of a generic 'Invalid username or password'.
        """
        return True

