"""Child management use cases."""

from typing import List, Optional
from datetime import datetime

from src.application.dto import ChildRequestDTO, ChildResponseDTO
from src.domain.entities import Child
from src.domain.value_objects import Gender
from src.domain.repositories.child_repository import ChildRepository
from src.core.logging import get_logger
from src.core.exceptions import NotFoundError

logger = get_logger("application.manage_children")


class CreateChildUseCase:
    """Use case for creating a child profile."""
    
    def __init__(self, child_repository: ChildRepository):
        """Initialize use case.
        
        Args:
            child_repository: Child repository
        """
        self.child_repository = child_repository
    
    def execute(self, request: ChildRequestDTO) -> ChildResponseDTO:
        """Create a new child profile.
        
        Args:
            request: Child creation request
            
        Returns:
            Created child response
        """
        logger.info(f"Creating child profile for: {request.name}")
        
        # Create child entity
        child = Child(
            name=request.name,
            age_category=request.age_category,
            gender=Gender(request.gender),
            interests=request.interests,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        # Save to repository
        saved_child = self.child_repository.save(child)
        logger.info(f"Child created with ID: {saved_child.id}")
        
        # Return response
        return self._to_response_dto(saved_child)
    
    def _to_response_dto(self, child: Child) -> ChildResponseDTO:
        """Convert child entity to response DTO."""
        return ChildResponseDTO(
            id=child.id,
            name=child.name,
            age_category=child.age_category,
            gender=child.gender.value,
            interests=child.interests,
            created_at=child.created_at.isoformat() if child.created_at else None,
            updated_at=child.updated_at.isoformat() if child.updated_at else None
        )


class GetChildUseCase:
    """Use case for retrieving a child profile."""
    
    def __init__(self, child_repository: ChildRepository):
        """Initialize use case.
        
        Args:
            child_repository: Child repository
        """
        self.child_repository = child_repository
    
    def execute(self, child_id: str) -> ChildResponseDTO:
        """Get a child profile by ID.
        
        Args:
            child_id: Child ID
            
        Returns:
            Child response
            
        Raises:
            NotFoundError: If child not found
        """
        logger.debug(f"Retrieving child with ID: {child_id}")
        
        child = self.child_repository.find_by_id(child_id)
        if not child:
            raise NotFoundError("Child", child_id)
        
        return self._to_response_dto(child)
    
    def _to_response_dto(self, child: Child) -> ChildResponseDTO:
        """Convert child entity to response DTO."""
        return ChildResponseDTO(
            id=child.id,
            name=child.name,
            age_category=child.age_category,
            gender=child.gender.value,
            interests=child.interests,
            created_at=child.created_at.isoformat() if child.created_at else None,
            updated_at=child.updated_at.isoformat() if child.updated_at else None
        )


class ListChildrenUseCase:
    """Use case for listing all children."""
    
    def __init__(self, child_repository: ChildRepository):
        """Initialize use case.
        
        Args:
            child_repository: Child repository
        """
        self.child_repository = child_repository
    
    def execute(self) -> List[ChildResponseDTO]:
        """List all children.
        
        Returns:
            List of child responses
        """
        logger.debug("Listing all children")
        
        children = self.child_repository.list_all()
        logger.info(f"Retrieved {len(children)} children")
        
        return [self._to_response_dto(child) for child in children]
    
    def _to_response_dto(self, child: Child) -> ChildResponseDTO:
        """Convert child entity to response DTO."""
        return ChildResponseDTO(
            id=child.id,
            name=child.name,
            age_category=child.age_category,
            gender=child.gender.value,
            interests=child.interests,
            created_at=child.created_at.isoformat() if child.created_at else None,
            updated_at=child.updated_at.isoformat() if child.updated_at else None
        )


class ListChildrenByNameUseCase:
    """Use case for listing children by name."""
    
    def __init__(self, child_repository: ChildRepository):
        """Initialize use case.
        
        Args:
            child_repository: Child repository
        """
        self.child_repository = child_repository
    
    def execute(self, name: str) -> List[ChildResponseDTO]:
        """List children by name.
        
        Args:
            name: Child name
            
        Returns:
            List of child responses
        """
        logger.debug(f"Listing children with name: {name}")
        
        children = self.child_repository.find_by_name(name)
        logger.info(f"Retrieved {len(children)} children with name: {name}")
        
        return [self._to_response_dto(child) for child in children]
    
    def _to_response_dto(self, child: Child) -> ChildResponseDTO:
        """Convert child entity to response DTO."""
        return ChildResponseDTO(
            id=child.id,
            name=child.name,
            age_category=child.age_category,
            gender=child.gender.value,
            interests=child.interests,
            created_at=child.created_at.isoformat() if child.created_at else None,
            updated_at=child.updated_at.isoformat() if child.updated_at else None
        )


class DeleteChildUseCase:
    """Use case for deleting a child profile."""
    
    def __init__(self, child_repository: ChildRepository):
        """Initialize use case.
        
        Args:
            child_repository: Child repository
        """
        self.child_repository = child_repository
    
    def execute(self, child_id: str) -> bool:
        """Delete a child profile.
        
        Args:
            child_id: Child ID
            
        Returns:
            True if deleted
            
        Raises:
            NotFoundError: If child not found
        """
        logger.info(f"Deleting child with ID: {child_id}")
        
        deleted = self.child_repository.delete(child_id)
        if not deleted:
            raise NotFoundError("Child", child_id)
        
        logger.info(f"Child deleted: {child_id}")
        return True
