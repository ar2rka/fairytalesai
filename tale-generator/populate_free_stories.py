#!/usr/bin/env python3
"""Script to populate free_stories table with existing stories from the database."""

import os
import sys
import logging
from typing import Dict, List
from collections import defaultdict
from dotenv import load_dotenv

# Add the src directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__)))

from src.supabase_client import SupabaseClient
from src.infrastructure.persistence.models import FreeStoryDB, StoryDB

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


def age_to_category(age: int) -> str:
    """Convert child age to age category.
    
    Args:
        age: Child age
        
    Returns:
        Age category: '2-3', '3-5', or '5-7'
    """
    if age <= 3:
        return '2-3'
    elif age <= 5:
        return '3-5'
    else:
        return '5-7'


def select_stories_for_free(client: SupabaseClient) -> Dict[str, List[StoryDB]]:
    """Select stories from database, grouped by age category.
    
    Args:
        client: Supabase client
        
    Returns:
        Dictionary mapping age category to list of stories
    """
    logger.info("Fetching all stories from database...")
    all_stories = client.get_all_stories()
    logger.info(f"Found {len(all_stories)} total stories")
    
    # Group stories by age category
    stories_by_category: Dict[str, List[StoryDB]] = defaultdict(list)
    
    for story in all_stories:
        if not story.child_age or not story.title or not story.content:
            logger.debug(f"Skipping story {story.id}: missing required fields")
            continue
        
        age_category = age_to_category(story.child_age)
        stories_by_category[age_category].append(story)
    
    logger.info(f"Stories by category: {dict((k, len(v)) for k, v in stories_by_category.items())}")
    
    return stories_by_category


def insert_free_stories(client: SupabaseClient, stories_by_category: Dict[str, List[StoryDB]]) -> None:
    """Insert selected stories into free_stories table.
    
    Args:
        client: Supabase client
        stories_by_category: Dictionary mapping age category to list of stories
    """
    stories_to_insert = []
    
    # Select 2 stories per category
    for category in ['2-3', '3-5', '5-7']:
        stories = stories_by_category.get(category, [])
        
        if len(stories) == 0:
            logger.warning(f"No stories found for category {category}")
            continue
        
        # Take first 2 stories (or less if not available)
        selected = stories[:2]
        logger.info(f"Selected {len(selected)} stories for category {category}")
        
        for story in selected:
            # Extract language value (handle both enum and string)
            language_value = story.language
            if hasattr(language_value, 'value'):
                language_value = language_value.value
            if not language_value or language_value not in ['en', 'ru']:
                language_value = 'en'
            
            # Create FreeStoryDB from StoryDB
            free_story = FreeStoryDB(
                title=story.title,
                content=story.content,
                age_category=category,
                language=language_value,
                is_active=True
            )
            stories_to_insert.append(free_story)
            logger.info(f"  - {story.title[:50]}... (language: {free_story.language})")
    
    if not stories_to_insert:
        logger.error("No stories to insert!")
        return
    
    logger.info(f"\nInserting {len(stories_to_insert)} stories into free_stories table...")
    
    # Insert stories into database
    inserted_count = 0
    for free_story in stories_to_insert:
        try:
            # Convert to dict for insertion
            story_dict = free_story.model_dump(exclude={'id', 'created_at'})
            
            # Insert into database
            response = client.client.table("free_stories").insert(story_dict).execute()
            
            if response.data:
                inserted_count += 1
                logger.info(f"  ✓ Inserted: {free_story.title[:50]}...")
            else:
                logger.error(f"  ✗ Failed to insert: {free_story.title[:50]}...")
        except Exception as e:
            logger.error(f"  ✗ Error inserting {free_story.title[:50]}...: {str(e)}")
    
    logger.info(f"\nSuccessfully inserted {inserted_count} out of {len(stories_to_insert)} stories")


def main():
    """Main function."""
    try:
        logger.info("=" * 60)
        logger.info("Populating free_stories table")
        logger.info("=" * 60)
        
        # Initialize client
        client = SupabaseClient()
        
        # Select stories
        stories_by_category = select_stories_for_free(client)
        
        # Insert stories
        insert_free_stories(client, stories_by_category)
        
        logger.info("\n" + "=" * 60)
        logger.info("Done!")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"Error populating free stories: {str(e)}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()

