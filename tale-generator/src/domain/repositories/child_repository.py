"""Child repository interface."""

from abc import abstractmethod
from typing import List, Optional
from src.domain.repositories.base import Repository
from src.domain.entities import Child
from src.domain.value_objects import Gender


class ChildRepository(Repository[Child]):
    """Repository interface for Child entities."""
    
    @abstractmethod
    def find_by_name(self, name: str) -> List[Child]:
        """Find children by name.
        
        Args:
            name: Child name
            
        Returns:
            List of children with the name
        """
        pass
    
    @abstractmethod
    def find_exact_match(self, name: str, age: int, gender: Gender) -> Optional[Child]:
        """Find exact match for child profile.
        
        Args:
            name: Child name
            age: Child age
            gender: Child gender
            
        Returns:
            Matching child if found, None otherwise
        """
        pass
