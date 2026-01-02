"""Entity fetching and conversion helpers."""

import logging
from fastapi import HTTPException

from src.domain.value_objects import Language, Gender
from src.domain.entities import Child, Hero
from src.supabase_client_async import AsyncSupabaseClient

logger = logging.getLogger("tale_generator.api.helpers")


async def fetch_and_convert_child(
    child_id: str,
    user_id: str,
    supabase_client: AsyncSupabaseClient
) -> Child:
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
    
    # Ensure age_category is present
    age_category = getattr(child_db, 'age_category', None)
    if not age_category:
        logger.error(f"Child {child_id} missing required age_category")
        raise HTTPException(
            status_code=500,
            detail="Child profile is missing age_category"
        )
    
    return Child(
        id=child_db.id,
        name=child_db.name,
        age_category=age_category,
        gender=Gender(child_db.gender),
        interests=child_db.interests,
        created_at=getattr(child_db, 'created_at', None),
        updated_at=getattr(child_db, 'updated_at', None)
    )


async def fetch_and_convert_hero(
    hero_id: str,
    expected_language: Language,
    supabase_client: AsyncSupabaseClient
) -> Hero:
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

