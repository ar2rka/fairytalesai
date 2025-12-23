"""Test script for the tale generator API."""

import requests
import json

def test_api():
    """Test the tale generator API endpoints."""
    base_url = "http://localhost:8000"
    
    # Test root endpoint
    print("Testing root endpoint...")
    response = requests.get(f"{base_url}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()
    
    # Test health endpoint
    print("Testing health endpoint...")
    response = requests.get(f"{base_url}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()
    
    # Test story generation endpoint (this will fail without API key)
    print("Testing story generation endpoint...")
    story_request = {
        "child": {
            "name": "Emma",
            "age": 6,
            "gender": "female",
            "interests": ["unicorns", "fairies", "princesses"]
        },
        "moral": "kindness"
    }
    
    try:
        response = requests.post(
            f"{base_url}/api/v1/stories/generate",
            json=story_request
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_api()