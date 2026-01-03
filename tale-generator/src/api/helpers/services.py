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


def initialize_prompt_service(supabase_client: Optional[AsyncSupabaseClient]) -> PromptService:
    """Initialize prompt service with Supabase client if available.
    
    Note: PromptRepository needs sync client, so we get it from async client.
    """
    _sync_supabase_client = None
    
    if supabase_client is None:
        logger.error("❌ supabase_client is None - cannot initialize PromptTemplateService")
        logger.error("⚠️ Check SUPABASE_URL and SUPABASE_KEY environment variables")
    elif not hasattr(supabase_client, '_sync_client'):
        logger.error(f"❌ supabase_client does not have _sync_client attribute: {type(supabase_client)}")
    else:
        _sync_supabase_client = supabase_client._sync_client
        if _sync_supabase_client is None:
            logger.error("❌ _sync_client is None inside AsyncSupabaseClient")
        else:
            logger.info(f"✅ Extracted sync Supabase client from async client: {type(_sync_supabase_client)}")
    
    prompt_service = PromptService(_sync_supabase_client)
    
    if prompt_service._template_service:
        logger.info("✅ Prompt service initialized with PromptTemplateService (prompts will be loaded from Supabase)")
    else:
        logger.error("❌ Prompt service initialized WITHOUT PromptTemplateService")
        logger.error("⚠️ Will use built-in prompt generation methods (includes 'IMPORTANT: Start directly...' text)")
        logger.error("⚠️ This means prompts are NOT being loaded from Supabase database")
    
    return prompt_service

