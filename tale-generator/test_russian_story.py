"""Test script to generate a Russian story."""

from src.prompts import get_story_prompt
from src.models import Language, ChildProfile, Gender

def test_russian_story():
    """Test generating a Russian story."""
    # Test child data
    child = ChildProfile(
        name="Алекс",
        age=7,
        gender=Gender.MALE,
        interests=["динозавры", "космос", "роботы"]
    )
    
    moral = "храбрость"
    
    # Test Russian prompt
    russian_prompt = get_story_prompt(child, moral, Language.RUSSIAN)
    print("Russian Prompt:")
    print("=" * 50)
    print(russian_prompt)
    print()
    
    # Verify Russian prompt contains key elements
    assert "Создай детскую сказку" in russian_prompt
    assert "Алекс" in russian_prompt
    assert "динозавры" in russian_prompt
    assert "храбрость" in russian_prompt
    assert "русском языке" in russian_prompt
    print("✓ Russian prompt contains all required elements")

if __name__ == "__main__":
    test_russian_story()