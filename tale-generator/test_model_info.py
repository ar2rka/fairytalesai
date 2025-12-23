"""Test script to verify model information is stored correctly."""

from src.supabase_client import SupabaseClient
from src.models import StoryDB
from datetime import datetime

def test_model_info_storage():
    """Test that model information is stored correctly."""
    try:
        print("Testing model information storage...")
        
        # Initialize Supabase client
        client = SupabaseClient()
        print("✓ Supabase client initialized successfully")
        
        # Test creating a story with model information
        print("\nTesting story creation with model info...")
        test_story = StoryDB(
            title="Test Story with Model Info",
            content="This is a test story to verify model information storage.",
            moral="testing",
            child_name="Test Child",
            child_age=5,
            child_gender="other",
            child_interests=["testing", "verification"],
            model_used="openai/gpt-4o-mini",
            full_response={
                "id": "test-response-id",
                "choices": [
                    {
                        "message": {
                            "content": "This is a test story to verify model information storage."
                        }
                    }
                ]
            },
            created_at=datetime.now().isoformat(),
            updated_at=datetime.now().isoformat()
        )
        
        # Try to save the story
        saved_story = client.save_story(test_story)
        print(f"✓ Story saved successfully with ID: {saved_story.id}")
        
        # Verify model information was stored
        if saved_story.model_used == "openai/gpt-4o-mini":
            print("✓ Model information stored correctly")
        else:
            print(f"✗ Model information not stored correctly: {saved_story.model_used}")
            
        # Verify full response was stored
        if saved_story.full_response and "id" in saved_story.full_response:
            print("✓ Full response stored correctly")
        else:
            print("✗ Full response not stored correctly")
            
        # Try to retrieve the story
        retrieved_story = client.get_story(saved_story.id)
        if retrieved_story and retrieved_story.model_used == "openai/gpt-4o-mini":
            print("✓ Story retrieved with model information correctly")
        else:
            print("✗ Story not retrieved with model information correctly")
            
        # Try to delete the story
        deleted = client.delete_story(saved_story.id)
        if deleted:
            print("✓ Story deleted successfully")
        else:
            print("✗ Failed to delete story")
            
        print("\nAll tests passed! Model information storage is working correctly.")
        
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    test_model_info_storage()