"""Integration tests for hero and combined story generation."""

import pytest
import requests
import os
from datetime import datetime

# Test configuration
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
TEST_TIMEOUT = 120  # 2 minutes for story generation


class TestHeroStoryGeneration:
    """Test suite for hero-only story generation."""
    
    @pytest.fixture
    def test_child_id(self):
        """Create a test child profile."""
        # This should be replaced with actual child creation
        # For now, using a placeholder
        return "test-child-uuid"
    
    @pytest.fixture
    def test_hero_id_en(self):
        """Get an English hero ID for testing."""
        # This should query the database for an English hero
        return "test-hero-en-uuid"
    
    @pytest.fixture
    def test_hero_id_ru(self):
        """Get a Russian hero ID for testing."""
        return "test-hero-ru-uuid"
    
    def test_generate_hero_story_english(self, test_child_id, test_hero_id_en):
        """Test generating a hero story in English."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "hero",
            "hero_id": test_hero_id_en,
            "story_length": 5,
            "moral": "bravery"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 200, f"Failed: {response.text}"
        
        story_data = response.json()
        
        # Validate response structure
        assert "id" in story_data
        assert "title" in story_data
        assert "content" in story_data
        assert story_data["story_type"] == "hero"
        assert story_data["language"] == "en"
        assert story_data["moral"] == "bravery"
        assert story_data["hero"]["id"] == test_hero_id_en
        
        # Validate hero information is present
        assert "hero" in story_data
        assert "name" in story_data["hero"]
        assert "gender" in story_data["hero"]
        assert "appearance" in story_data["hero"]
        
        print(f"✓ Hero story generated: {story_data['title']}")
        print(f"  Hero: {story_data['hero']['name']}")
        print(f"  Length: {len(story_data['content'])} characters")
    
    def test_generate_hero_story_russian(self, test_child_id, test_hero_id_ru):
        """Test generating a hero story in Russian."""
        request_data = {
            "language": "ru",
            "child_id": test_child_id,
            "story_type": "hero",
            "hero_id": test_hero_id_ru,
            "story_length": 5,
            "moral": "kindness"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 200, f"Failed: {response.text}"
        
        story_data = response.json()
        
        assert story_data["story_type"] == "hero"
        assert story_data["language"] == "ru"
        assert story_data["hero"]["id"] == test_hero_id_ru
        
        print(f"✓ Russian hero story generated: {story_data['title']}")
    
    def test_hero_story_missing_hero_id(self, test_child_id):
        """Test that hero story requires hero_id."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "hero",
            # Missing hero_id
            "story_length": 5,
            "moral": "courage"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 400
        error_data = response.json()
        assert "hero" in error_data["detail"].lower() or "required" in error_data["detail"].lower()
        
        print("✓ Validation correctly rejects hero story without hero_id")
    
    def test_hero_language_mismatch(self, test_child_id, test_hero_id_ru):
        """Test that hero language must match story language."""
        request_data = {
            "language": "en",  # English story
            "child_id": test_child_id,
            "story_type": "hero",
            "hero_id": test_hero_id_ru,  # Russian hero
            "story_length": 5,
            "moral": "honesty"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 400
        error_data = response.json()
        assert "language" in error_data["detail"].lower()
        
        print("✓ Validation correctly rejects language mismatch")


class TestCombinedStoryGeneration:
    """Test suite for combined (child + hero) story generation."""
    
    @pytest.fixture
    def test_child_id(self):
        """Create a test child profile."""
        return "test-child-uuid"
    
    @pytest.fixture
    def test_hero_id_en(self):
        """Get an English hero ID for testing."""
        return "test-hero-en-uuid"
    
    def test_generate_combined_story_english(self, test_child_id, test_hero_id_en):
        """Test generating a combined story in English."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "combined",
            "hero_id": test_hero_id_en,
            "story_length": 7,
            "moral": "teamwork"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 200, f"Failed: {response.text}"
        
        story_data = response.json()
        
        # Validate response structure
        assert story_data["story_type"] == "combined"
        assert story_data["language"] == "en"
        assert story_data["moral"] == "teamwork"
        
        # Validate both child and hero information present
        assert "child" in story_data
        assert story_data["child"]["id"] == test_child_id
        
        assert "hero" in story_data
        assert story_data["hero"]["id"] == test_hero_id_en
        
        # Validate relationship description
        assert "relationship_description" in story_data
        assert story_data["relationship_description"] is not None
        assert len(story_data["relationship_description"]) > 0
        
        print(f"✓ Combined story generated: {story_data['title']}")
        print(f"  Child: {story_data['child']['name']}")
        print(f"  Hero: {story_data['hero']['name']}")
        print(f"  Relationship: {story_data['relationship_description']}")
        print(f"  Length: {len(story_data['content'])} characters")
    
    def test_combined_story_relationship_description(self, test_child_id, test_hero_id_en):
        """Test that relationship description is properly generated."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "combined",
            "hero_id": test_hero_id_en,
            "story_length": 5,
            "moral": "friendship"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 200
        story_data = response.json()
        
        # Check relationship description format
        relationship = story_data["relationship_description"]
        child_name = story_data["child"]["name"]
        hero_name = story_data["hero"]["name"]
        
        # Should contain both names
        assert child_name in relationship
        assert hero_name in relationship
        
        print(f"✓ Relationship description validated: {relationship}")
    
    def test_combined_story_missing_hero_id(self, test_child_id):
        """Test that combined story requires hero_id."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "combined",
            # Missing hero_id
            "story_length": 5,
            "moral": "courage"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 400
        error_data = response.json()
        assert "hero" in error_data["detail"].lower() or "required" in error_data["detail"].lower()
        
        print("✓ Validation correctly rejects combined story without hero_id")
    
    def test_combined_story_content_includes_both_characters(self, test_child_id, test_hero_id_en):
        """Test that combined story content mentions both child and hero."""
        request_data = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "combined",
            "hero_id": test_hero_id_en,
            "story_length": 5,
            "moral": "cooperation"
        }
        
        response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=request_data,
            timeout=TEST_TIMEOUT
        )
        
        assert response.status_code == 200
        story_data = response.json()
        
        child_name = story_data["child"]["name"]
        hero_name = story_data["hero"]["name"]
        content = story_data["content"]
        
        # Both names should appear in the story content
        assert child_name in content, f"Child name '{child_name}' not found in story"
        assert hero_name in content, f"Hero name '{hero_name}' not found in story"
        
        # Count occurrences
        child_count = content.count(child_name)
        hero_count = content.count(hero_name)
        
        print(f"✓ Story mentions child {child_count} times and hero {hero_count} times")


class TestStoryTypeComparison:
    """Test suite comparing different story types."""
    
    @pytest.fixture
    def test_child_id(self):
        return "test-child-uuid"
    
    @pytest.fixture
    def test_hero_id_en(self):
        return "test-hero-en-uuid"
    
    def test_story_length_differences(self, test_child_id, test_hero_id_en):
        """Test that combined stories can be longer than child-only stories."""
        # Generate child story
        child_story_request = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "child",
            "story_length": 5,
            "moral": "kindness"
        }
        
        child_response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=child_story_request,
            timeout=TEST_TIMEOUT
        )
        
        # Generate combined story
        combined_story_request = {
            "language": "en",
            "child_id": test_child_id,
            "story_type": "combined",
            "hero_id": test_hero_id_en,
            "story_length": 7,
            "moral": "kindness"
        }
        
        combined_response = requests.post(
            f"{API_BASE_URL}/api/v1/stories/generate",
            json=combined_story_request,
            timeout=TEST_TIMEOUT
        )
        
        assert child_response.status_code == 200
        assert combined_response.status_code == 200
        
        child_story = child_response.json()
        combined_story = combined_response.json()
        
        print(f"✓ Child story length: {len(child_story['content'])} chars")
        print(f"✓ Combined story length: {len(combined_story['content'])} chars")
        
        # Combined stories typically should be longer due to more characters
        # But this depends on the requested story_length


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
