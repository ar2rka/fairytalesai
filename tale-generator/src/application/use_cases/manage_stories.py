"""Story management use cases."""

from typing import List
from src.application.dto import StoryDBResponseDTO, StoryRatingRequestDTO
from src.domain.entities import Story
from src.domain.value_objects import Language, Rating
from src.domain.repositories.story_repository import StoryRepository
from src.domain.services.story_service import StoryService
from src.core.logging import get_logger
from src.core.exceptions import NotFoundError

logger = get_logger("application.manage_stories")


class GetStoryUseCase:
    """Use case for retrieving a story."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self, story_id: str) -> StoryDBResponseDTO:
        """Get a story by ID.
        
        Args:
            story_id: Story ID
            
        Returns:
            Story response
            
        Raises:
            NotFoundError: If story not found
        """
        logger.debug(f"Retrieving story with ID: {story_id}")
        
        story = self.story_repository.find_by_id(story_id)
        if not story:
            raise NotFoundError("Story", story_id)
        
        return self._to_response_dto(story)
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class ListAllStoriesUseCase:
    """Use case for listing all stories."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self) -> List[StoryDBResponseDTO]:
        """List all stories.
        
        Returns:
            List of story responses
        """
        logger.debug("Listing all stories")
        
        stories = self.story_repository.list_all()
        logger.info(f"Retrieved {len(stories)} stories")
        
        return [self._to_response_dto(story) for story in stories]
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class ListStoriesByChildIdUseCase:
    """Use case for listing stories by child ID."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self, child_id: str) -> List[StoryDBResponseDTO]:
        """List stories for a child.
        
        Args:
            child_id: Child ID
            
        Returns:
            List of story responses
        """
        logger.debug(f"Listing stories for child ID: {child_id}")
        
        stories = self.story_repository.find_by_child_id(child_id)
        logger.info(f"Retrieved {len(stories)} stories for child ID: {child_id}")
        
        return [self._to_response_dto(story) for story in stories]
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class ListStoriesByChildNameUseCase:
    """Use case for listing stories by child name."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self, child_name: str) -> List[StoryDBResponseDTO]:
        """List stories for a child.
        
        Args:
            child_name: Child name
            
        Returns:
            List of story responses
        """
        logger.debug(f"Listing stories for child: {child_name}")
        
        stories = self.story_repository.find_by_child_name(child_name)
        logger.info(f"Retrieved {len(stories)} stories for child: {child_name}")
        
        return [self._to_response_dto(story) for story in stories]
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class ListStoriesByLanguageUseCase:
    """Use case for listing stories by language."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self, language_code: str) -> List[StoryDBResponseDTO]:
        """List stories by language.
        
        Args:
            language_code: Language code (en, ru)
            
        Returns:
            List of story responses
        """
        logger.debug(f"Listing stories for language: {language_code}")
        
        language = Language.from_code(language_code)
        stories = self.story_repository.find_by_language(language)
        logger.info(f"Retrieved {len(stories)} stories for language: {language_code}")
        
        return [self._to_response_dto(story) for story in stories]
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class RateStoryUseCase:
    """Use case for rating a story."""
    
    def __init__(
        self,
        story_repository: StoryRepository,
        story_service: StoryService
    ):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
            story_service: Story domain service
        """
        self.story_repository = story_repository
        self.story_service = story_service
    
    def execute(self, story_id: str, request: StoryRatingRequestDTO) -> StoryDBResponseDTO:
        """Rate a story.
        
        Args:
            story_id: Story ID
            request: Rating request
            
        Returns:
            Updated story response
            
        Raises:
            NotFoundError: If story not found
        """
        logger.info(f"Rating story {story_id} with {request.rating}")
        
        # Create rating value object
        rating = Rating(value=request.rating)
        
        # Update rating in repository
        story = self.story_repository.update_rating(story_id, rating)
        if not story:
            raise NotFoundError("Story", story_id)
        
        logger.info(f"Story rated: {story_id} - {request.rating}/10")
        return self._to_response_dto(story)
    
    def _to_response_dto(self, story: Story) -> StoryDBResponseDTO:
        """Convert story entity to response DTO."""
        return StoryDBResponseDTO(
            id=story.id,
            title=story.title,
            content=story.content,
            moral=story.moral,
            language=story.language.value,
            child_id=story.child_id,
            child_name=story.child_name,
            age_category=story.age_category,
            child_gender=story.child_gender,
            child_interests=story.child_interests,
            story_length=story.story_length.minutes if story.story_length else None,
            rating=story.rating.value if story.rating else None,
            audio_file_url=story.audio_file.url if story.audio_file else None,
            audio_provider=story.audio_file.provider if story.audio_file else None,
            audio_generation_metadata=story.audio_file.metadata if story.audio_file else None,
            model_used=story.model_used,
            created_at=story.created_at.isoformat() if story.created_at else None,
            updated_at=story.updated_at.isoformat() if story.updated_at else None
        )


class DeleteStoryUseCase:
    """Use case for deleting a story."""
    
    def __init__(self, story_repository: StoryRepository):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
        """
        self.story_repository = story_repository
    
    def execute(self, story_id: str) -> bool:
        """Delete a story.
        
        Args:
            story_id: Story ID
            
        Returns:
            True if deleted
            
        Raises:
            NotFoundError: If story not found
        """
        logger.info(f"Deleting story with ID: {story_id}")
        
        deleted = self.story_repository.delete(story_id)
        if not deleted:
            raise NotFoundError("Story", story_id)
        
        logger.info(f"Story deleted: {story_id}")
        return True
