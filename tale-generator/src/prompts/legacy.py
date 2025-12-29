"""Legacy compatibility layer for backward compatibility with existing code.

This module provides wrapper functions that maintain the old API while
delegating to the new modular prompt system.
"""

from typing import List
from src.prompts.character_types import ChildCharacter, HeroCharacter
from src.prompts.builders import EnglishPromptBuilder, RussianPromptBuilder
from src.domain.value_objects import Language


def get_heroic_story_prompt(hero, moral: str, language: Language, story_length: int = 5) -> str:
    """Get a language-specific heroic story prompt (legacy function).
    
    Args:
        hero: Hero object or Hero entity
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    # Convert hero to HeroCharacter
    hero_char = HeroCharacter(
        name=hero.name,
        age=hero.age,
        gender=hero.gender if isinstance(hero.gender, str) else hero.gender.value,
        appearance=hero.appearance,
        personality_traits=hero.personality_traits,
        strengths=hero.strengths,
        interests=hero.interests,
        language=language,
        description=None  # Legacy heroes don't have description
    )
    
    # Use appropriate builder
    if language == Language.RUSSIAN:
        builder = RussianPromptBuilder()
    else:
        builder = EnglishPromptBuilder()
    
    return (builder
            .set_character(hero_char)
            .set_moral(moral)
            .set_story_length(story_length)
            .build())


def get_child_story_prompt(child, moral: str, language: Language, story_length: int = 5) -> str:
    """Get a language-specific child-based story prompt (legacy function).
    
    Args:
        child: Child object or Child entity
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    # Convert child to ChildCharacter
    child_char = ChildCharacter(
        name=child.name,
        age_category=child.age_category,
        gender=child.gender if isinstance(child.gender, str) else child.gender.value,
        interests=child.interests,
        description=None
    )
    
    # Use appropriate builder
    if language == Language.RUSSIAN:
        builder = RussianPromptBuilder()
    else:
        builder = EnglishPromptBuilder()
    
    return (builder
            .set_character(child_char)
            .set_moral(moral)
            .set_story_length(story_length)
            .build())


def get_story_prompt(child, moral, language: Language, story_length: int = 5) -> str:
    """Get a language-specific prompt for story generation (legacy function).
    
    This is a backward compatibility function that delegates to get_child_story_prompt.
    
    Args:
        child: Child profile information
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    return get_child_story_prompt(child, moral, language, story_length)
