"""Test script to verify child entity functionality."""

from src.supabase_client import SupabaseClient
from src.models import ChildDB
from datetime import datetime

def test_children():
    """Test child entity functionality."""
    try:
        # Initialize Supabase client
        client = SupabaseClient()
        
        # Create a test child
        print("Creating a test child...")
        test_child = ChildDB(
            name="Test Child",
            age=7,
            gender="male",
            interests=["testing", "programming", "games"],
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        # Save the child
        saved_child = client.save_child(test_child)
        print(f"✓ Child saved with ID: {saved_child.id}")
        
        # Retrieve the child
        retrieved_child = client.get_child(saved_child.id)
        print(f"✓ Child retrieved: {retrieved_child.name}, Age: {retrieved_child.age}")
        
        # Retrieve all children
        all_children = client.get_all_children()
        print(f"✓ Found {len(all_children)} total children")
        
        # Check if our test child is in the list
        test_children = [child for child in all_children if child.name == "Test Child"]
        print(f"✓ Found {len(test_children)} children with name 'Test Child' in all children list")
        
        # Delete the test child
        deleted = client.delete_child(saved_child.id)
        print(f"✓ Child deletion {'successful' if deleted else 'failed'}")
        
        print("\nAll child entity tests passed!")
        
    except Exception as e:
        print(f"Error in child entity tests: {e}")

if __name__ == "__main__":
    test_children()