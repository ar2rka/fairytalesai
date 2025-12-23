"""Base repository interface."""

from abc import ABC, abstractmethod
from typing import TypeVar, Generic, Optional, List

T = TypeVar('T')


class Repository(ABC, Generic[T]):
    """Base repository interface for CRUD operations."""
    
    @abstractmethod
    def save(self, entity: T) -> T:
        """Save an entity.
        
        Args:
            entity: Entity to save
            
        Returns:
            Saved entity with ID
        """
        pass
    
    @abstractmethod
    def find_by_id(self, entity_id: str) -> Optional[T]:
        """Find entity by ID.
        
        Args:
            entity_id: Entity ID
            
        Returns:
            Entity if found, None otherwise
        """
        pass
    
    @abstractmethod
    def list_all(self) -> List[T]:
        """List all entities.
        
        Returns:
            List of all entities
        """
        pass
    
    @abstractmethod
    def delete(self, entity_id: str) -> bool:
        """Delete entity by ID.
        
        Args:
            entity_id: Entity ID
            
        Returns:
            True if deleted, False otherwise
        """
        pass
