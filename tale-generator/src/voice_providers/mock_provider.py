"""Mock voice provider for testing without API costs."""

import logging
from typing import Optional, List, Dict, Any
import hashlib

from .base_provider import VoiceProvider, ProviderMetadata

# Set up logger
logger = logging.getLogger("tale_generator.voice_provider.mock")


class MockVoiceProvider(VoiceProvider):
    """Mock voice provider for testing purposes."""
    
    def __init__(self):
        """Initialize the mock provider."""
        self._metadata = ProviderMetadata(
            provider_name="mock",
            display_name="Mock Voice Provider",
            supports_streaming=False,
            max_text_length=10000,
            supported_formats=["mp3"]
        )
        self._configured = True
    
    @property
    def metadata(self) -> ProviderMetadata:
        """Get provider metadata."""
        return self._metadata
    
    def validate_configuration(self) -> bool:
        """Validate that the provider is properly configured."""
        return self._configured
    
    def get_supported_languages(self) -> List[str]:
        """Get list of supported language codes."""
        return ["en", "ru", "es", "fr", "de", "it", "pt", "pl", "ja", "ko", "zh"]
    
    def get_available_voices(self, language: Optional[str] = None) -> List[str]:
        """Get list of available voice identifiers."""
        voices = ["mock-voice-1", "mock-voice-2", "mock-voice-3"]
        if language:
            voices.append(f"mock-voice-{language}")
        return voices
    
    def generate_speech(
        self,
        text: str,
        language: str = "en",
        voice_options: Optional[Dict[str, Any]] = None
    ) -> Optional[bytes]:
        """Generate mock audio from text.
        
        This creates a deterministic fake audio file based on the input text.
        The "audio" is just a byte sequence that encodes the text length and hash.
        
        Args:
            text: The text to convert to speech
            language: The language code for the text (default: "en")
            voice_options: Provider-specific options (ignored for mock)
            
        Returns:
            Mock audio data as bytes
        """
        try:
            logger.info(f"Generating mock audio for {len(text)} characters in {language}")
            
            # Create a deterministic mock audio file
            # In reality, this would be actual audio data
            text_hash = hashlib.md5(text.encode()).hexdigest()
            
            # Create mock MP3 header (simplified)
            mock_header = b'ID3\x04\x00\x00\x00\x00\x00\x00'
            
            # Add text length and hash as "audio data"
            mock_data = f"MOCK_AUDIO:len={len(text)},lang={language},hash={text_hash}".encode()
            
            # Pad to make it look more like a real file
            padding = b'\x00' * (1024 - len(mock_data) % 1024)
            
            audio_bytes = mock_header + mock_data + padding
            
            logger.info(f"Generated {len(audio_bytes)} bytes of mock audio")
            return audio_bytes
            
        except Exception as e:
            logger.error(f"Error generating mock audio: {str(e)}", exc_info=True)
            return None
    
    def set_configured(self, configured: bool):
        """Set configuration status (for testing).
        
        Args:
            configured: Whether the provider should report as configured
        """
        self._configured = configured
