"""Async generate story use case with LangGraph workflow support."""

import uuid
from typing import Optional
from datetime import datetime

from src.application.dto import StoryRequestDTO, StoryResponseDTO
from src.domain.entities import Child, Story, Hero
from src.domain.value_objects import Gender, Language, StoryLength
from src.domain.repositories.child_repository import ChildRepository
from src.domain.repositories.hero_repository import HeroRepository
from src.domain.repositories.story_repository import StoryRepository
from src.domain.services.story_service import StoryService
from src.domain.services.prompt_service import PromptService
from src.domain.services.audio_service import AudioService
from src.domain.services.langgraph import LangGraphWorkflowService
from src.core.logging import get_logger
from src.core.exceptions import ExternalServiceError, ValidationError

logger = get_logger("application.generate_story_async")


class GenerateStoryUseCaseAsync:
    """Async use case for generating bedtime stories with LangGraph workflow support."""
    
    def __init__(
        self,
        story_repository: StoryRepository,
        child_repository: ChildRepository,
        hero_repository: HeroRepository,
        story_service: StoryService,
        prompt_service: PromptService,
        audio_service: AudioService,
        ai_service,
        storage_service
    ):
        """Initialize use case.
        
        Args:
            story_repository: Story repository
            child_repository: Child repository
            hero_repository: Hero repository
            story_service: Story domain service
            prompt_service: Prompt generation service
            audio_service: Audio generation service
            ai_service: AI service for story generation
            storage_service: Storage service for audio files
        """
        self.story_repository = story_repository
        self.child_repository = child_repository
        self.hero_repository = hero_repository
        self.story_service = story_service
        self.prompt_service = prompt_service
        self.audio_service = audio_service
        self.ai_service = ai_service
        self.storage_service = storage_service
        
        # Initialize LangGraph workflow service (always enabled)
        # Check if storage_service is AsyncSupabaseClient (has create_generation method)
        supabase_client = None
        if hasattr(storage_service, 'create_generation'):
            # storage_service is AsyncSupabaseClient
            supabase_client = storage_service
            logger.info("Supabase client available for generation tracking")
        else:
            logger.warning("Supabase client not available - generation tracking will be disabled")
        
        self.langgraph_service = LangGraphWorkflowService(
            openrouter_client=ai_service,
            prompt_service=prompt_service,
            child_repository=child_repository,
            hero_repository=hero_repository,
            supabase_client=supabase_client
        )
        logger.info("LangGraph workflow initialized")
    
    async def execute(
        self,
        request: StoryRequestDTO,
        story_type: str = "child",
        hero_id: Optional[str] = None,
        user_id: str = ""
    ) -> StoryResponseDTO:
        """Execute story generation use case.
        
        Args:
            request: Story generation request
            story_type: Type of story (child/hero/combined)
            hero_id: Optional hero ID for hero/combined stories
            user_id: User ID for tracking
            
        Returns:
            Generated story response
        """
        logger.info(f"Generating {story_type} story for child {request.child.name}")
        
        # 1. Find or create child entity
        child = await self._get_or_create_child(request)
        
        # 2. Get hero entity if needed
        hero = None
        if story_type in ["hero", "combined"] and hero_id:
            hero = await self._get_hero(hero_id)
        
        # 3. Determine moral and story length
        moral = request.custom_moral if request.custom_moral else (
            request.moral.value if request.moral else "kindness"
        )
        story_length = StoryLength(minutes=request.story_length or 5)
        
        # 4. Validate request
        self.story_service.validate_story_request(child, moral, request.language, story_length.minutes)
        
        # 5. Generate story using LangGraph workflow
        story, quality_metadata, validation_result, workflow_metadata = await self._generate_with_langgraph(
            child=child,
            hero=hero,
            moral=moral,
            language=request.language,
            story_length=story_length,
            story_type=story_type,
            user_id=user_id
        )
        
        # 6. Generate audio if requested
        audio_url = None
        if request.generate_audio:
            audio_url = await self._generate_and_upload_audio(
                story=story,
                request=request
            )
        
        # 7. Save story to repository with quality metadata
        # Add quality metadata to story
        story.quality_score = quality_metadata.get("overall_score")
        story.generation_attempts_count = quality_metadata.get("attempts_count", 1)
        story.selected_attempt_number = quality_metadata.get("selected_attempt_number", 1)
        story.quality_metadata = quality_metadata
        story.validation_result = validation_result
        story.workflow_metadata = workflow_metadata
        
        saved_story = await self.story_repository.save(story)
        logger.info(f"Story saved with ID: {saved_story.id}")
        
        # 8. Return response
        return StoryResponseDTO(
            title=saved_story.title,
            content=saved_story.content,
            moral=saved_story.moral,
            language=saved_story.language,
            story_length=story_length.minutes,
            audio_file_url=audio_url
        )
    
    async def _generate_with_langgraph(
        self,
        child: Child,
        hero: Optional[Hero],
        moral: str,
        language: Language,
        story_length: StoryLength,
        story_type: str,
        user_id: str
    ) -> tuple[Story, dict, dict, dict]:
        """Generate story using LangGraph workflow.
        
        Args:
            child: Child entity
            hero: Optional hero entity
            moral: Moral value
            language: Story language
            story_length: Story length
            story_type: Type of story
            user_id: User ID
            
        Returns:
            Tuple of (Story entity, quality metadata, validation result, workflow metadata)
            
        Raises:
            ValidationError: If prompt validation fails
            ExternalServiceError: If generation fails
        """
        logger.info("Using LangGraph workflow for story generation")
        
        # Execute workflow
        result = await self.langgraph_service.execute_workflow(
            child=child,
            moral=moral,
            language=language,
            story_length=story_length,
            story_type=story_type,
            hero=hero,
            user_id=user_id
        )
        
        # Check if workflow succeeded
        if not result.success:
            # Check if it was validation rejection
            if result.validation_result and result.validation_result.get("recommendation") == "rejected":
                raise ValidationError(
                    message=result.error_message,
                    field="prompt",
                    details=result.validation_result
                )
            else:
                raise ExternalServiceError(
                    service="LangGraph Workflow",
                    message=result.error_message
                )
        
        # Create story entity from workflow result
        story = self.story_service.create_story(
            title=result.story_title,
            content=result.story_content,
            moral=moral,
            language=language,
            child=child,
            story_length=story_length,
            model_used=result.all_attempts[result.selected_attempt_number - 1].get("model_used") if result.all_attempts else None,
            full_response=None,  # Not available from workflow
            generation_info=None
        )
        
        return story, result.quality_metadata, result.validation_result, result.workflow_metadata
    
    async def _get_or_create_child(self, request: StoryRequestDTO) -> Child:
        """Get existing child or create new one.
        
        Args:
            request: Story request
            
        Returns:
            Child entity
        """
        # Try to find exact match
        gender = Gender(request.child.gender.value)
        # For backward compatibility, calculate age from age_category if needed
        age = 4  # Default
        if hasattr(request.child, 'age_category'):
            if request.child.age_category == '2-3':
                age = 2
            elif request.child.age_category == '3-5':
                age = 4
            elif request.child.age_category == '5-7':
                age = 6
        else:
            age = request.child.age if hasattr(request.child, 'age') else 4
        
        existing_child = await self.child_repository.find_exact_match(
            name=request.child.name,
            age=age,
            gender=gender
        )
        
        if existing_child:
            logger.debug(f"Found existing child: {existing_child.id}")
            return existing_child
        
        # Create new child
        logger.debug(f"Creating new child: {request.child.name}")
        age_category = request.child.age_category if hasattr(request.child, 'age_category') else '3-5'
        child = Child(
            name=request.child.name,
            age_category=age_category,
            gender=gender,
            interests=request.child.interests,
            age=age,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        return await self.child_repository.save(child)
    
    async def _get_hero(self, hero_id: str) -> Hero:
        """Get hero by ID.
        
        Args:
            hero_id: Hero UUID
            
        Returns:
            Hero entity
            
        Raises:
            ValidationError: If hero not found
        """
        hero = await self.hero_repository.find_by_id(hero_id)
        
        if not hero:
            raise ValidationError(
                message=f"Hero not found: {hero_id}",
                field="hero_id"
            )
        
        return hero
    
    async def _generate_and_upload_audio(
        self,
        story: Story,
        request: StoryRequestDTO
    ) -> Optional[str]:
        """Generate audio and upload to storage.
        
        Args:
            story: Story entity
            request: Story request with audio options
            
        Returns:
            Audio file URL or None
        """
        try:
            # Generate audio
            audio_result = await self.audio_service.generate_audio(
                text=story.content,
                language=request.language,
                provider_name=request.voice_provider,
                voice_options=request.voice_options
            )
            
            if not audio_result.success or not audio_result.audio_data:
                logger.warning(f"Audio generation failed: {audio_result.error_message}")
                return None
            
            # Upload to storage
            filename = f"{uuid.uuid4()}.mp3"
            audio_url = await self.storage_service.upload_audio_file(
                file_data=audio_result.audio_data,
                filename=filename,
                story_id=story.id or "pending"
            )
            
            if audio_url:
                # Attach audio to story
                self.story_service.attach_audio_to_story(
                    story=story,
                    audio_url=audio_url,
                    provider=audio_result.provider_name,
                    metadata=audio_result.metadata
                )
                logger.info(f"Audio uploaded: {audio_url}")
                return audio_url
            else:
                logger.warning("Failed to upload audio file")
                return None
                
        except Exception as e:
            logger.error(f"Error generating/uploading audio: {str(e)}", exc_info=True)
            return None
