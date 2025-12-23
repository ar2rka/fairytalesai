"""Test script to verify language support functionality."""

from src.prompts import get_story_prompt
from src.models import Language, ChildProfile, Gender

def test_language_prompts():
    """Test that language-specific prompts are generated correctly."""
    # Test child data
    child = ChildProfile(
        name="Alex",
        age=7,
        gender=Gender.MALE,
        interests=["dinosaurs", "space", "robots"]
    )
    
    moral = "bravery"
    
    # Test English prompt
    english_prompt = get_story_prompt(child, moral, Language.ENGLISH)
    print("English Prompt:")
    print("=" * 50)
    print(english_prompt)
    print()
    
    # Verify English prompt contains key elements
    assert "Create a bedtime story" in english_prompt
    assert "Alex" in english_prompt
    assert "dinosaurs" in english_prompt
    assert "bravery" in english_prompt
    assert "English" in english_prompt
    print("✓ English prompt contains all required elements")
    
    # Test Russian prompt
    russian_prompt = get_story_prompt(child, moral, Language.RUSSIAN)
    print("Russian Prompt:")
    print("=" * 50)
    print(russian_prompt)
    print()
    
    # Verify Russian prompt contains key elements
    assert "Создай детскую сказку" in russian_prompt
    assert "Alex" in russian_prompt
    assert "динозавры" in russian_prompt  # dinosaurs in Russian
    assert "храбрость" in russian_prompt  # bravery in Russian
    assert "русском языке" in russian_prompt
    print("✓ Russian prompt contains all required elements")
    
    print("\nAll tests passed! Language support is working correctly.")

if __name__ == "__main__":
    test_language_prompts()