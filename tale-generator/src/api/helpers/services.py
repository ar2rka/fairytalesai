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
        logger.info("Async Supabase client initialized successfully")
        return client
    except ValueError as e:
        logger.warning(f"Async Supabase client initialization failed: {e}")
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


def initialize_prompt_service(supabase_client: Optional[AsyncSupabaseClient]) -> PromptService:
    """Initialize prompt service with Supabase client if available.
    
    Note: PromptRepository needs sync client, so we get it from async client.
    """
    _sync_supabase_client = None
    if supabase_client and hasattr(supabase_client, '_sync_client'):
        _sync_supabase_client = supabase_client._sync_client
    prompt_service = PromptService(_sync_supabase_client)
    logger.info("Prompt service initialized successfully")
    return prompt_service

