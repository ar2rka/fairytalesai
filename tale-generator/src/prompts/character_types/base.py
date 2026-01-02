"""Base character interface for prompt generation."""

from abc import ABC, abstractmethod
from typing import Dict, Any


class BaseCharacter(ABC):
    """Base interface for all character types used in story generation.
    
    Note: Different character types use different age representations:
    - ChildCharacter uses age_category (str, e.g., '3-5')
    - HeroCharacter uses age (int)
    """
    
    @abstractmethod
    def get_description_data(self) -> Dict[str, Any]:
        """Get character data for prompt rendering.
        
        Returns:
            Dictionary containing character attributes
        """
        ...
    
    @abstractmethod
    def validate(self) -> None:
        """Validate character data.
        
        Raises:
            ValidationError: If character data is invalid
        """
        ...
