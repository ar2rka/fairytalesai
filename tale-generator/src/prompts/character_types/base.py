"""Base character interface for prompt generation."""

from abc import ABC, abstractmethod
from typing import Dict, Any


class BaseCharacter(ABC):
    """Base interface for all character types used in story generation."""
    
    name: str
    age: int
    gender: str
    
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
