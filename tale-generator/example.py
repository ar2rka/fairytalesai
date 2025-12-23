"""Example script demonstrating how to use the Tale Generator API."""

import requests
import json
from datetime import datetime

def generate_and_save_child_story():
    """Generate a story for a child and save it using the API."""
    base_url = "http://localhost:8000"
    
    # 1. Generate a story
    print("Generating a story...")
    generate_url = f"{base_url}/api/v1/stories/generate"
    
    payload = {
        "child_id": "example-child-id",  # This would be a real child ID from the database
        "story_type": "child",
        "moral": "kindness",
        "language": "en",
        "story_length": 5
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        # Generate the story
        response = requests.post(generate_url, data=json.dumps(payload), headers=headers)
        
        if response.status_code == 200:
            story_data = response.json()
            print("Story generated successfully!")
            print(f"Title: {story_data['title']}")
            print(f"Moral: {story_data['moral']}")
            print("Story content preview:", story_data['content'][:100] + "...")
            
            print("\nStory generated and saved successfully!")
            print(f"Story ID: {story_data.get('id', 'N/A')}")
                
        else:
            print(f"Error generating story: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error occurred: {e}")

def retrieve_child_stories():
    """Retrieve all stories for a specific child."""
    print("\nNote: Story retrieval is now handled through the Supabase client in the frontend.")
    print("See the frontend code for examples of how to retrieve stories.")

if __name__ == "__main__":
    generate_and_save_child_story()
    retrieve_child_stories()