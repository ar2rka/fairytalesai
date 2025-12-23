"""Language-specific prompts for story generation.

This module provides backward compatibility with the old monolithic prompts module.
All functionality now delegates to the new modular prompt system in src/prompts/.

For new code, prefer using the modular system directly:
    from src.prompts import ChildCharacter, HeroCharacter, EnglishPromptBuilder
"""

# Import legacy compatibility functions
from src.prompts.legacy import (
    get_heroic_story_prompt,
    get_child_story_prompt,
    get_story_prompt
)

# Re-export classes from old prompts.py for backward compatibility
from src.prompts_old import (
    Hero,
    Child,
    StoryPrompt,
    LanguageStoryInfo,
    EnglishStoryInfo,
    RussianStoryInfo,
    PromptGenerator,
    EnglishPromptGenerator,
    RussianPromptGenerator,
    PromptFactory,
    Heroes,
    Children
)

__all__ = [
    # Legacy functions
    "get_heroic_story_prompt",
    "get_child_story_prompt",
    "get_story_prompt",
    # Legacy classes
    "Hero",
    "Child",
    "StoryPrompt",
    "LanguageStoryInfo",
    "EnglishStoryInfo",
    "RussianStoryInfo",
    "PromptGenerator",
    "EnglishPromptGenerator",
    "RussianPromptGenerator",
    "PromptFactory",
    "Heroes",
    "Children",
]
