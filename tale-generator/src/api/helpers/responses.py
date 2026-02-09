"""Response building helpers."""

import logging
from typing import Optional
from datetime import datetime

from src.domain.value_objects import Language
from src.domain.entities import Child, Hero
from src.models import StoryDB
from src.application.dto import (
    GenerateStoryResponseDTO,
    ChildInfoDTO,
    HeroInfoDTO
)
from src.supabase_client_async import AsyncSupabaseClient

logger = logging.getLogger("tale_generator.api.helpers")


def generate_relationship_description(
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


async def save_story(
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
    supabase_client: AsyncSupabaseClient,
    parent_id: Optional[str] = None,
    story_length: Optional[int] = None
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
        age_category=child.age_category,
        child_gender=child.gender.value,
        child_interests=child.interests,
        hero_id=hero.id if hero else None,
        language=language,
        audio_file_url=audio_file_url,
        parent_id=parent_id,
        story_length=story_length,
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


def build_response(
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
        age_category=child.age_category,
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

