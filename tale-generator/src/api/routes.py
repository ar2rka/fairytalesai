"""API routes for the tale generator service."""

import logging
import uuid
from fastapi import APIRouter, HTTPException, Depends
from typing import Optional, Tuple, List
from datetime import datetime

from src.models import StoryDB, ChildDB
from src.application.dto import (
    GenerateStoryRequestDTO, 
    GenerateStoryResponseDTO, 
    ChildInfoDTO, 
    HeroInfoDTO,
    ChildRequestDTO,
    FreeStoryResponseDTO
)
from src.openrouter_client import OpenRouterClient, StoryGenerationResult
from src.supabase_client_async import AsyncSupabaseClient
from src.voice_providers import get_voice_service, get_registry, ElevenLabsProvider
from src.api.auth import get_current_user, AuthUser
from src.api.subscription_validator import SubscriptionValidator
from src.domain.services.subscription_service import SubscriptionService
from src.domain.value_objects import Language, StoryLength, Gender
from src.domain.services.prompt_service import PromptService
from src.domain.entities import Child, Hero
from src.infrastructure.persistence.models import GenerationDB

# Set up logger
logger = logging.getLogger("tale_generator.api")

router = APIRouter()


# ============================================================================
# SERVICE INITIALIZATION
# ============================================================================

def _initialize_openrouter_client() -> Optional[OpenRouterClient]:
    """Initialize OpenRouter client with error handling."""
    try:
        client = OpenRouterClient()
        logger.info("OpenRouter client initialized successfully")
        return client
    except ValueError as e:
        logger.warning(f"OpenRouter client initialization failed: {e}")
        return None


def _initialize_supabase_client() -> Optional[AsyncSupabaseClient]:
    """Initialize Supabase client with error handling."""
    try:
        client = AsyncSupabaseClient()
        logger.info("Async Supabase client initialized successfully")
        return client
    except ValueError as e:
        logger.warning(f"Async Supabase client initialization failed: {e}")
        return None


def _initialize_voice_service():
    """Initialize voice service with providers."""
    try:
        voice_registry = get_registry()
        
        # Register ElevenLabs provider
        try:
            elevenlabs_provider = ElevenLabsProvider()
            voice_registry.register(elevenlabs_provider)
            logger.info("ElevenLabs provider registered successfully")
        except Exception as e:
            logger.warning(f"ElevenLabs provider registration failed: {e}")
        
        service = get_voice_service()
        logger.info("Voice service initialized successfully")
        return service
    except Exception as e:
        logger.warning(f"Voice service initialization failed: {e}")
        return None


# Initialize services
openrouter_client = _initialize_openrouter_client()
supabase_client = _initialize_supabase_client()
voice_service = _initialize_voice_service()

# Initialize prompt service with Supabase client if available
# Note: PromptRepository needs sync client, so we get it from async client
_sync_supabase_client = None
if supabase_client and hasattr(supabase_client, '_sync_client'):
    _sync_supabase_client = supabase_client._sync_client
prompt_service = PromptService(_sync_supabase_client)
logger.info("Prompt service initialized successfully")


# ============================================================================
# VALIDATION HELPERS
# ============================================================================

def _validate_language(language: str) -> Language:
    """Validate and convert language string to Language enum."""
    if language not in ["en", "ru"]:
        logger.warning(f"Invalid language: {language}")
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language: {language}. Supported: en, ru"
        )
    return Language.ENGLISH if language == "en" else Language.RUSSIAN


def _validate_story_type(story_type: str, hero_id: Optional[str]) -> None:
    """Validate story type and required fields."""
    if story_type not in ["child", "hero", "combined"]:
        logger.warning(f"Invalid story type: {story_type}")
        raise HTTPException(
            status_code=400,
            detail=f"Invalid story type: {story_type}. Supported: child, hero, combined"
        )
    
    if story_type in ["hero", "combined"] and not hero_id:
        logger.warning(f"Hero ID missing for {story_type} story")
        raise HTTPException(
            status_code=400,
            detail=f"Hero ID is required for {story_type} stories"
        )


def _validate_services() -> None:
    """Validate that required services are initialized."""
    if openrouter_client is None:
        logger.error("OpenRouter API key not configured")
        raise HTTPException(
            status_code=500,
            detail="OpenRouter API key not configured"
        )
    
    if supabase_client is None:
        logger.error("Supabase not configured")
        raise HTTPException(
            status_code=500,
            detail="Supabase not configured"
        )


# ============================================================================
# DATA FETCHING & CONVERSION HELPERS
# ============================================================================

async def _fetch_and_convert_child(child_id: str, user_id: str) -> Child:
    """Fetch child from database and convert to domain entity."""
    logger.debug(f"Fetching child with ID: {child_id}")
    child_db = await supabase_client.get_child(child_id)
    
    if not child_db:
        logger.warning(f"Child not found: {child_id}")
        raise HTTPException(
            status_code=404,
            detail=f"Child with ID {child_id} not found"
        )
    
    # Verify the child belongs to the authenticated user
    if hasattr(child_db, 'user_id') and child_db.user_id != user_id:
        logger.warning(f"User {user_id} attempted to access child {child_id} belonging to another user")
        raise HTTPException(
            status_code=403,
            detail="You don't have permission to use this child profile"
        )
    
    return Child(
        id=child_db.id,
        name=child_db.name,
        age_category=child_db.age_category,
        gender=Gender(child_db.gender),
        interests=child_db.interests,
        age=child_db.age,  # For backward compatibility
        created_at=child_db.created_at,
        updated_at=child_db.updated_at
    )


async def _fetch_and_convert_hero(hero_id: str, expected_language: Language) -> Hero:
    """Fetch hero from database and convert to domain entity."""
    logger.debug(f"Fetching hero with ID: {hero_id}")
    hero_db = await supabase_client.get_hero(hero_id)
    
    if not hero_db:
        logger.warning(f"Hero not found: {hero_id}")
        raise HTTPException(
            status_code=404,
            detail=f"Hero with ID {hero_id} not found"
        )
    
    # Validate hero language matches requested language
    hero_language = Language(hero_db.language.value if hasattr(hero_db.language, 'value') else hero_db.language)
    if hero_language != expected_language:
        logger.warning(f"Hero language mismatch: {hero_language.value} != {expected_language.value}")
        raise HTTPException(
            status_code=400,
            detail=f"Hero language {hero_language.value} does not match requested language {expected_language.value}"
        )
    
    return Hero(
        id=hero_db.id,
        name=hero_db.name,
        age=5,  # Default age if not in HeroDB
        gender=Gender(hero_db.gender) if isinstance(hero_db.gender, str) else hero_db.gender,
        appearance=hero_db.appearance,
        personality_traits=hero_db.personality_traits,
        interests=hero_db.interests,
        strengths=hero_db.strengths,
        language=hero_language,
        created_at=hero_db.created_at,
        updated_at=hero_db.updated_at
    )


# ============================================================================
# STORY GENERATION HELPERS
# ============================================================================

def _determine_moral(request: GenerateStoryRequestDTO) -> str:
    """Determine the moral value for the story."""
    if request.custom_moral:
        return request.custom_moral
    elif request.moral:
        return request.moral
    else:
        return "kindness"


def _generate_prompt(
    story_type: str,
    child: Child,
    hero: Optional[Hero],
    moral: str,
    language: Language,
    story_length: StoryLength,
    parent_story: Optional[StoryDB] = None
) -> str:
    """Generate appropriate prompt based on story type."""
    if story_type == "child":
        logger.info(f"Generating child story for {child.name}")
        return prompt_service.generate_child_prompt(child, moral, language, story_length, parent_story)
    elif story_type == "hero":
        logger.info(f"Generating hero story for {hero.name}")
        return prompt_service.generate_hero_prompt(hero, moral, story_length, parent_story)
    else:  # combined
        logger.info(f"Generating combined story for {child.name} and {hero.name}")
        return prompt_service.generate_combined_prompt(child, hero, moral, language, story_length, parent_story)


async def _create_generation_record(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str
) -> None:
    """Create initial generation tracking record with pending status."""
    generation_data = GenerationDB(
        generation_id=generation_id,
        attempt_number=1,
        model_used="",
        full_response=None,
        prompt=prompt,
        user_id=user_id,
        story_type=story_type,
        story_length=story_length,
        hero_appearance=hero.appearance if hero else None,
        relationship_description=None,
        moral=moral,
        status="pending",
        error_message=None,
        created_at=datetime.now()
    )
    
    try:
        await supabase_client.create_generation(generation_data)
        logger.info(f"Generation record created: {generation_id}")
    except Exception as e:
        logger.error(f"Failed to create generation record: {str(e)}")


async def _update_generation_success(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str,
    model_used: str,
    full_response: str,
    attempt_number: int = 1
) -> None:
    """Update generation record with success status and results."""
    generation_data = GenerationDB(
        generation_id=generation_id,
        attempt_number=attempt_number,
        model_used=model_used,
        full_response=full_response,
        status="success",
        prompt=prompt,
        user_id=user_id,
        story_type=story_type,
        story_length=story_length,
        hero_appearance=hero.appearance if hero else None,
        relationship_description=None,
        moral=moral,
        error_message=None,
        completed_at=datetime.now()
    )
    
    try:
        await supabase_client.update_generation(generation_data)
        logger.info(f"Generation {generation_id} updated with success status")
    except Exception as e:
        logger.error(f"Failed to update generation success: {str(e)}")


async def _update_generation_failure(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str,
    error_message: str,
    attempt_number: int = 1
) -> None:
    """Update generation record with failed status and error details."""
    generation_data = GenerationDB(
        generation_id=generation_id,
        attempt_number=attempt_number,
        model_used="unknown",
        full_response=None,
        status="failed",
        prompt=prompt,
        user_id=user_id,
        story_type=story_type,
        story_length=story_length,
        hero_appearance=hero.appearance if hero else None,
        relationship_description=None,
        moral=moral,
        error_message=error_message,
        completed_at=datetime.now()
    )
    
    try:
        await supabase_client.update_generation(generation_data)
        logger.info(f"Generation {generation_id} updated with failed status")
    except Exception as e:
        logger.error(f"Failed to update generation failure: {str(e)}")


async def _generate_story_content(
    prompt: str,
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    child: Child,
    language: Language
) -> StoryGenerationResult:
    """Generate story content using LangGraph workflow with retry and tracking."""
    
    try:
        result = await openrouter_client.generate_story(
            prompt,
            max_retries=3,
            retry_delay=1.0,
            use_langgraph=True,  # Always use LangGraph workflow
            child_name=child.name,
            child_age=child.age,
            child_gender=child.gender.value,
            child_interests=child.interests or [],
            moral=moral,
            language=language.value,
            story_length_minutes=story_length,
            user_id=user_id
        )
        
        # Update with success
        await _update_generation_success(
            generation_id=generation_id,
            user_id=user_id,
            story_type=story_type,
            story_length=story_length,
            hero=hero,
            moral=moral,
            prompt=prompt,
            model_used=result.model.value if result.model else "unknown",
            full_response=result.full_response,
            attempt_number=1  # TODO: Track actual attempt number from retry logic
        )
        
        return result
        
    except Exception as gen_error:
        # Update with failure
        await _update_generation_failure(
            generation_id=generation_id,
            user_id=user_id,
            story_type=story_type,
            story_length=story_length,
            hero=hero,
            moral=moral,
            prompt=prompt,
            error_message=str(gen_error),
            attempt_number=1  # TODO: Track actual attempt number from retry logic
        )
        
        raise HTTPException(
            status_code=500,
            detail=f"Story generation failed: {str(gen_error)}"
        )


def _clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers.
    
    Args:
        content: Raw story content from AI
        
    Returns:
        Cleaned content without formatting markers
    """
    # Remove **** markers and other excessive formatting
    import re
    
    # Remove sequences of 3 or more asterisks
    cleaned = re.sub(r'\*{3,}', '', content)
    
    # Remove sequences of 3 or more underscores
    cleaned = re.sub(r'_{3,}', '', cleaned)
    
    # Remove sequences of 3 or more hyphens (but not in words)
    cleaned = re.sub(r'(?<!\w)-{3,}(?!\w)', '', cleaned)
    
    # Clean up any excessive whitespace that might have been left
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    
    return cleaned.strip()


def _extract_title(content: str) -> str:
    """Extract title from story content."""
    lines = content.strip().split('\n')
    title = lines[0].replace('#', '').strip() if lines else "A Bedtime Story"
    logger.debug(f"Extracted title: {title}")
    return title


async def _generate_summary(content: str, title: str, language: Language) -> str:
    """Generate a summary of the story in a few sentences.
    
    Args:
        content: The full story content
        title: The story title
        language: The language of the story
        
    Returns:
        A summary of the story in 2-3 sentences
    """
    if not openrouter_client:
        logger.warning("OpenRouter client not available, skipping summary generation")
        return ""
    
    try:
        # Build summary prompt based on language
        if language == Language.RUSSIAN:
            summary_prompt = f"""Создай краткое резюме этой сказки в 2-3 предложениях. Резюме должно передавать основную сюжетную линию и главную мораль истории.

Название: {title}

Сказка:
{content}

Резюме (2-3 предложения):"""
        else:
            summary_prompt = f"""Create a brief summary of this story in 2-3 sentences. The summary should convey the main plot and moral of the story.

Title: {title}

Story:
{content}

Summary (2-3 sentences):"""
        
        logger.info("Generating story summary...")
        result = await openrouter_client.generate_story(
            summary_prompt,
            model="openai/gpt-4o-mini",
            max_tokens=200,
            temperature=0.5,
            use_langgraph=False  # Direct API call for summary
        )
        
        summary = result.content.strip()
        # Remove any markdown formatting if present
        summary = summary.replace("**", "").replace("*", "").strip()
        
        logger.info(f"Summary generated: {summary[:100]}...")
        return summary
        
    except Exception as e:
        logger.error(f"Error generating summary: {str(e)}", exc_info=True)
        return ""  # Return empty string on error, don't fail the whole request


# ============================================================================
# AUDIO GENERATION HELPERS
# ============================================================================

async def _generate_audio(
    content: str,
    language: str,
    provider_name: Optional[str],
    voice_options: Optional[dict],
    story_id: str
) -> Tuple[Optional[str], Optional[str], Optional[dict]]:
    """Generate audio for story content.
    
    Args:
        content: Story content to convert to audio
        language: Language code
        provider_name: Audio provider name
        voice_options: Voice generation options
        story_id: Story ID to use for the audio filename
    
    Returns:
        Tuple of (audio_file_url, audio_provider, audio_metadata)
    """
    if voice_service is None:
        logger.warning("Voice service not available")
        return None, None, None
    
    try:
        logger.info("Generating audio for story")
        audio_result = await voice_service.generate_audio(
            text=content,
            language=language,
            provider_name=provider_name,
            voice_options=voice_options
        )
        
        if not audio_result.success or not audio_result.audio_data:
            error_msg = audio_result.error_message if audio_result else "Unknown error"
            logger.warning(f"Failed to generate audio: {error_msg}")
            return None, None, None
        
        # Upload audio file
        audio_filename = f"{story_id}.mp3"
        audio_file_url = await supabase_client.upload_audio_file(
            file_data=audio_result.audio_data,
            filename=audio_filename,
            story_id=story_id
        )
        
        if audio_file_url:
            logger.info(f"Audio file uploaded successfully: {audio_file_url}")
            return audio_file_url, audio_result.provider_name, audio_result.metadata
        else:
            logger.warning("Failed to upload audio file to Supabase storage")
            return None, None, None
            
    except Exception as e:
        logger.error(f"Error generating or uploading audio: {str(e)}", exc_info=True)
        return None, None, None


# ============================================================================
# RESPONSE BUILDING HELPERS
# ============================================================================

def _generate_relationship_description(
    story_type: str,
    child: Child,
    hero: Optional[Hero],
    language: Language
) -> Optional[str]:
    """Generate relationship description for combined stories."""
    if story_type != "combined" or not hero:
        return None
    
    if language == Language.ENGLISH:
        return f"{child.name} meets the legendary {hero.name}"
    else:
        return f"{child.name} встречает легендарного героя {hero.name}"


async def _save_story(
    title: str,
    content: str,
    summary: str,
    generation_id: str,
    moral: str,
    child: Child,
    hero: Optional[Hero],
    language: Language,
    audio_file_url: Optional[str],
    user_id: str,
    parent_id: Optional[str] = None
) -> Optional[StoryDB]:
    """Save story to database.
    
    Note: Content should already be cleaned before calling this function.
    """
    now = datetime.now()
    story_db = StoryDB(
        title=title,
        content=content,
        summary=summary,
        generation_id=generation_id,
        moral=moral,
        child_id=child.id,
        child_name=child.name,
        child_age=child.age,
        child_gender=child.gender.value,
        child_interests=child.interests,
        hero_id=hero.id if hero else None,
        language=language,
        audio_file_url=audio_file_url,
        parent_id=parent_id,
        created_at=now,
        updated_at=now
    )
    
    # Add user_id
    story_dict = story_db.model_dump()
    story_dict['user_id'] = user_id
    story_db_with_user = StoryDB(**story_dict)
    
    try:
        saved_story = await supabase_client.save_story(story_db_with_user)
        logger.info(f"Story saved to database with ID: {saved_story.id}, user: {user_id}, parent_id: {parent_id}")
        return saved_story
    except Exception as e:
        logger.error(f"Failed to save story to database: {str(e)}")
        return None


def _build_response(
    story_id: str,
    title: str,
    content: str,
    moral: str,
    language: Language,
    story_type: str,
    story_length: int,
    child: Child,
    hero: Optional[Hero],
    relationship_description: Optional[str],
    audio_file_url: Optional[str],
    created_at: datetime
) -> GenerateStoryResponseDTO:
    """Build the API response DTO."""
    child_info = ChildInfoDTO(
        id=child.id,
        name=child.name,
        age=child.age,
        gender=child.gender.value,
        interests=child.interests
    )
    
    hero_info = None
    if hero:
        hero_info = HeroInfoDTO(
            id=hero.id,
            name=hero.name,
            gender=hero.gender.value,
            appearance=hero.appearance
        )
    
    return GenerateStoryResponseDTO(
        id=story_id,
        title=title,
        content=content,
        moral=moral,
        language=language.value,
        story_type=story_type,
        story_length=story_length,
        child=child_info,
        hero=hero_info,
        relationship_description=relationship_description,
        audio_file_url=audio_file_url,
        created_at=created_at.isoformat()
    )


# ============================================================================
# API ENDPOINTS
# ============================================================================

@router.post("/stories/generate", response_model=GenerateStoryResponseDTO)
async def generate_story(
    request: GenerateStoryRequestDTO,
    user: AuthUser = Depends(get_current_user)
):
    """Generate a bedtime story with support for child, hero, and combined types."""
    try:
        # Initialize subscription validator
        subscription_validator = SubscriptionValidator()
        
        # Validate subscription and limits BEFORE processing
        subscription = await subscription_validator.validate_story_generation(
            user=user,
            story_type=request.story_type,
            story_length=request.story_length or 5,
            generate_audio=request.generate_audio or False
        )
        
        logger.info(f"Subscription validated for user {user.user_id}, plan: {subscription.plan.value}")
        
        # Validate services
        _validate_services()
        
        # Validate request
        language = _validate_language(request.language)
        _validate_story_type(request.story_type, request.hero_id)
        
        # Fetch and convert entities
        child = await _fetch_and_convert_child(request.child_id, user.user_id)
        
        hero = None
        if request.story_type in ["hero", "combined"]:
            hero = await _fetch_and_convert_hero(request.hero_id, language)
        
        # Determine story parameters
        moral = _determine_moral(request)
        story_length = StoryLength(minutes=request.story_length or 5)
        
        logger.debug(f"Using moral: {moral}")
        
        # Fetch parent story if parent_id is provided
        parent_story = None
        if request.parent_id:
            parent_story = await supabase_client.get_story(request.parent_id, user.user_id)
            if not parent_story:
                raise HTTPException(
                    status_code=404,
                    detail=f"Parent story with ID {request.parent_id} not found or access denied"
                )
            logger.info(f"Using parent story: {parent_story.title} (ID: {parent_story.id})")
        
        # Generate prompt
        prompt = _generate_prompt(
            request.story_type,
            child,
            hero,
            moral,
            language,
            story_length,
            parent_story
        )
        
        # Generate story content
        generation_id = str(uuid.uuid4())
        logger.info(f"Created generation ID: {generation_id}")

        await _create_generation_record(
            generation_id=generation_id,
            user_id=user.user_id,
            story_type=request.story_type,
            story_length=story_length.minutes,
            hero=hero,
            moral=moral,
            prompt=prompt
        )
        
        result = await _generate_story_content(
            prompt=prompt,
            generation_id=generation_id,
            user_id=user.user_id,
            story_type=request.story_type,
            story_length=story_length.minutes,
            hero=hero,
            moral=moral,
            child=child,
            language=language
        )
        
        # Clean the content to remove formatting markers
        cleaned_content = _clean_story_content(result.content)
        
        # Extract title
        title = _extract_title(cleaned_content)
        
        # Generate summary
        summary = await _generate_summary(cleaned_content, title, language)
        
        # Generate relationship description
        relationship_description = _generate_relationship_description(
            request.story_type,
            child,
            hero,
            language
        )
        
        # Save story to database first (to get story_id)
        now = datetime.now()
        saved_story = await _save_story(
            title=title,
            content=cleaned_content,
            summary=summary,
            generation_id=generation_id,
            moral=moral,
            child=child,
            hero=hero,
            language=language,
            audio_file_url=None,  # Will be updated after audio generation
            user_id=user.user_id,
            parent_id=request.parent_id
        )
        
        # Get story ID (fallback to uuid if save failed)
        story_id = saved_story.id if saved_story else str(uuid.uuid4())
        
        # Generate audio if requested (now we have story_id)
        audio_file_url, audio_provider, audio_metadata = None, None, None
        if request.generate_audio:
            audio_file_url, audio_provider, audio_metadata = await _generate_audio(
                content=cleaned_content,
                language=language.value,
                provider_name=request.voice_provider,
                voice_options=request.voice_options,
                story_id=story_id
            )
            
            # Update story with audio URL if generation was successful
            if audio_file_url and saved_story:
                try:
                    await supabase_client.update_story_audio(
                        story_id=story_id,
                        audio_file_url=audio_file_url,
                        audio_provider=audio_provider,
                        audio_metadata=audio_metadata
                    )
                    logger.info(f"Story {story_id} updated with audio URL")
                except Exception as audio_update_error:
                    logger.warning(f"Failed to update story with audio URL: {str(audio_update_error)}")
        
        # Increment story count and track usage AFTER successful generation
        try:
            await supabase_client.increment_story_count(user.user_id)
            await supabase_client.track_usage(
                user_id=user.user_id,
                action_type='story_generation',
                resource_id=story_id,
                metadata={
                    'plan': subscription.plan.value,
                    'story_type': request.story_type,
                    'story_length': story_length.minutes,
                    'audio_generated': request.generate_audio or False
                }
            )
            logger.info(f"Usage tracked for user {user.user_id}, story {story_id}")
        except Exception as tracking_error:
            # Don't fail the request if tracking fails, just log it
            logger.warning(f"Failed to track usage: {str(tracking_error)}")
        
        logger.info(f"Story generation completed successfully for {request.story_type} story")
        
        return _build_response(
            story_id=story_id,
            title=title,
            content=cleaned_content,
            moral=moral,
            language=language,
            story_type=request.story_type,
            story_length=story_length.minutes,
            child=child,
            hero=hero,
            relationship_description=relationship_description,
            audio_file_url=audio_file_url,
            created_at=now
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating story: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error generating story: {str(e)}"
        )


@router.post("/children")
async def create_child(
    request: ChildRequestDTO,
    user: AuthUser = Depends(get_current_user)
):
    """Create a new child profile with subscription limit validation."""
    try:
        # Initialize subscription validator
        subscription_validator = SubscriptionValidator()
        
        # Validate subscription and child limit BEFORE creation
        subscription = await subscription_validator.validate_child_creation(user=user)
        
        logger.info(f"Child creation validated for user {user.user_id}, plan: {subscription.plan.value}")
        
        # Validate services
        if supabase_client is None:
            logger.error("Supabase not configured")
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured"
            )
        
        # Create child entity
        # Calculate age from age_category for backward compatibility
        from src.utils.age_category_utils import calculate_age_from_category
        age = calculate_age_from_category(request.age_category)
        
        child_db = ChildDB(
            name=request.name,
            age_category=request.age_category,  # Already normalized by DTO validator
            age=age,
            gender=request.gender,
            interests=request.interests,
            user_id=user.user_id
        )
        
        # Save to database
        saved_child = await supabase_client.save_child(child_db)
        
        # Track usage
        try:
            await supabase_client.track_usage(
                user_id=user.user_id,
                action_type='child_creation',
                resource_id=saved_child.id,
                metadata={
                    'plan': subscription.plan.value,
                    'child_name': saved_child.name
                }
            )
            logger.info(f"Child creation tracked for user {user.user_id}, child {saved_child.id}")
        except Exception as tracking_error:
            logger.warning(f"Failed to track child creation: {str(tracking_error)}")
        
        logger.info(f"Child profile created successfully: {saved_child.id}")
        
        return {
            "id": saved_child.id,
            "name": saved_child.name,
            "age": saved_child.age,
            "gender": saved_child.gender,
            "interests": saved_child.interests,
            "created_at": saved_child.created_at.isoformat() if saved_child.created_at else None
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating child: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error creating child: {str(e)}"
        )


@router.get("/users/subscription")
async def get_user_subscription(
    user: AuthUser = Depends(get_current_user)
):
    """Get current user's subscription information and usage statistics."""
    try:
        # Initialize services
        subscription_validator = SubscriptionValidator()
        subscription_service = SubscriptionService()
        
        # Get subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        
        if not subscription:
            logger.warning(f"Subscription not found for user {user.user_id}")
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Check if monthly reset is needed
        if subscription_service.needs_monthly_reset(subscription):
            logger.info(f"Resetting monthly counter for user {user.user_id}")
            await supabase_client.reset_monthly_story_count(user.user_id)
            # Reload subscription to get updated counter
            subscription = await supabase_client.get_user_subscription(user.user_id)
        
        # Get child count
        child_count = await supabase_client.count_user_children(user.user_id)
        
        # Build response with full subscription info
        subscription_info = subscription_service.get_subscription_info(
            subscription=subscription,
            child_count=child_count
        )
        
        logger.info(f"Subscription info retrieved for user {user.user_id}")
        return subscription_info
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting subscription info: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting subscription info: {str(e)}"
        )


# ============================================================================
# PURCHASE & PLAN ENDPOINTS
# ============================================================================

@router.get("/subscription/plans")
async def get_available_plans(
    user: AuthUser = Depends(get_current_user)
):
    """Get all available subscription plans with pricing and features."""
    try:
        from src.domain.services.plan_catalog import PlanCatalog
        
        # Get user's current subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        
        if not subscription:
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Get all plan definitions
        all_plans = PlanCatalog.get_all_plans()
        
        # Convert to API response format
        plans_list = []
        for plan_tier, plan_def in all_plans.items():
            plans_list.append({
                "tier": plan_tier.value,
                "display_name": plan_def.display_name,
                "description": plan_def.description,
                "monthly_price": float(plan_def.monthly_price),
                "annual_price": float(plan_def.annual_price),
                "features": plan_def.features,
                "limits": {
                    "monthly_stories": plan_def.limits.monthly_stories,
                    "child_profiles": plan_def.limits.child_profiles,
                    "max_story_length": plan_def.limits.max_story_length,
                    "audio_enabled": plan_def.limits.audio_enabled,
                    "hero_stories_enabled": plan_def.limits.hero_stories_enabled,
                    "combined_stories_enabled": plan_def.limits.combined_stories_enabled,
                    "priority_support": plan_def.limits.priority_support,
                },
                "is_purchasable": plan_def.is_purchasable,
                "is_current": plan_tier == subscription.plan,
            })
        
        logger.info(f"Retrieved {len(plans_list)} plans for user {user.user_id}")
        return {
            "plans": plans_list,
            "current_plan": subscription.plan.value
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting available plans: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting available plans: {str(e)}"
        )


@router.post("/subscription/purchase")
async def purchase_subscription(
    plan_tier: str,
    billing_cycle: str,
    payment_method: str,
    user: AuthUser = Depends(get_current_user)
):
    """Purchase a subscription plan upgrade."""
    try:
        from src.domain.services.plan_catalog import BillingCycle, PlanCatalog
        from src.domain.services.purchase_service import PurchaseService
        from src.domain.services.payment_provider import MockPaymentProvider
        from src.domain.services.subscription_service import SubscriptionPlan
        
        logger.info(
            f"Purchase request: user={user.user_id}, "
            f"plan={plan_tier}, cycle={billing_cycle}, method={payment_method}"
        )
        
        # Validate inputs
        try:
            target_plan = SubscriptionPlan(plan_tier)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid plan tier: {plan_tier}"
            )
        
        try:
            cycle = BillingCycle(billing_cycle)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid billing cycle: {billing_cycle}. Must be 'monthly' or 'annual'"
            )
        
        # Get current subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        if not subscription:
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Initialize purchase service with mock payment provider
        payment_provider = MockPaymentProvider()
        purchase_service = PurchaseService(payment_provider)
        
        # Initiate purchase
        success, transaction, error_msg = purchase_service.initiate_purchase(
            user_id=user.user_id,
            current_subscription=subscription,
            target_plan=target_plan,
            billing_cycle=cycle,
            payment_method=payment_method
        )
        
        if not success:
            # Save failed transaction to database
            if transaction:
                await supabase_client.create_purchase_transaction({
                    "user_id": transaction.user_id,
                    "from_plan": transaction.from_plan,
                    "to_plan": transaction.to_plan,
                    "amount": float(transaction.amount),
                    "currency": transaction.currency,
                    "payment_status": transaction.payment_status,
                    "payment_method": transaction.payment_method,
                    "payment_provider": transaction.payment_provider,
                    "transaction_reference": transaction.transaction_reference,
                    "metadata": transaction.metadata
                })
            
            logger.warning(f"Purchase failed for user {user.user_id}: {error_msg}")
            raise HTTPException(
                status_code=402,
                detail=error_msg or "Payment processing failed"
            )
        
        # Save successful transaction to database
        saved_transaction = await supabase_client.create_purchase_transaction({
            "user_id": transaction.user_id,
            "from_plan": transaction.from_plan,
            "to_plan": transaction.to_plan,
            "amount": float(transaction.amount),
            "currency": transaction.currency,
            "payment_status": transaction.payment_status,
            "payment_method": transaction.payment_method,
            "payment_provider": transaction.payment_provider,
            "transaction_reference": transaction.transaction_reference,
            "completed_at": transaction.completed_at.isoformat() if transaction.completed_at else None,
            "metadata": transaction.metadata
        })
        
        # Update user subscription
        updated_subscription = purchase_service.create_updated_subscription(
            current_subscription=subscription,
            new_plan=target_plan,
            billing_cycle=cycle
        )
        
        await supabase_client.update_subscription_plan(
            user_id=user.user_id,
            plan=updated_subscription.plan.value,
            start_date=updated_subscription.start_date,
            end_date=updated_subscription.end_date
        )
        
        logger.info(
            f"Purchase successful: user={user.user_id}, "
            f"transaction={saved_transaction['id']}, "
            f"new_plan={target_plan.value}"
        )
        
        # Return success response
        return {
            "success": True,
            "transaction_id": saved_transaction['id'],
            "subscription": {
                "plan": updated_subscription.plan.value,
                "status": updated_subscription.status.value,
                "start_date": updated_subscription.start_date.isoformat(),
                "end_date": updated_subscription.end_date.isoformat() if updated_subscription.end_date else None,
            },
            "message": f"Successfully upgraded to {target_plan.value} plan"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing purchase: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error processing purchase: {str(e)}"
        )


@router.get("/subscription/purchases")
async def get_purchase_history(
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    user: AuthUser = Depends(get_current_user)
):
    """Get user's purchase transaction history."""
    try:
        # Validate limit
        if limit > 100:
            limit = 100
        if limit < 1:
            limit = 10
        
        # Validate offset
        if offset < 0:
            offset = 0
        
        # Validate status if provided
        if status and status not in ['pending', 'completed', 'failed', 'refunded']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {status}"
            )
        
        # Get purchase history
        history = await supabase_client.get_user_purchase_history(
            user_id=user.user_id,
            status=status,
            limit=limit,
            offset=offset
        )
        
        logger.info(
            f"Retrieved {len(history['transactions'])} transactions for user {user.user_id}"
        )
        
        return history
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting purchase history: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting purchase history: {str(e)}"
        )


@router.get("/admin/generations/test")
async def test_generations_access():
    """Test endpoint to check if we can access generations table."""
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Try a simple query to test access
        logger.info("Testing generations table access...")
        test_result = await supabase_client.get_all_generations(limit=1)
        
        return {
            "success": True,
            "message": "Access to generations table is working",
            "count": len(test_result),
            "sample": test_result[0].model_dump() if test_result else None
        }
    except Exception as e:
        logger.error(f"Test failed: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__
        }


@router.get("/admin/generations/{generation_id}/test")
async def test_generation_detail(generation_id: str):
    """Test endpoint to check if we can access a specific generation."""
    try:
        logger.info(f"Testing generation detail access for ID: {generation_id}")
        
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Test get_all_attempts
        logger.info("Testing get_all_attempts...")
        all_attempts = await supabase_client.get_all_attempts(generation_id)
        
        # Test get_latest_attempt
        logger.info("Testing get_latest_attempt...")
        latest_attempt = await supabase_client.get_latest_attempt(generation_id)
        
        return {
            "success": True,
            "generation_id": generation_id,
            "all_attempts_count": len(all_attempts),
            "latest_attempt": latest_attempt.model_dump() if latest_attempt else None,
            "all_attempts": [attempt.model_dump() for attempt in all_attempts]
        }
    except Exception as e:
        logger.error(f"Test failed: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__,
            "generation_id": generation_id
        }


@router.get("/admin/generations")
async def get_generations(
    limit: int = 100,
    status: Optional[str] = None,
    model_used: Optional[str] = None,
    story_type: Optional[str] = None
):
    """Get all generations with optional filters (admin endpoint)."""
    try:
        # Validate services
        if supabase_client is None:
            logger.error("Supabase not configured")
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured"
            )
        
        # Validate limit
        if limit > 500:
            limit = 500
        if limit < 1:
            limit = 50
        
        # Validate status if provided
        if status and status not in ['pending', 'success', 'failed', 'timeout']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {status}. Must be one of: pending, success, failed, timeout"
            )
        
        # Validate story_type if provided
        if story_type and story_type not in ['child', 'hero', 'combined']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid story_type: {story_type}. Must be one of: child, hero, combined"
            )
        
        # Get generations
        logger.info(f"Fetching generations with filters: limit={limit}, status={status}, model={model_used}, story_type={story_type}")
        generations = await supabase_client.get_all_generations(
            limit=limit,
            status=status,
            model_used=model_used,
            story_type=story_type
        )
        
        logger.info(f"Retrieved {len(generations)} generations from database")
        
        # Convert to dict format for JSON response
        generations_list = []
        for gen in generations:
            try:
                gen_dict = gen.model_dump()
                # Convert datetime to ISO format strings
                if gen_dict.get('created_at'):
                    gen_dict['created_at'] = gen_dict['created_at'].isoformat() if hasattr(gen_dict['created_at'], 'isoformat') else str(gen_dict['created_at'])
                if gen_dict.get('completed_at'):
                    gen_dict['completed_at'] = gen_dict['completed_at'].isoformat() if hasattr(gen_dict['completed_at'], 'isoformat') else str(gen_dict['completed_at'])
                generations_list.append(gen_dict)
            except Exception as e:
                logger.error(f"Error converting generation to dict: {str(e)}", exc_info=True)
                continue
        
        logger.info(f"Successfully converted {len(generations_list)} generations to response format")
        
        return {
            "generations": generations_list,
            "count": len(generations_list)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting generations: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting generations: {str(e)}"
        )


@router.get("/admin/generations/{generation_id}")
async def get_generation_detail(generation_id: str):
    """Get detailed information about a specific generation including all attempts (admin endpoint)."""
    try:
        logger.info(f"Fetching generation detail for ID: {generation_id}")
        
        # Validate services
        if supabase_client is None:
            logger.error("Supabase not configured")
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured"
            )
        
        # Get all attempts for this generation
        logger.debug(f"Fetching all attempts for generation {generation_id}")
        all_attempts = await supabase_client.get_all_attempts(generation_id)
        logger.info(f"Retrieved {len(all_attempts)} attempts for generation {generation_id}")
        
        if not all_attempts:
            logger.warning(f"No attempts found for generation_id: {generation_id}")
            raise HTTPException(
                status_code=404,
                detail=f"Generation with ID {generation_id} not found"
            )
        
        # Get latest attempt
        logger.debug(f"Fetching latest attempt for generation {generation_id}")
        latest_attempt = await supabase_client.get_latest_attempt(generation_id)
        logger.info(f"Latest attempt retrieved: {latest_attempt.attempt_number if latest_attempt else 'None'}")
        
        # Convert to dict format for JSON response
        attempts_list = []
        for attempt in all_attempts:
            attempt_dict = attempt.model_dump()
            # Convert datetime to ISO format strings
            if attempt_dict.get('created_at'):
                attempt_dict['created_at'] = attempt_dict['created_at'].isoformat() if hasattr(attempt_dict['created_at'], 'isoformat') else str(attempt_dict['created_at'])
            if attempt_dict.get('completed_at'):
                attempt_dict['completed_at'] = attempt_dict['completed_at'].isoformat() if hasattr(attempt_dict['completed_at'], 'isoformat') else str(attempt_dict['completed_at'])
            attempts_list.append(attempt_dict)
        
        latest_dict = None
        if latest_attempt:
            latest_dict = latest_attempt.model_dump()
            if latest_dict.get('created_at'):
                latest_dict['created_at'] = latest_dict['created_at'].isoformat() if hasattr(latest_dict['created_at'], 'isoformat') else str(latest_dict['created_at'])
            if latest_dict.get('completed_at'):
                latest_dict['completed_at'] = latest_dict['completed_at'].isoformat() if hasattr(latest_dict['completed_at'], 'isoformat') else str(latest_dict['completed_at'])
        
        logger.info(f"Retrieved generation detail for {generation_id} with {len(attempts_list)} attempts")
        
        return {
            "generation_id": generation_id,
            "latest_attempt": latest_dict,
            "all_attempts": attempts_list,
            "total_attempts": len(attempts_list)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting generation detail: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting generation detail: {str(e)}"
        )


# ============================================================================
# FREE STORIES ENDPOINTS (Public, no authentication required)
# ============================================================================

@router.get("/free-stories", response_model=List[FreeStoryResponseDTO])
async def get_free_stories(
    age_category: Optional[str] = None,
    language: Optional[str] = None,
    limit: Optional[int] = None
):
    """Get active free stories, optionally filtered by age category and language.
    
    This endpoint is publicly accessible and requires no authentication.
    Stories are sorted by creation date in descending order (newest first).
    
    Args:
        age_category: Optional age category filter ('2-3', '3-5', '5-7')
        language: Optional language filter ('en', 'ru')
        limit: Optional limit on number of results
        
    Returns:
        List of active free stories
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Validate and normalize age_category if provided
        if age_category:
            try:
                from src.utils.age_category_utils import normalize_age_category
                age_category = normalize_age_category(age_category)
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid age_category: {str(e)}"
                )
        
        # Validate language if provided
        if language and language not in ['en', 'ru']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language: {language}. Must be one of: 'en', 'ru'"
            )
        
        # Validate limit if provided
        if limit is not None and (limit < 1 or limit > 1000):
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 1000"
            )
        
        # Get free stories from database
        free_stories = await supabase_client.get_free_stories(
            age_category=age_category,
            language=language,
            limit=limit
        )
        
        # Convert to response DTOs
        response_stories = []
        for story in free_stories:
            if not story.id or not story.created_at:
                continue  # Skip stories without ID or created_at
            response_stories.append(FreeStoryResponseDTO(
                id=story.id,
                title=story.title,
                content=story.content,
                age_category=story.age_category,
                language=story.language,
                created_at=story.created_at.isoformat()
            ))
        
        logger.info(f"Retrieved {len(response_stories)} free stories (age_category={age_category}, language={language}, limit={limit})")
        
        return response_stories
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving free stories: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving free stories: {str(e)}"
        )