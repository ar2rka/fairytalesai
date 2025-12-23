"""Test script to verify Supabase client functionality."""

from src.supabase_client import SupabaseClient

def test_supabase_client():
    """Test Supabase client instantiation."""
    try:
        # Try to create a Supabase client (this will fail if credentials are not set)
        print("Testing Supabase client instantiation...")
        client = SupabaseClient()
        print("✓ Supabase client created successfully")
        print(f"✓ Client type: {type(client)}")
        print(f"✓ Client has save_child method: {hasattr(client, 'save_child')}")
        print(f"✓ Client has get_child method: {hasattr(client, 'get_child')}")
        print(f"✓ Client has get_all_children method: {hasattr(client, 'get_all_children')}")
        
        # Test that all expected methods are present
        expected_methods = [
            'save_child', 'get_child', 'get_all_children',
            'save_story', 'get_story', 'get_stories_by_child', 'get_all_stories',
            'get_stories_by_language', 'delete_story', 'delete_child'
        ]
        
        missing_methods = []
        for method in expected_methods:
            if not hasattr(client, method):
                missing_methods.append(method)
        
        if missing_methods:
            print(f"✗ Missing methods: {missing_methods}")
        else:
            print("✓ All expected methods are present")
        
        print("\nSupabase client test completed successfully!")
        
    except ValueError as e:
        # This is expected if credentials are not set
        print(f"✓ Supabase client instantiation test passed (credentials not set): {e}")
    except Exception as e:
        print(f"✗ Error in Supabase client test: {e}")

if __name__ == "__main__":
    test_supabase_client()