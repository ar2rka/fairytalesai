"""Generation repository interface."""

from abc import ABC, abstractmethod
from typing import Optional, List
from src.infrastructure.persistence.models import GenerationDB


class GenerationRepository(ABC):
    """Repository interface for generation tracking operations."""
    
    @abstractmethod
    async def create_generation(self, generation: GenerationDB) -> GenerationDB:
        """Create a new generation record.
        
        Args:
            generation: Generation record to create
            
        Returns:
            Created generation record
        """
        pass
    
    @abstractmethod
    async def update_generation(self, generation: GenerationDB) -> GenerationDB:
        """Update an existing generation record.
        
        Args:
            generation: Generation record with updated data
            
        Returns:
            Updated generation record
        """
        pass
    
    @abstractmethod
    async def get_generation(self, generation_id: str, attempt_number: int) -> Optional[GenerationDB]:
        """Get a specific generation attempt.
        
        Args:
            generation_id: Generation identifier
            attempt_number: Attempt number
            
        Returns:
            Generation record if found, None otherwise
        """
        pass
    
    @abstractmethod
    async def get_latest_attempt(self, generation_id: str) -> Optional[GenerationDB]:
        """Get the latest attempt for a generation.
        
        Args:
            generation_id: Generation identifier
            
        Returns:
            Latest generation attempt if found, None otherwise
        """
        pass
    
    @abstractmethod
    async def get_all_attempts(self, generation_id: str) -> List[GenerationDB]:
        """Get all attempts for a generation.
        
        Args:
            generation_id: Generation identifier
            
        Returns:
            List of all attempts for the generation
        """
        pass
    
    @abstractmethod
    async def get_user_generations(self, user_id: str, limit: int = 50) -> List[GenerationDB]:
        """Get all generations for a user.
        
        Args:
            user_id: User identifier
            limit: Maximum number of records to return
            
        Returns:
            List of user's generations
        """
        pass
    
    @abstractmethod
    async def get_generations_by_status(self, status: str, limit: int = 50) -> List[GenerationDB]:
        """Get generations by status.
        
        Args:
            status: Status to filter by ('pending', 'success', 'failed', 'timeout')
            limit: Maximum number of records to return
            
        Returns:
            List of generations with the specified status
        """
        pass
