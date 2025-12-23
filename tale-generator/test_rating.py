"""Test script for story rating functionality."""

import logging
import os
from src.supabase_client import SupabaseClient
from src.models import StoryRatingRequest

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("test_rating")

def test_rating_functionality():
    """Test the story rating functionality."""
    try:
        # Initialize the Supabase client
        client = SupabaseClient()
        logger.info("Supabase client initialized successfully")
        
        # Get all stories to find one to rate
        stories = client.get_all_stories()
        if not stories:
            logger.warning("No stories found in the database to rate")
            return
            
        # Select the first story for testing
        story = stories[0]
        logger.info(f"Selected story: {story.title} (ID: {story.id})")
        
        # Rate the story with a score of 8
        rating_request = StoryRatingRequest(rating=8)
        updated_story = client.update_story_rating(story.id, rating_request.rating)
        
        if updated_story:
            logger.info(f"Successfully rated story '{updated_story.title}' with {updated_story.rating}/10")
            
            # Verify the rating was saved
            retrieved_story = client.get_story(story.id)
            if retrieved_story and retrieved_story.rating == 8:
                logger.info(f"Rating verification successful: {retrieved_story.rating}/10")
            else:
                logger.error("Rating verification failed")
        else:
            logger.error("Failed to rate story")
            
    except Exception as e:
        logger.error(f"Error testing rating functionality: {e}", exc_info=True)
        # Log a helpful message about applying the migration
        logger.info("Make sure you have applied the rating migration:")
        logger.info("Run: python apply_rating_migration.py")
        logger.info("Then manually apply the SQL in your Supabase dashboard")

if __name__ == "__main__":
    test_rating_functionality()