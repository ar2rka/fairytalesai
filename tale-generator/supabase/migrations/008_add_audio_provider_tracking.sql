-- Migration: Add audio provider tracking to stories table
-- This enables tracking which voice provider generated the audio
-- and storing provider-specific metadata for analytics and debugging

-- Add audio_provider column to track which provider was used
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS audio_provider TEXT;

-- Add audio_generation_metadata column for provider-specific details
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS audio_generation_metadata JSONB;

-- Add comment to document the columns
COMMENT ON COLUMN tales.stories.audio_provider IS 
'Voice provider used for audio generation (e.g., elevenlabs, google, azure)';

COMMENT ON COLUMN tales.stories.audio_generation_metadata IS 
'Provider-specific metadata from audio generation including settings, voice IDs, and generation details';

-- Create index for querying by provider (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_stories_audio_provider 
ON tales.stories(audio_provider) 
WHERE audio_provider IS NOT NULL;
