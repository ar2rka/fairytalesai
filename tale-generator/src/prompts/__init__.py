"""Modular prompt generation system for story creation.

This package provides a composable architecture for building story prompts
with support for multiple character types and languages.
"""

from src.prompts.character_types import (
    BaseCharacter,
    ChildCharacter,
    HeroCharacter,
    CombinedCharacter
)
from src.prompts.builders import (
    PromptBuilder,
    EnglishPromptBuilder,
    RussianPromptBuilder
)
from src.prompts.legacy import (
    get_heroic_story_prompt,
    get_child_story_prompt,
    get_story_prompt
)

__all__ = [
    "BaseCharacter",
    "ChildCharacter",
    "HeroCharacter",
    "CombinedCharacter",
    "PromptBuilder",
    "EnglishPromptBuilder",
    "RussianPromptBuilder",
    "get_heroic_story_prompt",
    "get_child_story_prompt",
    "get_story_prompt",
]
