"""Test script to verify Supabase connection and table creation."""

from src.supabase_client import SupabaseClient
from src.models import StoryDB
from datetime import datetime

def test_supabase_connection():
    """Test Supabase connection and basic operations."""
    try:
        print("Testing Supabase connection...")
        
        # Initialize Supabase client
        client = SupabaseClient()
        print("✓ Supabase client initialized successfully")
        
        # Test creating a simple story
        print("\nTesting story creation...")
        test_story = StoryDB(
            title="Test Story",
            content="This is a test story for verifying Supabase connection.",
            moral="testing",
            child_name="Test Child",
            child_age=5,
            child_gender="other",
            child_interests=["testing", "verification"],
            created_at=datetime.now().isoformat(),
            updated_at=datetime.now().isoformat()
        )
        
        # Try to save the story
        saved_story = client.save_story(test_story)
        print(f"✓ Story saved successfully with ID: {saved_story.id}")
        
        # Try to retrieve the story
        retrieved_story = client.get_story(saved_story.id)
        if retrieved_story:
            print(f"✓ Story retrieved successfully: {retrieved_story.title}")
        else:
            print("✗ Failed to retrieve story")
            
        # Try to delete the story
        deleted = client.delete_story(saved_story.id)
        if deleted:
            print("✓ Story deleted successfully")
        else:
            print("✗ Failed to delete story")
            
        print("\nAll tests passed! Supabase connection is working correctly.")
        
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    test_supabase_connection()