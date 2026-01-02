"""Validation helpers for API routes."""

import logging
from typing import Optional
from fastapi import HTTPException

from src.domain.value_objects import Language

logger = logging.getLogger("tale_generator.api.helpers")


def validate_language(language: str) -> Language:
    """Validate and convert language string to Language enum."""
    if language not in ["en", "ru"]:
        logger.warning(f"Invalid language: {language}")
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported language: {language}. Supported: en, ru"
        )
    return Language.ENGLISH if language == "en" else Language.RUSSIAN


def validate_story_type(story_type: str, hero_id: Optional[str]) -> None:
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


def validate_services(openrouter_client, supabase_client) -> None:
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

