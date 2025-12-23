"""Utility script for managing stories in the database."""

import logging
import click
from tabulate import tabulate
from src.logging_config import setup_logging
from src.supabase_client import SupabaseClient
from src.models import Language, ChildDB, StoryRatingRequest

# Set up logger
setup_logging()
logger = logging.getLogger("tale_generator.manage")


@click.group()
def cli():
    """Manage stories and children in the tale generator database."""
    pass


@cli.command()
def list_all_stories():
    """List all stories in the database."""
    try:
        client = SupabaseClient()
        stories = client.get_all_stories()
        
        if not stories:
            logger.info("No stories found in the database.")
            return
            
        # Limit to 5 records
        stories = stories[:5]
        logger.info(f"Showing {len(stories)} of {len(stories)} stories:")
        
        # Prepare table data
        table_data = []
        for story in stories:
            row = [
                story.title,
                story.moral,
                f"{story.child_name} ({story.child_age})" if story.child_name else (story.child_id or "N/A"),
                story.model_used or "Unknown",
                story.language.value,
                story.story_length or "N/A",
                story.rating or "N/A",
                story.audio_file_url or "N/A",
                story.audio_provider or "N/A"
            ]
            table_data.append(row)
        
        headers = ["Title", "Moral", "Child", "Model", "Language", "Length", "Rating", "Audio URL", "Provider"]
        logger.info("\n" + tabulate(table_data, headers=headers, tablefmt="grid"))
            
    except Exception as e:
        logger.error(f"Error listing stories: {e}", exc_info=True)


@cli.command()
@click.argument('child_name')
def list_child_stories(child_name):
    """List all stories for a specific child."""
    try:
        client = SupabaseClient()
        stories = client.get_stories_by_child(child_name)
        
        if not stories:
            logger.info(f"No stories found for child '{child_name}'.")
            return
            
        # Limit to 5 records
        stories = stories[:5]
        logger.info(f"Showing {len(stories)} of {len(stories)} stories for child '{child_name}':")
        
        # Prepare table data
        table_data = []
        for story in stories:
            row = [
                story.title,
                story.moral,
                story.model_used or "Unknown",
                story.language.value,
                story.story_length or "N/A",
                story.rating or "N/A",
                story.audio_file_url or "N/A",
                story.audio_provider or "N/A"
            ]
            table_data.append(row)
        
        headers = ["Title", "Moral", "Model", "Language", "Length", "Rating", "Audio URL", "Provider"]
        logger.info("\n" + tabulate(table_data, headers=headers, tablefmt="grid"))
            
    except Exception as e:
        logger.error(f"Error listing stories: {e}", exc_info=True)


@cli.command()
@click.argument('language')
def list_language_stories(language):
    """List all stories in a specific language."""
    try:
        client = SupabaseClient()
        stories = client.get_stories_by_language(language)
        
        if not stories:
            logger.info(f"No stories found in language '{language}'.")
            return
            
        # Limit to 5 records
        stories = stories[:5]
        logger.info(f"Showing {len(stories)} of {len(stories)} stories in {language}:")
        
        # Prepare table data
        table_data = []
        for story in stories:
            row = [
                story.title,
                story.moral,
                f"{story.child_name} ({story.child_age})" if story.child_name else "N/A",
                story.model_used or "Unknown",
                story.language.value,
                story.story_length or "N/A",
                story.rating or "N/A",
                story.audio_file_url or "N/A",
                story.audio_provider or "N/A"
            ]
            table_data.append(row)
        
        headers = ["Title", "Moral", "Child", "Model", "Language", "Length", "Rating", "Audio URL", "Provider"]
        logger.info("\n" + tabulate(table_data, headers=headers, tablefmt="grid"))
            
    except Exception as e:
        logger.error(f"Error listing stories: {e}", exc_info=True)


@cli.command()
@click.argument('story_id')
@click.argument('rating', type=int)
def rate_story(story_id, rating):
    """Rate a story with a score from 1 to 10."""
    if not 1 <= rating <= 10:
        logger.error("Rating must be between 1 and 10.")
        return
        
    try:
        client = SupabaseClient()
        rating_request = StoryRatingRequest(rating=rating)
        updated_story = client.update_story_rating(story_id, rating_request.rating)
        
        if updated_story:
            logger.info(f"Story '{updated_story.title}' rated successfully with {rating}/10.")
        else:
            logger.warning(f"No story found with ID {story_id}.")
            
    except Exception as e:
        logger.error(f"Error rating story: {e}", exc_info=True)


@cli.command()
@click.argument('story_id')
def delete_story(story_id):
    """Delete a story by ID."""
    try:
        client = SupabaseClient()
        deleted = client.delete_story(story_id)
        
        if deleted:
            logger.info(f"Story with ID {story_id} deleted successfully.")
        else:
            logger.warning(f"No story found with ID {story_id}.")
            
    except Exception as e:
        logger.error(f"Error deleting story: {e}", exc_info=True)


@cli.command()
def list_all_children():
    """List all children in the database."""
    try:
        client = SupabaseClient()
        children = client.get_all_children()
        
        if not children:
            logger.info("No children found in the database.")
            return
            
        # Limit to 5 records
        children = children[:5]
        logger.info(f"Showing {len(children)} of {len(children)} children:")
        
        # Prepare table data
        table_data = []
        for child in children:
            row = [
                child.name,
                child.age,
                child.gender,
                ", ".join(child.interests) if child.interests else "N/A",
                child.id,
                child.created_at
            ]
            table_data.append(row)
        
        headers = ["Name", "Age", "Gender", "Interests", "ID", "Created"]
        logger.info("\n" + tabulate(table_data, headers=headers, tablefmt="grid"))
            
    except Exception as e:
        logger.error(f"Error listing children: {e}", exc_info=True)



@click.argument('child_id')
def delete_child(child_id):
    """Delete a child by ID."""
    try:
        client = SupabaseClient()
        deleted = client.delete_child(child_id)
        
        if deleted:
            logger.info(f"Child with ID {child_id} deleted successfully.")
        else:
            logger.warning(f"No child found with ID {child_id}.")
            
    except Exception as e:
        logger.error(f"Error deleting child: {e}", exc_info=True)


if __name__ == "__main__":
    cli()