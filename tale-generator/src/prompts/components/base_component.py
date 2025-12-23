"""Base component interface for prompt building."""

from abc import ABC, abstractmethod
from typing import Dict, Any, List
from dataclasses import dataclass
from src.domain.value_objects import Language
from src.prompts.character_types.base import BaseCharacter


@dataclass
class PromptContext:
    """Context data for prompt component rendering."""
    
    character: BaseCharacter
    moral: str
    language: Language
    story_length: int  # in minutes
    word_count: int


class BaseComponent(ABC):
    """Base interface for prompt components."""
    
    @abstractmethod
    def render(self, context: PromptContext) -> str:
        """Render the component as a prompt fragment.
        
        Args:
            context: Context containing character, moral, language, etc.
            
        Returns:
            Rendered prompt fragment as string
        """
        ...
    
    def validate(self, context: PromptContext) -> bool:
        """Validate if component can render with given context.
        
        Args:
            context: Context to validate
            
        Returns:
            True if component can render
        """
        return True
    
    def get_dependencies(self) -> List[type]:
        """Get list of component types this component depends on.
        
        Returns:
            List of component class types
        """
        return []
