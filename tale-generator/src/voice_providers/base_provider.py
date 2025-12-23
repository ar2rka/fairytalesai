"""Base provider interface for voice-over services."""

from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any
from dataclasses import dataclass
import logging

# Set up logger
logger = logging.getLogger("tale_generator.voice_provider")


@dataclass
class ProviderMetadata:
    """Metadata about a voice provider."""
    
    provider_name: str
    display_name: str
    supports_streaming: bool = False
    max_text_length: int = 5000
    supported_formats: List[str] = None
    
    def __post_init__(self):
        """Initialize default values."""
        if self.supported_formats is None:
            self.supported_formats = ["mp3"]


class VoiceProvider(ABC):
    """Abstract base class for voice-over providers."""
    
    @property
    @abstractmethod
    def metadata(self) -> ProviderMetadata:
        """Get provider metadata.
        
        Returns:
            Provider metadata with capabilities and limitations
        """
        pass
    
    @abstractmethod
    def validate_configuration(self) -> bool:
        """Validate that the provider is properly configured.
        
        Returns:
            True if configuration is valid and provider is ready to use
        """
        pass
    
    @abstractmethod
    def get_supported_languages(self) -> List[str]:
        """Get list of supported language codes.
        
        Returns:
            List of ISO 639-1 language codes (e.g., ['en', 'ru', 'es'])
        """
        pass
    
    @abstractmethod
    def get_available_voices(self, language: Optional[str] = None) -> List[str]:
        """Get list of available voice identifiers.
        
        Args:
            language: Optional language code to filter voices
            
        Returns:
            List of voice identifiers available for the given language
        """
        pass
    
    @abstractmethod
    def generate_speech(
        self, 
        text: str, 
        language: str = "en",
        voice_options: Optional[Dict[str, Any]] = None
    ) -> Optional[bytes]:
        """Generate speech audio from text.
        
        Args:
            text: The text to convert to speech
            language: The language code for the text (default: "en")
            voice_options: Provider-specific voice configuration options
            
        Returns:
            Audio data as bytes (typically MP3 format), or None if generation failed
        """
        pass
    
    def __str__(self) -> str:
        """String representation of the provider."""
        return f"{self.metadata.display_name} ({self.metadata.provider_name})"
    
    def __repr__(self) -> str:
        """Detailed string representation."""
        return f"<{self.__class__.__name__} provider={self.metadata.provider_name}>"
