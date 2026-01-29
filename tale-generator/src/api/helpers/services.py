"""Service initialization helpers."""

import logging
from typing import Optional

from src.openrouter_client import OpenRouterClient
from src.supabase_client_async import AsyncSupabaseClient
from src.voice_providers import get_voice_service, get_registry, ElevenLabsProvider
from src.domain.services.prompt_service import PromptService

logger = logging.getLogger("tale_generator.api.helpers")


def initialize_openrouter_client() -> Optional[OpenRouterClient]:
    """Initialize OpenRouter client with error handling."""
    try:
        client = OpenRouterClient()
        logger.info("OpenRouter client initialized successfully")
        return client
    except ValueError as e:
        logger.warning(f"OpenRouter client initialization failed: {e}")
        return None


def initialize_supabase_client() -> Optional[AsyncSupabaseClient]:
    """Initialize Supabase client with error handling."""
    try:
        client = AsyncSupabaseClient()
        logger.info("✅ Async Supabase client initialized successfully")
        return client
    except ValueError as e:
        logger.error(f"❌ Async Supabase client initialization failed: {e}")
        logger.error("⚠️ PromptService will use built-in methods instead of Supabase prompts")
        return None
    except Exception as e:
        logger.error(f"❌ Unexpected error initializing Supabase client: {e}", exc_info=True)
        return None


def initialize_voice_service():
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


def initialize_prompt_service(_supabase_client: Optional[AsyncSupabaseClient] = None) -> PromptService:
    """Initialize prompt service. Uses file-based templates from src/prompts/templates/ by default."""
    from src.prompts.loader import FilePromptLoader

    loader = FilePromptLoader()
    prompt_service = PromptService(prompt_loader=loader)

    if prompt_service._template_service:
        logger.info("Prompt service initialized with file-based templates")
    else:
        logger.warning("Prompt service fell back to built-in methods (check templates in src/prompts/templates/)")

    return prompt_service

