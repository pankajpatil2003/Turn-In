from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Post, Feed

# --- Helper Function for Rank Update ---
def calculate_and_update_rank(feed_instance):
    """
    Calculates a simple rank score based on total_used and recency.
    Note: This runs every time a tag's stats are updated.
    """
    
    # 1. Total Usage Score
    usage_score = feed_instance.total_used
    
    # 2. Recency Score (Closer to now is better, gives boost for activity)
    days_since_last_used = (timezone.now() - feed_instance.last_used_at).days
    
    # Simple Recency Multiplier: Gives a positive score if used in the last 7 days.
    recency_score = max(0, 7 - days_since_last_used) * 0.5 
    
    new_rank = usage_score + recency_score
    
    # Update the rank in the database
    Feed.objects.filter(pk=feed_instance.pk).update(Rank=new_rank)


# --- Signal Handler ---
@receiver(post_save, sender=Post)
def update_feed_statistics(sender, instance, created, **kwargs):
    """
    Handler that updates Feed entries whenever a Post is created or modified.
    """
    
    if not instance.is_published:
        return

    post_tags = instance.tags
    now = timezone.now()

    for raw_tag_name in post_tags:
        # Final cleanup ensures consistency with serializer logic
        tag_name = raw_tag_name.strip().upper() 

        # 1. Get the Feed instance or create it
        feed_instance, is_new = Feed.objects.get_or_create(
            tag=tag_name,
            # Set default values for a new tag
            defaults={'total_used': 1, 'last_used_at': now, 'Rank': 1.0}
        )
        
        # 2. If the tag already existed (not new)
        if not is_new:
            update_fields = {'last_used_at': now}
            
            # CRITICAL: Only increment total_used if the post is NEW.
            if created:
                update_fields['total_used'] = feed_instance.total_used + 1
            
            # Perform the update
            Feed.objects.filter(pk=feed_instance.pk).update(**update_fields)

            # Manually update the in-memory instance for the Rank calculation
            if created:
                feed_instance.total_used += 1

        # 3. Update the rank based on current stats
        calculate_and_update_rank(feed_instance)