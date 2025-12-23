"""Story repository interface."""

from abc import abstractmethod
from typing import List, Optional
from src.domain.repositories.base import Repository
from src.domain.entities import Story
from src.domain.value_objects import Language, Rating


class StoryRepository(Repository[Story]):
    """Repository interface for Story entities."""
    
    @abstractmethod
    def find_by_child_id(self, child_id: str) -> List[Story]:
        """Find stories by child ID.
        
        Args:
            child_id: Child ID
            
        Returns:
            List of stories for the child
        """
        pass
    
    @abstractmethod
    def find_by_child_name(self, child_name: str) -> List[Story]:
        """Find stories by child name.
        
        Args:
            child_name: Child name
            
        Returns:
            List of stories for the child
        """
        pass
    
    @abstractmethod
    def find_by_language(self, language: Language) -> List[Story]:
        """Find stories by language.
        
        Args:
            language: Language
            
        Returns:
            List of stories in the language
        """
        pass
    
    @abstractmethod
    def update_rating(self, story_id: str, rating: Rating) -> Optional[Story]:
        """Update story rating.
        
        Args:
            story_id: Story ID
            rating: New rating
            
        Returns:
            Updated story if found, None otherwise
        """
        pass
