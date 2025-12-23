"""Hero repository interface."""

from abc import abstractmethod
from typing import List, Optional
from src.domain.repositories.base import Repository
from src.domain.entities import Hero
from src.domain.value_objects import Language


class HeroRepository(Repository[Hero]):
    """Repository interface for Hero entities."""
    
    @abstractmethod
    def find_by_name(self, name: str) -> List[Hero]:
        """Find heroes by name.
        
        Args:
            name: Hero name
            
        Returns:
            List of heroes with the name
        """
        pass
    
    @abstractmethod
    def find_by_language(self, language: Language) -> List[Hero]:
        """Find heroes by language.
        
        Args:
            language: Language
            
        Returns:
            List of heroes for the language
        """
        pass
    
    @abstractmethod
    def update(self, hero: Hero) -> Hero:
        """Update a hero.
        
        Args:
            hero: Hero to update
            
        Returns:
            Updated hero
        """
        pass
