"""Test script for the Supabase integration."""

import requests
import json
from datetime import datetime

def test_supabase_integration():
    """Test the Supabase integration endpoints."""
    base_url = "http://localhost:8000"
    
    # Example story data
    story_data = {
        "title": "The Kind Little Dragon",
        "content": "Once upon a time, there was a kind little dragon...",
        "moral": "kindness",
        "child_name": "Emma",
        "child_age": 6,
        "child_gender": "female",
        "child_interests": ["dragons", "castles", "magic"],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Test saving a story (this will fail without Supabase credentials)
    print("Testing story saving...")
    try:
        response = requests.post(
            f"{base_url}/api/v1/save-story",
            json=story_data
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")
    
    # Test retrieving all stories (this will fail without Supabase credentials)
    print("\nTesting story retrieval...")
    try:
        response = requests.get(f"{base_url}/api/v1/stories")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_supabase_integration()