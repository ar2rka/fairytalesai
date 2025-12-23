"""Components for building story prompts."""

from src.prompts.components.base_component import BaseComponent, PromptContext
from src.prompts.components.character_description_component import CharacterDescriptionComponent
from src.prompts.components.moral_component import MoralComponent
from src.prompts.components.length_component import LengthComponent
from src.prompts.components.ending_component import EndingComponent
from src.prompts.components.language_component import LanguageComponent

__all__ = [
    "BaseComponent",
    "PromptContext",
    "CharacterDescriptionComponent",
    "MoralComponent",
    "LengthComponent",
    "EndingComponent",
    "LanguageComponent",
]
