# content/apps.py

from django.apps import AppConfig

class ContentConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'content'

    def ready(self):
        """
        Import and connect the signal handlers when the app is ready.
        """
        import content.signals  # THIS LINE IS CRITICAL