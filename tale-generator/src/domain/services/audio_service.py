"""Audio generation service."""

from typing import Optional, Dict, Any
from dataclasses import dataclass
from src.domain.entities import AudioFile
from src.domain.value_objects import Language
from src.core.logging import get_logger
from src.core.exceptions import ExternalServiceError

logger = get_logger("domain.audio_service")


@dataclass
class AudioGenerationResult:
    """Result of audio generation."""
    success: bool
    audio_data: Optional[bytes] = None
    provider_name: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class AudioService:
    """Service for managing audio generation workflow."""
    
    def __init__(self, voice_provider_registry):
        """Initialize audio service.
        
        Args:
            voice_provider_registry: Registry of voice providers
        """
        self.voice_provider_registry = voice_provider_registry
        self._logger = logger
    
    def generate_audio(
        self,
        text: str,
        language: Language,
        provider_name: Optional[str] = None,
        voice_options: Optional[Dict[str, Any]] = None
    ) -> AudioGenerationResult:
        """Generate audio for text.
        
        Args:
            text: Text to convert to speech
            language: Language of the text
            provider_name: Specific provider to use (optional)
            voice_options: Provider-specific options
            
        Returns:
            AudioGenerationResult with audio data or error
        """
        self._logger.info(f"Generating audio for text in {language.value}")
        
        try:
            # Get provider
            if provider_name:
                provider = self.voice_provider_registry.get(provider_name)
                if not provider:
                    return AudioGenerationResult(
                        success=False,
                        error_message=f"Provider '{provider_name}' not found"
                    )
            else:
                # Use default provider
                provider = self.voice_provider_registry.get_default()
                if not provider:
                    return AudioGenerationResult(
                        success=False,
                        error_message="No voice provider available"
                    )
            
            # Generate audio
            self._logger.debug(f"Using provider: {provider.metadata.name}")
            audio_data = provider.generate_speech(
                text=text,
                language=language.value,
                options=voice_options or {}
            )
            
            if audio_data:
                self._logger.info("Audio generated successfully")
                return AudioGenerationResult(
                    success=True,
                    audio_data=audio_data,
                    provider_name=provider.metadata.name,
                    metadata={
                        "language": language.value,
                        "text_length": len(text),
                        "provider_version": provider.metadata.version
                    }
                )
            else:
                return AudioGenerationResult(
                    success=False,
                    error_message="Provider returned no audio data"
                )
                
        except Exception as e:
            self._logger.error(f"Error generating audio: {str(e)}", exc_info=True)
            return AudioGenerationResult(
                success=False,
                error_message=str(e)
            )
    
    def create_audio_file_entity(
        self,
        url: str,
        provider: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> AudioFile:
        """Create an AudioFile entity.
        
        Args:
            url: Audio file URL
            provider: Provider name
            metadata: Additional metadata
            
        Returns:
            AudioFile entity
        """
        return AudioFile(
            url=url,
            provider=provider,
            metadata=metadata or {}
        )
