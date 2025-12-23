"""Test script for the new story generation endpoint with Russian language stories."""

import requests
import json
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8000/api/v1"

def test_child_story_russian():
    """Test generating a child-only story in Russian."""
    print("\n=== Testing Child Story Generation (Russian) ===")
    
    # First, create a test child
    child_data = {
        "name": "Денис",
        "age": 7,
        "gender": "male",
        "interests": ["космос", "роботы", "динозавры"],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Create child
    print("Creating test child...")
    child_response = requests.post(f"{BASE_URL}/children", json=child_data)
    if child_response.status_code != 200:
        print(f"Failed to create child: {child_response.status_code}")
        print(child_response.text)
        return
    
    child = child_response.json()
    child_id = child["id"]
    print(f"Child created with ID: {child_id}")
    
    # Generate child story
    story_request = {
        "language": "ru",
        "child_id": child_id,
        "story_type": "child",
        "moral": "доброта",
        "story_length": 3
    }
    
    print(f"\nGenerating child story with request: {json.dumps(story_request, indent=2)}")
    response = requests.post(f"{BASE_URL}/stories/generate", json=story_request)
    
    if response.status_code == 200:
        story = response.json()
        print(f"\n✓ Success! Story generated:")
        print(f"  - ID: {story['id']}")
        print(f"  - Title: {story['title']}")
        print(f"  - Type: {story['story_type']}")
        print(f"  - Child: {story['child']['name']}")
        print(f"  - Moral: {story['moral']}")
        print(f"  - Length: {story['story_length']} minutes")
        print(f"  - Content preview: {story['content'][:100]}...")
    else:
        print(f"\n✗ Failed: {response.status_code}")
        print(response.json())

def test_hero_story_russian():
    """Test generating a hero story in Russian."""
    print("\n=== Testing Hero Story Generation (Russian) ===")
    
    # First, create a test child
    child_data = {
        "name": "Анна",
        "age": 6,
        "gender": "female",
        "interests": ["котята", "цветы", "танцы"],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Create child
    print("Creating test child...")
    child_response = requests.post(f"{BASE_URL}/children", json=child_data)
    if child_response.status_code != 200:
        print(f"Failed to create child: {child_response.status_code}")
        print(child_response.text)
        return
    
    child = child_response.json()
    child_id = child["id"]
    print(f"Child created with ID: {child_id}")
    
    # Get a hero for the story (using Supabase client directly since there's no API endpoint)
    print("Getting heroes from database...")
    try:
        from src.supabase_client import SupabaseClient
        supabase_client = SupabaseClient()
        all_heroes = supabase_client.get_all_heroes()
        
        if not all_heroes:
            print("No heroes available in the database")
            return
        
        # Filter Russian heroes
        russian_heroes = [h for h in all_heroes if h.language == "ru"]
        if not russian_heroes:
            print("No Russian heroes available in the database")
            return
        
        hero = russian_heroes[0]
        hero_id = hero.id
        print(f"Selected hero: {hero.name} (ID: {hero_id})")
    except Exception as e:
        print(f"Failed to get heroes: {str(e)}")
        return
    
    # Generate hero story
    story_request = {
        "language": "ru",
        "child_id": child_id,
        "story_type": "hero",
        "hero_id": hero_id,
        "moral": "храбрость",
        "story_length": 4
    }
    
    print(f"\nGenerating hero story with request: {json.dumps(story_request, indent=2)}")
    response = requests.post(f"{BASE_URL}/stories/generate", json=story_request)
    
    if response.status_code == 200:
        story = response.json()
        print(f"\n✓ Success! Hero story generated:")
        print(f"  - ID: {story['id']}")
        print(f"  - Title: {story['title']}")
        print(f"  - Type: {story['story_type']}")
        print(f"  - Child: {story['child']['name']}")
        print(f"  - Hero: {story['hero']['name']}")
        print(f"  - Moral: {story['moral']}")
        print(f"  - Length: {story['story_length']} minutes")
        print(f"  - Content preview: {story['content'][:100]}...")
    else:
        print(f"\n✗ Failed: {response.status_code}")
        print(response.json())

def test_combined_story_russian():
    """Test generating a combined story in Russian."""
    print("\n=== Testing Combined Story Generation (Russian) ===")
    
    # First, create a test child
    child_data = {
        "name": "Максим",
        "age": 8,
        "gender": "male",
        "interests": ["машины", "самолеты", "космос"],
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Create child
    print("Creating test child...")
    child_response = requests.post(f"{BASE_URL}/children", json=child_data)
    if child_response.status_code != 200:
        print(f"Failed to create child: {child_response.status_code}")
        print(child_response.text)
        return
    
    child = child_response.json()
    child_id = child["id"]
    print(f"Child created with ID: {child_id}")
    
    # Get a hero for the story (using Supabase client directly since there's no API endpoint)
    print("Getting heroes from database...")
    try:
        from src.supabase_client import SupabaseClient
        supabase_client = SupabaseClient()
        all_heroes = supabase_client.get_all_heroes()
        
        if not all_heroes:
            print("No heroes available in the database")
            return
        
        # Filter Russian heroes
        russian_heroes = [h for h in all_heroes if h.language == "ru"]
        if not russian_heroes:
            print("No Russian heroes available in the database")
            return
        
        hero = russian_heroes[0]
        hero_id = hero.id
        print(f"Selected hero: {hero.name} (ID: {hero_id})")
    except Exception as e:
        print(f"Failed to get heroes: {str(e)}")
        return
    
    # Generate combined story
    story_request = {
        "language": "ru",
        "child_id": child_id,
        "story_type": "combined",
        "hero_id": hero_id,
        "moral": "дружба",
        "story_length": 5
    }
    
    print(f"\nGenerating combined story with request: {json.dumps(story_request, indent=2)}")
    response = requests.post(f"{BASE_URL}/stories/generate", json=story_request)
    
    if response.status_code == 200:
        story = response.json()
        print(f"\n✓ Success! Combined story generated:")
        print(f"  - ID: {story['id']}")
        print(f"  - Title: {story['title']}")
        print(f"  - Type: {story['story_type']}")
        print(f"  - Child: {story['child']['name']}")
        print(f"  - Hero: {story['hero']['name']}")
        print(f"  - Relationship: {story['relationship_description']}")
        print(f"  - Moral: {story['moral']}")
        print(f"  - Length: {story['story_length']} minutes")
        print(f"  - Content preview: {story['content'][:100]}...")
    else:
        print(f"\n✗ Failed: {response.status_code}")
        print(response.json())

def test_validation_errors_russian():
    """Test validation error handling for Russian stories."""
    print("\n=== Testing Validation Errors (Russian) ===")
    
    # Test invalid language
    print("\n1. Testing invalid language...")
    response = requests.post(f"{BASE_URL}/stories/generate", json={
        "language": "fr",
        "child_id": "123e4567-e89b-12d3-a456-426614174000",
        "story_type": "child"
    })
    print(f"   Status: {response.status_code} (expected 400)")
    if response.status_code == 400:
        print(f"   ✓ Correct error: {response.json()['detail']}")
    
    # Test invalid story type
    print("\n2. Testing invalid story type...")
    response = requests.post(f"{BASE_URL}/stories/generate", json={
        "language": "ru",
        "child_id": "123e4567-e89b-12d3-a456-426614174000",
        "story_type": "invalid"
    })
    print(f"   Status: {response.status_code} (expected 400)")
    if response.status_code == 400:
        print(f"   ✓ Correct error: {response.json()['detail']}")
    
    # Test missing hero_id for hero story
    print("\n3. Testing missing hero_id for hero story...")
    response = requests.post(f"{BASE_URL}/stories/generate", json={
        "language": "ru",
        "child_id": "123e4567-e89b-12d3-a456-426614174000",
        "story_type": "hero"
    })
    print(f"   Status: {response.status_code} (expected 400)")
    if response.status_code == 400:
        print(f"   ✓ Correct error: {response.json()['detail']}")
    
    # Test child not found
    print("\n4. Testing child not found...")
    response = requests.post(f"{BASE_URL}/stories/generate", json={
        "language": "ru",
        "child_id": "00000000-0000-0000-0000-000000000000",
        "story_type": "child"
    })
    print(f"   Status: {response.status_code} (expected 404)")
    if response.status_code == 404:
        print(f"   ✓ Correct error: {response.json()['detail']}")

def test_endpoint_structure():
    """Test endpoint structure and documentation."""
    print("\n=== Testing Endpoint Structure ===")
    
    # Check if endpoint is registered
    print("\nChecking API documentation...")
    response = requests.get("http://localhost:8000/docs")
    if response.status_code == 200:
        print("✓ API documentation accessible at /docs")
    
    # Check OpenAPI schema
    response = requests.get("http://localhost:8000/openapi.json")
    if response.status_code == 200:
        openapi = response.json()
        if "/api/v1/stories/generate" in openapi.get("paths", {}):
            print("✓ Endpoint /api/v1/stories/generate is registered")
            endpoint_info = openapi["paths"]["/api/v1/stories/generate"]
            if "post" in endpoint_info:
                print("✓ POST method is available")
                post_info = endpoint_info["post"]
                print(f"  - Summary: {post_info.get('summary', 'N/A')}")
                print(f"  - Request body: {list(post_info.get('requestBody', {}).get('content', {}).keys())}")
                print(f"  - Response: {list(post_info.get('responses', {}).get('200', {}).get('content', {}).keys())}")
        else:
            print("✗ Endpoint not found in OpenAPI schema")
    else:
        print("✗ Failed to fetch OpenAPI schema")

if __name__ == "__main__":
    print("=" * 60)
    print("Russian Story Generation Endpoint Test Suite")
    print("=" * 60)
    print("\nMake sure the server is running on http://localhost:8000")
    print("Run with: uv run uvicorn main:app --reload")
    
    try:
        # Test endpoint structure first
        test_endpoint_structure()
        
        # Test validation errors
        test_validation_errors_russian()
        
        # Test actual story generation
        print("\n" + "=" * 60)
        input("Press Enter to test actual story generation (this will call OpenRouter API)...")
        test_child_story_russian()
        
        print("\n" + "=" * 60)
        input("Press Enter to test hero story generation (this will call OpenRouter API)...")
        test_hero_story_russian()
        
        print("\n" + "=" * 60)
        input("Press Enter to test combined story generation (this will call OpenRouter API)...")
        test_combined_story_russian()
        
        print("\n" + "=" * 60)
        print("Tests completed!")
        print("=" * 60)
        
    except requests.exceptions.ConnectionError:
        print("\n✗ Error: Could not connect to the server.")
        print("Please make sure the server is running on http://localhost:8000")
    except Exception as e:
        print(f"\n✗ Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()