#!/usr/bin/env python3
"""Check story types in the database."""

from src.supabase_client import SupabaseClient

def check_story_types():
    """Check the distribution of story types."""
    client = SupabaseClient()
    stories = client.get_all_stories()
    
    story_types = {}
    for story in stories:
        story_type = getattr(story, 'story_type', 'unknown')
        story_types[story_type] = story_types.get(story_type, 0) + 1
    
    print("Story types distribution:", story_types)
    
    # Check for stories with hero information
    hero_stories = [s for s in stories if getattr(s, 'hero_id', None)]
    print(f"Stories with hero_id: {len(hero_stories)}")
    
    # Show some examples
    for story in stories[-5:]:
        print(f"Title: {story.title[:50]}..., Type: {getattr(story, 'story_type', 'unknown')}")

if __name__ == "__main__":
    check_story_types()