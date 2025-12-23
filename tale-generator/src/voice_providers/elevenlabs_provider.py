"""ElevenLabs voice provider implementation."""

import os
import asyncio
import logging
from typing import Optional, List, Dict, Any
from elevenlabs import ElevenLabs, Voice, VoiceSettings
from dotenv import load_dotenv

from .base_provider import VoiceProvider, ProviderMetadata

# Set up logger
logger = logging.getLogger("tale_generator.voice_provider.elevenlabs")

# Load environment variables
load_dotenv()


class ElevenLabsProvider(VoiceProvider):
    """ElevenLabs text-to-speech provider implementation."""
    
    def __init__(self):
        """Initialize the ElevenLabs provider."""
        self.api_key = os.getenv("ELEVENLABS_API_KEY")
        self._client: Optional[ElevenLabs] = None
        self._voices = None
        
        # Define voice settings for children's stories
        self.voice_settings = VoiceSettings(
            stability=0.5,
            similarity_boost=0.75,
            style=0.0,
            use_speaker_boost=True
        )
        
        # Provider metadata
        self._metadata = ProviderMetadata(
            provider_name="elevenlabs",
            display_name="ElevenLabs",
            supports_streaming=True,
            max_text_length=5000,
            supported_formats=["mp3", "pcm"]
        )
    
    @property
    def metadata(self) -> ProviderMetadata:
        """Get provider metadata."""
        return self._metadata
    
    @property
    def client(self) -> Optional[ElevenLabs]:
        """Get or initialize the ElevenLabs client (lazy loading)."""
        if self._client is None and self.api_key:
            try:
                self._client = ElevenLabs(api_key=self.api_key)
                logger.info("ElevenLabs client initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize ElevenLabs client: {str(e)}")
                return None
        return self._client
    
    def validate_configuration(self) -> bool:
        """Validate that the provider is properly configured."""
        if not self.api_key:
            logger.warning("ElevenLabs API key is not configured")
            return False
        
        # Try to initialize the client to verify the key
        if self.client is None:
            return False
        
        return True
    
    def get_supported_languages(self) -> List[str]:
        """Get list of supported language codes."""
        # ElevenLabs supports many languages with multilingual models
        return [
            "en",  # English
            "ru",  # Russian
            "es",  # Spanish
            "fr",  # French
            "de",  # German
            "it",  # Italian
            "pt",  # Portuguese
            "pl",  # Polish
            "hi",  # Hindi
            "ja",  # Japanese
            "ko",  # Korean
            "zh",  # Chinese
            "ar",  # Arabic
        ]
    
    def _get_voices(self):
        """Get available voices from ElevenLabs API."""
        if self._voices is None:
            try:
                if self.client:
                    self._voices = self.client.voices.get_all()
                    logger.info(f"Loaded {len(self._voices.voices)} voices from ElevenLabs")
            except Exception as e:
                logger.warning(f"Could not retrieve voices list: {str(e)}")
                self._voices = None
        return self._voices
    
    def get_available_voices(self, language: Optional[str] = None) -> List[str]:
        """Get list of available voice identifiers."""
        voices_data = self._get_voices()
        
        if voices_data is None or not hasattr(voices_data, 'voices'):
            # Return fallback voice IDs
            logger.warning("Could not retrieve voices, returning fallback list")
            return ["21m00Tcm4TlvDq8ikWAM"]  # Rachel voice
        
        voice_ids = []
        for voice in voices_data.voices:
            # If language filter is specified, try to match
            if language:
                if hasattr(voice, 'labels') and voice.labels:
                    if language in str(voice.labels).lower():
                        voice_ids.append(voice.voice_id)
                elif hasattr(voice, 'name') and language in voice.name.lower():
                    voice_ids.append(voice.voice_id)
            else:
                # No filter, add all voices
                voice_ids.append(voice.voice_id)
        
        return voice_ids if voice_ids else ["21m00Tcm4TlvDq8ikWAM"]
    
    def _find_voice_by_language(self, language_code: str) -> str:
        """Find an appropriate voice for the given language code."""
        try:
            voices = self._get_voices()
            if voices is None or not hasattr(voices, 'voices'):
                return self._get_fallback_voice(language_code)
            
            # Look for voices that support the requested language
            for voice in voices.voices:
                if hasattr(voice, 'labels') and voice.labels:
                    if language_code in str(voice.labels).lower():
                        logger.info(f"Found voice {voice.name} for language {language_code}")
                        return voice.voice_id
                
                if (hasattr(voice, 'name') and language_code in voice.name.lower()) or \
                   (hasattr(voice, 'settings') and voice.settings and \
                    hasattr(voice.settings, 'language_code') and \
                    voice.settings.language_code == language_code):
                    logger.info(f"Found voice {voice.name} for language {language_code}")
                    return voice.voice_id
            
            # No specific voice found, use fallback
            logger.warning(f"No specific voice found for {language_code}, using fallback")
            return self._get_fallback_voice(language_code)
            
        except Exception as e:
            logger.error(f"Error finding voice for language {language_code}: {str(e)}")
            return self._get_fallback_voice(language_code)
    
    def _get_fallback_voice(self, language_code: str) -> str:
        """Get a fallback voice for the given language code."""
        voice_map = {
            "en": "21m00Tcm4TlvDq8ikWAM",  # Rachel - clear and calm voice
            "ru": "21m00Tcm4TlvDq8ikWAM"   # Use Rachel for Russian with multilingual model
        }
        return voice_map.get(language_code, "21m00Tcm4TlvDq8ikWAM")
    
    async def generate_speech(
        self,
        text: str,
        language: str = "en",
        voice_options: Optional[Dict[str, Any]] = None
    ) -> Optional[bytes]:
        """Generate speech from text asynchronously.
        
        Args:
            text: The text to convert to speech
            language: The language code for the text (default: "en")
            voice_options: Provider-specific options (voice_id, model_id, settings)
            
        Returns:
            Audio data as bytes, or None if generation failed
        """
        return await asyncio.to_thread(
            self._generate_speech_sync,
            text,
            language,
            voice_options
        )
    
    def _generate_speech_sync(
        self,
        text: str,
        language: str = "en",
        voice_options: Optional[Dict[str, Any]] = None
    ) -> Optional[bytes]:
        """Synchronous implementation of speech generation.
        
        Args:
            text: The text to convert to speech
            language: The language code for the text (default: "en")
            voice_options: Provider-specific options (voice_id, model_id, settings)
            
        Returns:
            Audio data as bytes, or None if generation failed
        """
        try:
            if not self.client:
                logger.error("ElevenLabs client is not initialized")
                return None
            
            logger.info(f"Generating speech for text with {len(text)} characters in language {language}")
            
            # Parse voice options
            voice_options = voice_options or {}
            voice_id = voice_options.get("voice_id")
            model_id = voice_options.get("model_id", "eleven_multilingual_v2")
            custom_settings = voice_options.get("voice_settings")
            
            # Select voice if not provided
            if not voice_id:
                voice_id = self._find_voice_by_language(language)
            
            logger.info(f"Using voice ID: {voice_id}, model: {model_id}")
            
            # Use custom settings if provided, otherwise use defaults
            settings = custom_settings if custom_settings else self.voice_settings
            
            # Generate the audio
            audio = self.client.text_to_speech.convert(
                text=text,
                voice_id=voice_id,
                model_id=model_id,
                voice_settings=settings
            )
            
            # Convert generator to bytes
            audio_bytes = b"".join(audio)
            
            logger.info(f"Successfully generated speech with {len(audio_bytes)} bytes")
            return audio_bytes
            
        except Exception as e:
            logger.error(f"Error generating speech with ElevenLabs: {str(e)}", exc_info=True)
            return None
