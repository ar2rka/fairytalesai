"""Unit tests for the modular prompt system - builders and components."""

import pytest
from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.prompts.builders import PromptBuilder, EnglishPromptBuilder, RussianPromptBuilder
from src.prompts.components import PromptContext
from src.domain.value_objects import Language
from src.core.exceptions import ValidationError


class TestPromptBuilder:
    """Tests for PromptBuilder class."""
    
    def test_build_child_english_prompt(self):
        """Test building an English child story prompt."""
        child = ChildCharacter(
            name="Emma",
            age=7,
            gender="female",
            interests=["unicorns", "fairies"]
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .set_story_length(5)
                  .build())
        
        assert "Emma" in prompt
        assert "7" in prompt
        assert "female" in prompt
        assert "unicorns" in prompt
        assert "fairies" in prompt
        assert "kindness" in prompt
        assert "750 words" in prompt  # 5 minutes * 150 wpm
        assert "English" in prompt
    
    def test_build_child_russian_prompt(self):
        """Test building a Russian child story prompt."""
        child = ChildCharacter(
            name="Аня",
            age=6,
            gender="female",
            interests=["котята", "цветы"]
        )
        
        builder = RussianPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .set_story_length(5)
                  .build())
        
        assert "Аня" in prompt
        assert "6" in prompt
        assert "девочка" in prompt  # Translated gender
        assert "котята" in prompt
        assert "цветы" in prompt
        assert "доброта" in prompt  # Translated moral
        assert "750 слов" in prompt
        assert "русском языке" in prompt
    
    def test_build_hero_english_prompt(self):
        """Test building an English hero story prompt."""
        hero = HeroCharacter(
            name="Captain Wonder",
            age=12,
            gender="male",
            appearance="Wears a blue cape with golden star",
            personality_traits=["brave", "kind"],
            strengths=["flying", "super strength"],
            interests=["helping others", "solving mysteries"],
            language=Language.ENGLISH
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(hero)
                  .set_moral("bravery")
                  .set_story_length(5)
                  .build())
        
        assert "Captain Wonder" in prompt
        assert "Wears a blue cape" in prompt
        assert "brave" in prompt
        assert "kind" in prompt
        assert "flying" in prompt
        assert "super strength" in prompt
        assert "bravery" in prompt
        assert "heroic character" in prompt
    
    def test_build_hero_russian_prompt(self):
        """Test building a Russian hero story prompt."""
        hero = HeroCharacter(
            name="Капитан Чудо",
            age=10,
            gender="female",
            appearance="Носит красный плащ",
            personality_traits=["храбрая", "добрая"],
            strengths=["летает", "суперсила"],
            interests=["помощь другим"],
            language=Language.RUSSIAN
        )
        
        builder = RussianPromptBuilder()
        prompt = (builder
                  .set_character(hero)
                  .set_moral("bravery")
                  .set_story_length(5)
                  .build())
        
        assert "Капитан Чудо" in prompt
        assert "Носит красный плащ" in prompt
        assert "храбрая" in prompt
        assert "летает" in prompt
        assert "храбрость" in prompt  # Translated moral
        assert "герое" in prompt
    
    def test_build_combined_english_prompt(self):
        """Test building an English combined character prompt."""
        child = ChildCharacter(
            name="Sophie",
            age=7,
            gender="female",
            interests=["magic", "books"]
        )
        
        hero = HeroCharacter(
            name="Wizard Merlin",
            age=100,
            gender="male",
            appearance="Long white beard and blue robes",
            personality_traits=["wise", "patient"],
            strengths=["magic spells", "wisdom"],
            interests=["ancient scrolls", "teaching"],
            language=Language.ENGLISH
        )
        
        combined = CombinedCharacter(
            child=child,
            hero=hero,
            relationship="Sophie becomes Merlin's apprentice"
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(combined)
                  .set_moral("perseverance")
                  .set_story_length(5)
                  .build())
        
        assert "Sophie" in prompt
        assert "Wizard Merlin" in prompt
        assert "Child Character" in prompt
        assert "Hero Character" in prompt
        assert "magic" in prompt
        assert "books" in prompt
        assert "Long white beard" in prompt
        assert "wise" in prompt
        assert "apprentice" in prompt
    
    def test_build_with_description(self):
        """Test building prompt with freeform description."""
        child = ChildCharacter(
            name="Max",
            age=8,
            gender="male",
            interests=["dinosaurs", "fossils"],
            description="Max is very curious and loves visiting museums."
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("curiosity")
                  .set_story_length(3)
                  .build())
        
        assert "Max" in prompt
        assert "Additional Context" in prompt
        assert "very curious and loves visiting museums" in prompt
    
    def test_build_without_character_fails(self):
        """Test that building without character raises error."""
        builder = PromptBuilder()
        
        with pytest.raises(ValidationError) as exc_info:
            builder.set_moral("kindness").build()
        
        assert "Character must be set" in str(exc_info.value)
    
    def test_build_without_moral_fails(self):
        """Test that building without moral raises error."""
        child = ChildCharacter(
            name="Test",
            age=7,
            gender="female",
            interests=["reading"]
        )
        
        builder = PromptBuilder()
        
        with pytest.raises(ValidationError) as exc_info:
            builder.set_character(child).build()
        
        assert "Moral must be set" in str(exc_info.value)
    
    def test_invalid_story_length_fails(self):
        """Test that invalid story length raises error."""
        builder = PromptBuilder()
        
        with pytest.raises(ValidationError) as exc_info:
            builder.set_story_length(0)
        
        assert "Story length must be positive" in str(exc_info.value)
        
        with pytest.raises(ValidationError):
            builder.set_story_length(-5)
    
    def test_builder_reset(self):
        """Test resetting builder state."""
        child = ChildCharacter(
            name="Test",
            age=7,
            gender="female",
            interests=["reading"]
        )
        
        builder = PromptBuilder()
        builder.set_character(child).set_moral("kindness")
        
        builder.reset()
        
        # Should fail because character was reset
        with pytest.raises(ValidationError):
            builder.build()
    
    def test_method_chaining(self):
        """Test that builder methods support chaining."""
        child = ChildCharacter(
            name="Test",
            age=7,
            gender="female",
            interests=["reading"]
        )
        
        builder = PromptBuilder()
        result = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .set_language(Language.ENGLISH)
                  .set_story_length(5))
        
        assert result is builder  # Should return self
    
    def test_different_story_lengths(self):
        """Test prompts with different story lengths."""
        child = ChildCharacter(
            name="Test",
            age=7,
            gender="female",
            interests=["reading"]
        )
        
        builder = EnglishPromptBuilder()
        
        prompt_3min = (builder
                       .set_character(child)
                       .set_moral("kindness")
                       .set_story_length(3)
                       .build())
        
        builder.reset()
        
        prompt_10min = (builder
                        .set_character(child)
                        .set_moral("kindness")
                        .set_story_length(10)
                        .build())
        
        assert "450 words" in prompt_3min  # 3 * 150
        assert "1500 words" in prompt_10min  # 10 * 150


class TestLanguageSpecificBuilders:
    """Tests for language-specific builder classes."""
    
    def test_english_builder_defaults(self):
        """Test English builder has correct default language."""
        child = ChildCharacter(
            name="Emma",
            age=7,
            gender="female",
            interests=["unicorns"]
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .build())
        
        assert "English" in prompt
        assert "английском" not in prompt
    
    def test_russian_builder_defaults(self):
        """Test Russian builder has correct default language."""
        child = ChildCharacter(
            name="Аня",
            age=6,
            gender="female",
            interests=["котята"]
        )
        
        builder = RussianPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .build())
        
        assert "русском языке" in prompt
        assert "English" not in prompt


class TestPromptContent:
    """Tests for verifying prompt content quality."""
    
    def test_prompt_includes_all_components(self):
        """Test that built prompt includes all standard components."""
        child = ChildCharacter(
            name="Emma",
            age=7,
            gender="female",
            interests=["unicorns", "fairies"]
        )
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(child)
                  .set_moral("kindness")
                  .set_story_length(5)
                  .build())
        
        # Should include character description
        assert "Emma" in prompt
        assert "unicorns" in prompt
        
        # Should include moral
        assert "kindness" in prompt
        
        # Should include length
        assert "750 words" in prompt
        
        # Should include ending instruction
        assert "End the story" in prompt or "message about the moral" in prompt
        
        # Should include language
        assert "English" in prompt
    
    def test_combined_prompt_structure(self):
        """Test that combined character prompts have proper structure."""
        child = ChildCharacter(
            name="Tom",
            age=8,
            gender="male",
            interests=["space"]
        )
        
        hero = HeroCharacter(
            name="Star Captain",
            age=30,
            gender="male",
            appearance="Wears space suit",
            personality_traits=["brave"],
            strengths=["piloting"],
            interests=["exploration"],
            language=Language.ENGLISH
        )
        
        combined = CombinedCharacter(child=child, hero=hero)
        
        builder = EnglishPromptBuilder()
        prompt = (builder
                  .set_character(combined)
                  .set_moral("courage")
                  .build())
        
        # Should clearly separate child and hero sections
        assert "Child Character" in prompt
        assert "Hero Character" in prompt
        assert "Tom" in prompt
        assert "Star Captain" in prompt


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
