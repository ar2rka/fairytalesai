"""Modular prompt generation system for story creation.

This package provides character types for use with Jinja2 prompt templates.
Character types are used by PromptTemplateService to render prompts from Supabase.
"""

from src.prompts.character_types import (
    BaseCharacter,
    ChildCharacter,
    HeroCharacter,
    CombinedCharacter
)

__all__ = [
    "BaseCharacter",
    "ChildCharacter",
    "HeroCharacter",
    "CombinedCharacter",
]
