"""Audio generation helpers."""

import logging
from typing import Optional, Tuple

from src.supabase_client_async import AsyncSupabaseClient

logger = logging.getLogger("tale_generator.api.helpers")


async def generate_audio(
    content: str,
    language: str,
    provider_name: Optional[str],
    voice_options: Optional[dict],
    story_id: str,
    voice_service,
    supabase_client: AsyncSupabaseClient
) -> Tuple[Optional[str], Optional[str], Optional[dict]]:
    """Generate audio for story content.
    
    Args:
        content: Story content to convert to audio
        language: Language code
        provider_name: Audio provider name
        voice_options: Voice generation options
        story_id: Story ID to use for the audio filename
        voice_service: Voice service instance
        supabase_client: Supabase client instance
    
    Returns:
        Tuple of (audio_file_url, audio_provider, audio_metadata)
    """
    if voice_service is None:
        logger.warning("Voice service not available")
        return None, None, None
    
    try:
        logger.info("Generating audio for story")
        audio_result = await voice_service.generate_audio(
            text=content,
            language=language,
            provider_name=provider_name,
            voice_options=voice_options
        )
        
        if not audio_result.success or not audio_result.audio_data:
            error_msg = audio_result.error_message if audio_result else "Unknown error"
            logger.warning(f"Failed to generate audio: {error_msg}")
            return None, None, None
        
        # Upload audio file
        audio_filename = f"{story_id}.mp3"
        audio_file_url = await supabase_client.upload_audio_file(
            file_data=audio_result.audio_data,
            filename=audio_filename,
            story_id=story_id
        )
        
        if audio_file_url:
            logger.info(f"Audio file uploaded successfully: {audio_file_url}")
            return audio_file_url, audio_result.provider_name, audio_result.metadata
        else:
            logger.warning("Failed to upload audio file to Supabase storage")
            return None, None, None
            
    except Exception as e:
        logger.error(f"Error generating or uploading audio: {str(e)}", exc_info=True)
        return None, None, None

