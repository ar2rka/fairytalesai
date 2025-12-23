"""Unit tests for the modular prompt system - character types."""

import pytest
from src.prompts.character_types import (
    ChildCharacter,
    HeroCharacter,
    CombinedCharacter
)
from src.domain.value_objects import Language
from src.core.exceptions import ValidationError


class TestChildCharacter:
    """Tests for ChildCharacter class."""
    
    def test_create_valid_child(self):
        """Test creating a valid child character."""
        child = ChildCharacter(
            name="Emma",
            age=7,
            gender="female",
            interests=["unicorns", "fairies"]
        )
        
        assert child.name == "Emma"
        assert child.age == 7
        assert child.gender == "female"
        assert child.interests == ["unicorns", "fairies"]
        assert child.description is None
    
    def test_create_child_with_description(self):
        """Test creating a child with optional description."""
        child = ChildCharacter(
            name="Alex",
            age=8,
            gender="male",
            interests=["robots", "space"],
            description="Alex loves building things and dreams of being an astronaut."
        )
        
        assert child.description == "Alex loves building things and dreams of being an astronaut."
    
    def test_child_empty_name_fails(self):
        """Test that empty name raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            ChildCharacter(
                name="",
                age=7,
                gender="female",
                interests=["reading"]
            )
        assert "name cannot be empty" in str(exc_info.value)
    
    def test_child_invalid_age_fails(self):
        """Test that invalid age raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            ChildCharacter(
                name="Test",
                age=0,
                gender="female",
                interests=["reading"]
            )
        assert "age must be between 1 and 18" in str(exc_info.value)
        
        with pytest.raises(ValidationError):
            ChildCharacter(
                name="Test",
                age=20,
                gender="female",
                interests=["reading"]
            )
    
    def test_child_no_interests_fails(self):
        """Test that empty interests raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            ChildCharacter(
                name="Test",
                age=7,
                gender="female",
                interests=[]
            )
        assert "at least one interest" in str(exc_info.value)
    
    def test_get_description_data(self):
        """Test getting child description data."""
        child = ChildCharacter(
            name="Lily",
            age=6,
            gender="female",
            interests=["cats", "flowers"],
            description="Lily is very kind."
        )
        
        data = child.get_description_data()
        
        assert data["name"] == "Lily"
        assert data["age"] == 6
        assert data["gender"] == "female"
        assert data["interests"] == ["cats", "flowers"]
        assert data["description"] == "Lily is very kind."
        assert data["character_type"] == "child"


class TestHeroCharacter:
    """Tests for HeroCharacter class."""
    
    def test_create_valid_hero(self):
        """Test creating a valid hero character."""
        hero = HeroCharacter(
            name="Captain Wonder",
            age=12,
            gender="male",
            appearance="Wears a blue cape",
            personality_traits=["brave", "kind"],
            strengths=["flying", "super strength"],
            interests=["helping others"],
            language=Language.ENGLISH
        )
        
        assert hero.name == "Captain Wonder"
        assert hero.age == 12
        assert hero.gender == "male"
        assert hero.appearance == "Wears a blue cape"
        assert len(hero.personality_traits) == 2
        assert len(hero.strengths) == 2
        assert hero.language == Language.ENGLISH
    
    def test_create_hero_with_description(self):
        """Test creating a hero with optional description."""
        hero = HeroCharacter(
            name="Starlight",
            age=14,
            gender="female",
            appearance="Glows with gentle light",
            personality_traits=["wise", "compassionate"],
            strengths=["light manipulation"],
            interests=["stargazing"],
            language=Language.ENGLISH,
            description="Starlight protects the galaxy from darkness."
        )
        
        assert hero.description == "Starlight protects the galaxy from darkness."
    
    def test_hero_empty_appearance_fails(self):
        """Test that empty appearance raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            HeroCharacter(
                name="Test Hero",
                age=10,
                gender="male",
                appearance="",
                personality_traits=["brave"],
                strengths=["strength"],
                interests=["adventure"],
                language=Language.ENGLISH
            )
        assert "appearance cannot be empty" in str(exc_info.value)
    
    def test_hero_no_personality_traits_fails(self):
        """Test that empty personality traits raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            HeroCharacter(
                name="Test Hero",
                age=10,
                gender="male",
                appearance="Test appearance",
                personality_traits=[],
                strengths=["strength"],
                interests=["adventure"],
                language=Language.ENGLISH
            )
        assert "at least one personality trait" in str(exc_info.value)
    
    def test_get_description_data(self):
        """Test getting hero description data."""
        hero = HeroCharacter(
            name="Ice Wizard",
            age=16,
            gender="male",
            appearance="Wears blue robes",
            personality_traits=["calm", "intelligent"],
            strengths=["ice magic"],
            interests=["magic", "ancient runes"],
            language=Language.RUSSIAN,
            description="A powerful ice wizard."
        )
        
        data = hero.get_description_data()
        
        assert data["name"] == "Ice Wizard"
        assert data["language"] == Language.RUSSIAN
        assert data["description"] == "A powerful ice wizard."
        assert data["character_type"] == "hero"


class TestCombinedCharacter:
    """Tests for CombinedCharacter class."""
    
    def test_create_valid_combined(self):
        """Test creating a valid combined character."""
        child = ChildCharacter(
            name="Sophie",
            age=7,
            gender="female",
            interests=["magic", "books"]
        )
        
        hero = HeroCharacter(
            name="Dragon Master",
            age=30,
            gender="male",
            appearance="Wears dragon-scale armor",
            personality_traits=["brave", "wise"],
            strengths=["dragon riding"],
            interests=["dragons", "adventure"],
            language=Language.ENGLISH
        )
        
        combined = CombinedCharacter(
            child=child,
            hero=hero,
            relationship="Sophie discovers Dragon Master in the forest"
        )
        
        assert combined.child == child
        assert combined.hero == hero
        assert combined.name == "Sophie"  # Primary name is child's
        assert combined.age == 7  # Primary age is child's
        assert combined.relationship == "Sophie discovers Dragon Master in the forest"
    
    def test_combined_with_descriptions(self):
        """Test combined character with both descriptions."""
        child = ChildCharacter(
            name="Anna",
            age=6,
            gender="female",
            interests=["flowers"],
            description="Anna is very curious about nature."
        )
        
        hero = HeroCharacter(
            name="Nature Guardian",
            age=100,
            gender="female",
            appearance="Made of leaves and vines",
            personality_traits=["gentle", "ancient"],
            strengths=["plant control"],
            interests=["forests", "animals"],
            language=Language.ENGLISH,
            description="Guardian of the ancient forest for centuries."
        )
        
        combined = CombinedCharacter(child=child, hero=hero)
        
        data = combined.get_description_data()
        assert data["child"]["description"] == "Anna is very curious about nature."
        assert data["hero"]["description"] == "Guardian of the ancient forest for centuries."
    
    def test_get_merged_interests(self):
        """Test merging interests from both characters."""
        child = ChildCharacter(
            name="Tom",
            age=8,
            gender="male",
            interests=["space", "robots", "science"]
        )
        
        hero = HeroCharacter(
            name="Cosmic Explorer",
            age=25,
            gender="male",
            appearance="Space suit",
            personality_traits=["adventurous"],
            strengths=["space travel"],
            interests=["space", "aliens", "planets"],
            language=Language.ENGLISH
        )
        
        combined = CombinedCharacter(child=child, hero=hero)
        merged = combined.get_merged_interests()
        
        # Should have unique interests from both
        assert "space" in merged
        assert "robots" in merged
        assert "science" in merged
        assert "aliens" in merged
        assert "planets" in merged
        # Should not have duplicates
        assert merged.count("space") == 1
    
    def test_combined_invalid_child_fails(self):
        """Test that invalid child type raises validation error."""
        hero = HeroCharacter(
            name="Test",
            age=20,
            gender="male",
            appearance="Test",
            personality_traits=["brave"],
            strengths=["strength"],
            interests=["adventure"],
            language=Language.ENGLISH
        )
        
        with pytest.raises(ValidationError) as exc_info:
            CombinedCharacter(
                child="not a child character",  # Invalid type
                hero=hero
            )
        assert "ChildCharacter instance" in str(exc_info.value)
    
    def test_get_description_data(self):
        """Test getting combined description data."""
        child = ChildCharacter(
            name="Max",
            age=9,
            gender="male",
            interests=["dinosaurs"]
        )
        
        hero = HeroCharacter(
            name="Dino Guardian",
            age=40,
            gender="male",
            appearance="Wears dinosaur armor",
            personality_traits=["protective"],
            strengths=["dinosaur summoning"],
            interests=["dinosaurs", "fossils"],
            language=Language.ENGLISH
        )
        
        combined = CombinedCharacter(
            child=child,
            hero=hero,
            relationship="Max befriends the Dino Guardian"
        )
        
        data = combined.get_description_data()
        
        assert data["character_type"] == "combined"
        assert data["child"]["name"] == "Max"
        assert data["hero"]["name"] == "Dino Guardian"
        assert data["relationship"] == "Max befriends the Dino Guardian"
        assert "dinosaurs" in data["merged_interests"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
