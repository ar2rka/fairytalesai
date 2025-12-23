"""Voice service facade for audio generation with provider management."""

import asyncio
import logging
from typing import Optional, Dict, Any
from dataclasses import dataclass

from .provider_registry import get_registry
from .base_provider import VoiceProvider

# Set up logger
logger = logging.getLogger("tale_generator.voice_service")


@dataclass
class AudioGenerationResult:
    """Result of audio generation."""
    
    audio_data: Optional[bytes]
    provider_name: Optional[str]
    success: bool
    error_message: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class VoiceService:
    """Facade for voice generation with provider selection and fallback."""
    
    def __init__(self):
        """Initialize the voice service."""
        self.registry = get_registry()
    
    async def generate_audio(
        self,
        text: str,
        language: str = "en",
        provider_name: Optional[str] = None,
        voice_options: Optional[Dict[str, Any]] = None
    ) -> AudioGenerationResult:
        """Generate audio from text with automatic provider selection and fallback.
        
        Args:
            text: The text to convert to speech
            language: The language code (default: "en")
            provider_name: Preferred provider name (optional)
            voice_options: Provider-specific voice options (optional)
            
        Returns:
            AudioGenerationResult with audio data and metadata
        """
        if not text:
            logger.warning("Empty text provided for audio generation")
            return AudioGenerationResult(
                audio_data=None,
                provider_name=None,
                success=False,
                error_message="Empty text provided"
            )
        
        # Get provider with fallback
        provider = self.registry.get_provider_with_fallback(provider_name)
        
        if not provider:
            logger.error("No voice providers available for audio generation")
            return AudioGenerationResult(
                audio_data=None,
                provider_name=None,
                success=False,
                error_message="No voice providers available"
            )
        
        # Attempt to generate audio
        actual_provider_name = provider.metadata.provider_name
        logger.info(f"Generating audio with provider: {actual_provider_name}")
        
        try:
            audio_data = await provider.generate_speech(
                text=text,
                language=language,
                voice_options=voice_options
            )
            
            if audio_data:
                logger.info(f"Successfully generated {len(audio_data)} bytes of audio")
                return AudioGenerationResult(
                    audio_data=audio_data,
                    provider_name=actual_provider_name,
                    success=True,
                    metadata={
                        "text_length": len(text),
                        "language": language,
                        "audio_size": len(audio_data)
                    }
                )
            else:
                logger.warning(f"Provider {actual_provider_name} returned no audio data")
                
                # Try fallback providers if primary failed
                fallback_result = await self._try_fallback(
                    text=text,
                    language=language,
                    voice_options=voice_options,
                    failed_provider=actual_provider_name
                )
                
                if fallback_result:
                    return fallback_result
                
                return AudioGenerationResult(
                    audio_data=None,
                    provider_name=actual_provider_name,
                    success=False,
                    error_message="Provider returned no audio data"
                )
                
        except Exception as e:
            logger.error(f"Error generating audio with {actual_provider_name}: {str(e)}", exc_info=True)
            
            # Try fallback providers
            fallback_result = await self._try_fallback(
                text=text,
                language=language,
                voice_options=voice_options,
                failed_provider=actual_provider_name
            )
            
            if fallback_result:
                return fallback_result
            
            return AudioGenerationResult(
                audio_data=None,
                provider_name=actual_provider_name,
                success=False,
                error_message=str(e)
            )
    
    async def _try_fallback(
        self,
        text: str,
        language: str,
        voice_options: Optional[Dict[str, Any]],
        failed_provider: str
    ) -> Optional[AudioGenerationResult]:
        """Try to generate audio with fallback providers.
        
        Args:
            text: The text to convert
            language: Language code
            voice_options: Voice options
            failed_provider: Name of provider that failed
            
        Returns:
            AudioGenerationResult if successful, None otherwise
        """
        available_providers = self.registry.list_available_providers()
        
        for provider_name in available_providers:
            if provider_name == failed_provider:
                continue
            
            logger.info(f"Trying fallback provider: {provider_name}")
            provider = self.registry.get_provider(provider_name)
            
            if not provider:
                continue
            
            try:
                audio_data = await provider.generate_speech(
                    text=text,
                    language=language,
                    voice_options=voice_options
                )
                
                if audio_data:
                    logger.info(f"Successfully generated audio with fallback provider {provider_name}")
                    return AudioGenerationResult(
                        audio_data=audio_data,
                        provider_name=provider_name,
                        success=True,
                        metadata={
                            "text_length": len(text),
                            "language": language,
                            "audio_size": len(audio_data),
                            "fallback_from": failed_provider
                        }
                    )
            except Exception as e:
                logger.warning(f"Fallback provider {provider_name} also failed: {str(e)}")
                continue
        
        logger.error("All fallback providers failed")
        return None
    
    def get_available_providers(self) -> list[str]:
        """Get list of available provider names.
        
        Returns:
            List of provider names that are properly configured
        """
        return self.registry.list_available_providers()
    
    def get_supported_languages(self, provider_name: Optional[str] = None) -> list[str]:
        """Get supported languages for a provider.
        
        Args:
            provider_name: Provider to query, or None for default
            
        Returns:
            List of supported language codes
        """
        provider = self.registry.get_provider(provider_name)
        if provider:
            return provider.get_supported_languages()
        return []


# Global service instance
_global_service: Optional[VoiceService] = None


def get_voice_service() -> VoiceService:
    """Get the global voice service instance.
    
    Returns:
        The global voice service instance
    """
    global _global_service
    if _global_service is None:
        _global_service = VoiceService()
    return _global_service


def reset_voice_service() -> None:
    """Reset the global voice service (mainly for testing)."""
    global _global_service
    _global_service = None
