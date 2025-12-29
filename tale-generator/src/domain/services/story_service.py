"""Story generation service."""

from typing import Optional, Dict, Any
from datetime import datetime
from src.domain.entities import Story, Child
from src.domain.value_objects import Language, StoryLength
from src.core.logging import get_logger
from src.core.exceptions import ValidationError

logger = get_logger("domain.story_service")


class StoryService:
    """Service for orchestrating story generation workflow."""
    
    def create_story(
        self,
        title: str,
        content: str,
        moral: str,
        language: Language,
        child: Optional[Child] = None,
        story_length: Optional[StoryLength] = None,
        model_used: Optional[str] = None,
        full_response: Optional[Dict[str, Any]] = None,
        generation_info: Optional[Dict[str, Any]] = None
    ) -> Story:
        """Create a new story entity.
        
        Args:
            title: Story title
            content: Story content
            moral: Moral value
            language: Story language
            child: Child entity (optional)
            story_length: Story length
            model_used: AI model used
            full_response: Full API response
            generation_info: Generation metadata
            
        Returns:
            Story entity
        """
        logger.debug(f"Creating story with title: {title}")
        
        # Create story entity
        story = Story(
            title=title,
            content=content,
            moral=moral,
            language=language,
            child_id=child.id if child else None,
            child_name=child.name if child else None,
            child_age_category=child.age_category if child else None,
            child_gender=child.gender.value if child else None,
            child_interests=child.interests if child else None,
            story_length=story_length,
            model_used=model_used,
            full_response=full_response,
            generation_info=generation_info,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        logger.info(f"Story created: {title}")
        return story
    
    def extract_title_from_content(self, content: str) -> str:
        """Extract title from story content.
        
        Args:
            content: Story content
            
        Returns:
            Extracted title
        """
        lines = content.strip().split('\n')
        if lines:
            title = lines[0].replace('#', '').strip()
            return title if title else "A Bedtime Story"
        return "A Bedtime Story"
    
    def attach_audio_to_story(
        self,
        story: Story,
        audio_url: str,
        provider: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> None:
        """Attach audio file to story.
        
        Args:
            story: Story entity
            audio_url: Audio file URL
            provider: Audio provider name
            metadata: Audio metadata
        """
        logger.debug(f"Attaching audio to story: {story.title}")
        story.attach_audio(audio_url, provider, metadata)
        logger.info(f"Audio attached to story: {story.title}")
    
    def rate_story(self, story: Story, rating_value: int) -> None:
        """Rate a story.
        
        Args:
            story: Story entity
            rating_value: Rating value (1-10)
        """
        logger.debug(f"Rating story {story.title} with {rating_value}")
        story.rate(rating_value)
        logger.info(f"Story rated: {story.title} - {rating_value}/10")
    
    def validate_story_request(
        self,
        child: Child,
        moral: str,
        language: Language,
        story_length: Optional[int] = None
    ) -> None:
        """Validate story generation request.
        
        Args:
            child: Child entity
            moral: Moral value
            language: Language
            story_length: Story length in minutes
            
        Raises:
            ValidationError: If validation fails
        """
        # Child is already validated by entity
        
        # Validate moral
        if not moral or not moral.strip():
            raise ValidationError("Moral value cannot be empty", field="moral")
        
        # Validate story length if provided
        if story_length is not None and story_length <= 0:
            raise ValidationError(
                "Story length must be positive",
                field="story_length",
                details={"value": story_length}
            )
        
        logger.debug("Story request validated successfully")
