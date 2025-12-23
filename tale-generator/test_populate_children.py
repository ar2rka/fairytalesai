"""Test script to verify child population functionality."""

from src.supabase_client import SupabaseClient
from src.models import ChildDB
from datetime import datetime

def test_populate_children():
    """Test child population functionality."""
    try:
        # Sample children data
        CHILDREN = [
            {
                "name": "Emma",
                "age": 6,
                "gender": "female",
                "interests": ["unicorns", "fairies", "princesses"]
            },
            {
                "name": "Liam",
                "age": 7,
                "gender": "male",
                "interests": ["dinosaurs", "trucks", "robots"]
            }
        ]
        
        # Initialize Supabase client
        client = SupabaseClient()
        
        print("Testing child population...")
        
        # Save children to database
        saved_children = []
        for child_data in CHILDREN:
            try:
                child_db = ChildDB(
                    name=child_data["name"],
                    age=child_data["age"],
                    gender=child_data["gender"],
                    interests=child_data["interests"],
                    created_at=datetime.now().isoformat(),
                    updated_at=datetime.now().isoformat()
                )
                saved_child = client.save_child(child_db)
                saved_children.append(saved_child)
                print(f"  ✓ Saved child: {saved_child.name} with ID: {saved_child.id}")
            except Exception as e:
                print(f"  ✗ Error saving child {child_data['name']}: {e}")
        
        print(f"\nSuccessfully saved {len(saved_children)} children!")
        
        # Test retrieving children
        try:
            all_children = client.get_all_children()
            print(f"✓ Retrieved {len(all_children)} children from database")
            
            # Test retrieving by filtering all children for name
            all_children_for_emma = client.get_all_children()
            emma_children = [child for child in all_children_for_emma if child.name == "Emma"]
            print(f"✓ Found {len(emma_children)} children named Emma")
            
            if emma_children:
                child = emma_children[0]
                print(f"  - Child ID: {child.id}")
                print(f"  - Child Age: {child.age}")
                print(f"  - Child Gender: {child.gender}")
                print(f"  - Child Interests: {child.interests}")
                
        except Exception as e:
            print(f"✗ Error retrieving children: {e}")
        
        # Clean up - delete the test children
        for child in saved_children:
            try:
                deleted = client.delete_child(child.id)
                print(f"✓ Deleted child {child.name}: {deleted}")
            except Exception as e:
                print(f"✗ Error deleting child {child.name}: {e}")
        
        print("\nChild population test completed successfully!")
        
    except Exception as e:
        print(f"Error in child population test: {e}")

if __name__ == "__main__":
    test_populate_children()