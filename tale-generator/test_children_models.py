"""Test script to verify child entity models and functionality without database."""

from src.models import ChildDB, StoryDB, ChildProfile, Gender, Language
from datetime import datetime

def test_children_models():
    """Test child entity models."""
    try:
        # Test ChildDB model
        print("Testing ChildDB model...")
        child_db = ChildDB(
            id="test-id-123",
            name="Test Child",
            age=7,
            gender="male",
            interests=["testing", "programming", "games"],
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        print(f"✓ ChildDB created: {child_db.name}, Age: {child_db.age}")
        
        # Test ChildProfile model
        print("Testing ChildProfile model...")
        child_profile = ChildProfile(
            name="Profile Child",
            age=8,
            gender=Gender.FEMALE,
            interests=["reading", "art", "music"]
        )
        print(f"✓ ChildProfile created: {child_profile.name}, Gender: {child_profile.gender}")
        
        # Test StoryDB model with child reference
        print("Testing StoryDB model with child reference...")
        story_db = StoryDB(
            id="story-id-456",
            title="Test Story",
            content="Once upon a time...",
            moral="kindness",
            child_id=child_db.id,
            child_name=child_db.name,
            child_age=child_db.age,
            child_gender=child_db.gender,
            child_interests=child_db.interests,
            language=Language.ENGLISH,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        print(f"✓ StoryDB created with child reference: {story_db.title}")
        print(f"  Child ID: {story_db.child_id}")
        print(f"  Child Name: {story_db.child_name}")
        
        # Test model serialization
        print("Testing model serialization...")
        child_dict = child_db.model_dump()
        story_dict = story_db.model_dump()
        print(f"✓ ChildDB serialized to dict with {len(child_dict)} fields")
        print(f"✓ StoryDB serialized to dict with {len(story_dict)} fields")
        
        print("\nAll child entity model tests passed!")
        
    except Exception as e:
        print(f"Error in child entity model tests: {e}")

if __name__ == "__main__":
    test_children_models()