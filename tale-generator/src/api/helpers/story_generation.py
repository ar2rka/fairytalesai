"""Story generation helpers."""

import logging
import re
from typing import Optional
from datetime import datetime
from fastapi import HTTPException

from src.application.dto import GenerateStoryRequestDTO
from src.domain.value_objects import Language, StoryLength
from src.domain.entities import Child, Hero
from src.domain.services.prompt_service import PromptService
from src.models import StoryDB
from src.openrouter_client import OpenRouterClient, StoryGenerationResult
from src.supabase_client_async import AsyncSupabaseClient
from src.infrastructure.persistence.models import GenerationDB

logger = logging.getLogger("tale_generator.api.helpers")


def determine_moral(request: GenerateStoryRequestDTO) -> str:
    """Determine the moral value for the story."""
    if request.custom_moral:
        return request.custom_moral
    elif request.moral:
        return request.moral
    else:
        return "kindness"


def generate_prompt(
    story_type: str,
    child: Child,
    hero: Optional[Hero],
    moral: str,
    language: Language,
    story_length: StoryLength,
    prompt_service: PromptService,
    parent_story: Optional[StoryDB] = None
) -> str:
    """Generate appropriate prompt based on story type."""
    # Log prompt service status
    if prompt_service._template_service:
        logger.info(f"✅ PromptService has PromptTemplateService - will use prompts from Supabase")
    else:
        logger.warning(f"⚠️ PromptService does NOT have PromptTemplateService - will use built-in methods (includes 'IMPORTANT: Start directly...' text)")
    
    if story_type == "child":
        logger.info(f"Generating child story for {child.name}")
        prompt = prompt_service.generate_child_prompt(child, moral, language, story_length, parent_story)
    elif story_type == "hero":
        logger.info(f"Generating hero story for {hero.name}")
        prompt = prompt_service.generate_hero_prompt(hero, moral, story_length, parent_story)
    else:  # combined
        logger.info(f"Generating combined story for {child.name} and {hero.name}")
        prompt = prompt_service.generate_combined_prompt(child, hero, moral, language, story_length, parent_story)
    
    # Check if prompt contains fallback text
    if "IMPORTANT: Start directly with the story" in prompt:
        logger.error(f"❌ ERROR: Generated prompt contains 'IMPORTANT: Start directly...' - this means fallback methods were used instead of Supabase prompts!")
        logger.error(f"PromptService._template_service is None: {prompt_service._template_service is None}")
    
    return prompt


async def create_generation_record(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str,
    supabase_client: AsyncSupabaseClient
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


async def update_generation_success(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str,
    model_used: str,
    full_response: str,
    supabase_client: AsyncSupabaseClient,
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


async def update_generation_failure(
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    prompt: str,
    error_message: str,
    supabase_client: AsyncSupabaseClient,
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


async def generate_story_content(
    prompt: str,
    generation_id: str,
    user_id: str,
    story_type: str,
    story_length: int,
    hero: Optional[Hero],
    moral: str,
    child: Child,
    language: Language,
    openrouter_client: OpenRouterClient,
    supabase_client: AsyncSupabaseClient
) -> StoryGenerationResult:
    """Generate story content using LangGraph workflow with retry and tracking."""
    
    try:
        result = await openrouter_client.generate_story(
            prompt,
            max_retries=3,
            retry_delay=1.0,
            use_langgraph=True,  # Always use LangGraph workflow
            child_name=child.name,
            child_gender=child.gender.value,
            child_interests=child.interests or [],
            moral=moral,
            language=language.value,
            story_length_minutes=story_length,
            user_id=user_id
        )
        
        # Update with success
        await update_generation_success(
            generation_id=generation_id,
            user_id=user_id,
            story_type=story_type,
            story_length=story_length,
            hero=hero,
            moral=moral,
            prompt=prompt,
            model_used=result.model.value if result.model else "unknown",
            full_response=result.full_response,
            supabase_client=supabase_client,
            attempt_number=1  # TODO: Track actual attempt number from retry logic
        )
        
        return result
        
    except Exception as gen_error:
        # Update with failure
        await update_generation_failure(
            generation_id=generation_id,
            user_id=user_id,
            story_type=story_type,
            story_length=story_length,
            hero=hero,
            moral=moral,
            prompt=prompt,
            error_message=str(gen_error),
            supabase_client=supabase_client,
            attempt_number=1  # TODO: Track actual attempt number from retry logic
        )
        
        raise HTTPException(
            status_code=500,
            detail=f"Story generation failed: {str(gen_error)}"
        )


def clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers.
    
    Args:
        content: Raw story content from AI
        
    Returns:
        Cleaned content without formatting markers
    """
    # Remove sequences of 3 or more asterisks
    cleaned = re.sub(r'\*{3,}', '', content)
    
    # Remove sequences of 3 or more underscores
    cleaned = re.sub(r'_{3,}', '', cleaned)
    
    # Remove sequences of 3 or more hyphens (but not in words)
    cleaned = re.sub(r'(?<!\w)-{3,}(?!\w)', '', cleaned)
    
    # Clean up any excessive whitespace that might have been left
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    
    return cleaned.strip()


def extract_title(content: str) -> str:
    """Extract title from story content."""
    lines = content.strip().split('\n')
    title = lines[0].replace('#', '').strip() if lines else "A Bedtime Story"
    logger.debug(f"Extracted title: {title}")
    return title


async def generate_summary(
    content: str,
    title: str,
    language: Language,
    openrouter_client: Optional[OpenRouterClient]
) -> str:
    """Generate a summary of the story in a few sentences.
    
    Args:
        content: The full story content
        title: The story title
        language: The language of the story
        openrouter_client: OpenRouter client instance
        
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

