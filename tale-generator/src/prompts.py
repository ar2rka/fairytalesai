"""Backward compatibility module for old prompts classes.

This module provides backward compatibility with the old monolithic prompts module.
It re-exports data classes (Heroes, Children) that are still used in migration scripts.

Note: Prompt generation functionality now uses Jinja2 templates via PromptTemplateService.
Character types are available from src.prompts:
    from src.prompts import ChildCharacter, HeroCharacter, CombinedCharacter
"""

# Re-export classes from old prompts.py for backward compatibility
# (used in migration scripts and data population)
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
    # Data classes (still used in scripts)
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
