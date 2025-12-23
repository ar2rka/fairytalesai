"""Client for ElevenLabs text-to-speech API."""

import os
import logging
from typing import Optional
from elevenlabs import ElevenLabs, Voice, VoiceSettings
from dotenv import load_dotenv

# Set up logger
logger = logging.getLogger("tale_generator.elevenlabs")

# Load environment variables
load_dotenv()


class ElevenLabsClient:
    """Client for interacting with ElevenLabs API."""
    
    def __init__(self):
        """Initialize the ElevenLabs client."""
        self.api_key = os.getenv("ELEVENLABS_API_KEY")
        
        if not self.api_key:
            raise ValueError(
                "ElevenLabs API key is required. "
                "Set ELEVENLABS_API_KEY environment variable."
            )
        
        # Initialize the client
        self.client = ElevenLabs(api_key=self.api_key)
        
        # Cache available voices
        self._voices = None
        
        # Define voice settings for children's stories
        self.voice_settings = VoiceSettings(
            stability=0.5,
            similarity_boost=0.75,
            style=0.0,
            use_speaker_boost=True
        )
    
    def _get_voices(self):
        """Get available voices from ElevenLabs API."""
        if self._voices is None:
            try:
                self._voices = self.client.voices.get_all()
                logger.info(f"Loaded {len(self._voices.voices)} voices from ElevenLabs")
            except Exception as e:
                logger.warning(f"Could not retrieve voices list, using fallback voices: {str(e)}")
                self._voices = None  # Set to None to indicate failure
        return self._voices
    
    def _find_voice_by_language(self, language_code: str):
        """Find an appropriate voice for the given language code."""
        try:
            voices = self._get_voices()
            if voices is None or not hasattr(voices, 'voices'):
                # Fallback to default voices if we can't get the list
                logger.warning("Could not retrieve voices list, using fallback voices")
                return self._get_fallback_voice(language_code)
            
            # Look for voices that support the requested language
            for voice in voices.voices:
                if hasattr(voice, 'labels') and voice.labels:
                    # Check if the voice supports the language
                    if language_code in str(voice.labels).lower():
                        logger.info(f"Found voice {voice.name} for language {language_code}")
                        return voice.voice_id
                
                # Also check in the voice settings or name
                if (hasattr(voice, 'name') and language_code in voice.name.lower()) or \
                   (hasattr(voice, 'settings') and voice.settings and \
                    hasattr(voice.settings, 'language_code') and \
                    voice.settings.language_code == language_code):
                    logger.info(f"Found voice {voice.name} for language {language_code}")
                    return voice.voice_id
            
            # If no specific language voice found, use a general one
            logger.warning(f"No specific voice found for {language_code}, using fallback")
            return self._get_fallback_voice(language_code)
            
        except Exception as e:
            logger.error(f"Error finding voice for language {language_code}: {str(e)}")
            return self._get_fallback_voice(language_code)
    
    def _get_fallback_voice(self, language_code: str):
        """Get a fallback voice for the given language code."""
        # Known working voice IDs
        # For multilingual model, we can use English voices for Russian text
        voice_map = {
            "en": "21m00Tcm4TlvDq8ikWAM",  # Rachel - clear and calm voice
            "ru": "21m00Tcm4TlvDq8ikWAM"   # Use Rachel for Russian as well with multilingual model
        }
        
        return voice_map.get(language_code, "21m00Tcm4TlvDq8ikWAM")  # Default to Rachel
    
    def generate_speech(self, text: str, filename: str, language: str = "en") -> Optional[str]:
        """
        Generate speech from text and return the audio data.
        
        Args:
            text: The text to convert to speech
            filename: The filename to use for the audio file
            language: The language of the text (default: "en")
            
        Returns:
            The audio data as bytes, or None if generation failed
        """
        try:
            logger.info(f"Generating speech for text with {len(text)} characters")
            
            # Select appropriate voice based on language
            voice_id = self._find_voice_by_language(language)
            logger.info(f"Using voice ID: {voice_id} for language: {language}")
            
            # Generate the audio
            audio = self.client.text_to_speech.convert(
                text=text,
                voice_id=voice_id,
                model_id="eleven_multilingual_v2",
                voice_settings=self.voice_settings
            )
            
            # Convert generator to bytes
            audio_bytes = b"".join(audio)
            
            logger.info(f"Successfully generated speech with {len(audio_bytes)} bytes")
            return audio_bytes
            
        except Exception as e:
            logger.error(f"Error generating speech: {str(e)}", exc_info=True)
            return None