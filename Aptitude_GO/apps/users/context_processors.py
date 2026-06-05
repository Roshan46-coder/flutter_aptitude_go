from apps.users.models import SiteSetting

def site_settings(request):
    """
    Global Context Processor that injects SiteSettings into all templates.
    """
    settings = SiteSetting.get_settings()
    return {
        'site_settings': settings
    }
