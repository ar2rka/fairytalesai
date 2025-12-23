"""Test script to verify language support in the API."""

import requests
import json

def test_language_api():
    """Test the language support in the API."""
    base_url = "http://localhost:8000"
    
    # Test English story generation request
    print("Testing English story generation...")
    english_story_request = {
        "child": {
            "name": "Emma",
            "age": 6,
            "gender": "female",
            "interests": ["unicorns", "fairies", "princesses"]
        },
        "moral": "kindness",
        "language": "en"
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/v1/stories/generate",
            json=english_story_request
        )
        print(f"English story generation - Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Title: {data['title']}")
            print(f"Language: {data['language']}")
            print("✓ English story generation successful")
        else:
            print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error in English story generation: {e}")
    
    print()
    
    # Test Russian story generation request
    print("Testing Russian story generation...")
    russian_story_request = {
        "child": {
            "name": "Alex",
            "age": 7,
            "gender": "male",
            "interests": ["dinosaurs", "space", "robots"]
        },
        "moral": "bravery",
        "language": "ru"
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/v1/stories/generate",
            json=russian_story_request
        )
        print(f"Russian story generation - Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Title: {data['title']}")
            print(f"Language: {data['language']}")
            print("✓ Russian story generation successful")
        else:
            print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error in Russian story generation: {e}")

if __name__ == "__main__":
    test_language_api()