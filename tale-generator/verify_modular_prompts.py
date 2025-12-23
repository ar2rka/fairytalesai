"""Simple verification script for the modular prompt system."""

from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.prompts.builders import EnglishPromptBuilder, RussianPromptBuilder
from src.domain.value_objects import Language


def test_child_english():
    """Test creating an English child prompt."""
    print("=" * 80)
    print("TEST: Child Character - English")
    print("=" * 80)
    
    child = ChildCharacter(
        name="Emma",
        age=7,
        gender="female",
        interests=["unicorns", "fairies", "princesses"],
        description="Emma is very imaginative and loves creating her own fairy tales."
    )
    
    builder = EnglishPromptBuilder()
    prompt = (builder
              .set_character(child)
              .set_moral("kindness")
              .set_story_length(5)
              .build())
    
    print(prompt)
    print("\n✓ Child English prompt generated successfully\n")
    return True


def test_child_russian():
    """Test creating a Russian child prompt."""
    print("=" * 80)
    print("TEST: Child Character - Russian")
    print("=" * 80)
    
    child = ChildCharacter(
        name="Аня",
        age=6,
        gender="female",
        interests=["котята", "цветы", "танцы"],
        description="Аня очень добрая и всегда помогает младшим детям в детском саду."
    )
    
    builder = RussianPromptBuilder()
    prompt = (builder
              .set_character(child)
              .set_moral("kindness")
              .set_story_length(5)
              .build())
    
    print(prompt)
    print("\n✓ Child Russian prompt generated successfully\n")
    return True


def test_hero_english():
    """Test creating an English hero prompt."""
    print("=" * 80)
    print("TEST: Hero Character - English")
    print("=" * 80)
    
    hero = HeroCharacter(
        name="Captain Wonder",
        age=12,
        gender="male",
        appearance="Wears a blue cape with a golden star, has bright eyes and a confident smile",
        personality_traits=["brave", "kind", "curious", "determined"],
        strengths=["flying", "super strength", "problem-solving"],
        interests=["exploring space", "helping others", "solving mysteries"],
        language=Language.ENGLISH,
        description="Captain Wonder is known for his unwavering dedication to justice."
    )
    
    builder = EnglishPromptBuilder()
    prompt = (builder
              .set_character(hero)
              .set_moral("bravery")
              .set_story_length(5)
              .build())
    
    print(prompt)
    print("\n✓ Hero English prompt generated successfully\n")
    return True


def test_hero_russian():
    """Test creating a Russian hero prompt."""
    print("=" * 80)
    print("TEST: Hero Character - Russian")
    print("=" * 80)
    
    hero = HeroCharacter(
        name="Капитан Чудо",
        age=10,
        gender="female",
        appearance="Носит красный плащ с серебряной звездой, у неё карие глаза и добрый взгляд",
        personality_traits=["храбрая", "добрая", "любознательная", "настойчивая"],
        strengths=["летает", "суперсила", "решение проблем"],
        interests=["путешествия по космосу", "помощь другим", "разгадывание загадок"],
        language=Language.RUSSIAN,
        description="Капитан Чудо защищает город уже много лет и известна своей мудростью."
    )
    
    builder = RussianPromptBuilder()
    prompt = (builder
              .set_character(hero)
              .set_moral("bravery")
              .set_story_length(5)
              .build())
    
    print(prompt)
    print("\n✓ Hero Russian prompt generated successfully\n")
    return True


def test_combined_english():
    """Test creating a combined character prompt."""
    print("=" * 80)
    print("TEST: Combined Character - English")
    print("=" * 80)
    
    child = ChildCharacter(
        name="Sophie",
        age=7,
        gender="female",
        interests=["magic", "books", "learning"],
        description="Sophie is curious and dreams of becoming a great wizard."
    )
    
    hero = HeroCharacter(
        name="Wizard Merlin",
        age=100,
        gender="male",
        appearance="Long white beard, sparkling blue robes covered in stars",
        personality_traits=["wise", "patient", "kind"],
        strengths=["powerful magic", "ancient knowledge", "teaching"],
        interests=["ancient scrolls", "teaching young wizards", "protecting the realm"],
        language=Language.ENGLISH,
        description="Merlin has guided many young wizards on their path to greatness."
    )
    
    combined = CombinedCharacter(
        child=child,
        hero=hero,
        relationship="Sophie discovers Merlin in the ancient library and becomes his apprentice"
    )
    
    builder = EnglishPromptBuilder()
    prompt = (builder
              .set_character(combined)
              .set_moral("perseverance")
              .set_story_length(5)
              .build())
    
    print(prompt)
    print("\n✓ Combined English prompt generated successfully\n")
    return True


def test_legacy_compatibility():
    """Test legacy compatibility functions."""
    print("=" * 80)
    print("TEST: Legacy Compatibility")
    print("=" * 80)
    
    from src.prompts import get_child_story_prompt
    from src.domain.entities import Child
    from src.domain.value_objects import Gender
    
    # Create child using domain entity
    child = Child(
        name="Test Child",
        age=7,
        gender=Gender.FEMALE,
        interests=["reading", "art"]
    )
    
    # Use legacy function
    prompt = get_child_story_prompt(
        child=child,
        moral="kindness",
        language=Language.ENGLISH,
        story_length=5
    )
    
    print(prompt)
    print("\n✓ Legacy compatibility verified\n")
    return True


def main():
    """Run all tests."""
    print("\n" + "=" * 80)
    print("MODULAR PROMPT SYSTEM VERIFICATION")
    print("=" * 80 + "\n")
    
    tests = [
        test_child_english,
        test_child_russian,
        test_hero_english,
        test_hero_russian,
        test_combined_english,
        test_legacy_compatibility
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"\n✗ {test.__name__} failed: {e}\n")
            import traceback
            traceback.print_exc()
            failed += 1
    
    print("=" * 80)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 80 + "\n")
    
    return failed == 0


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
