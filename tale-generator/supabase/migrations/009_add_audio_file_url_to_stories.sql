-- Migration: Add audio_file_url column to stories table
-- This enables storing the URL of the generated audio file

-- Add audio_file_url column to store the URL of the generated audio file
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS audio_file_url TEXT;

-- Add comment to document the column
COMMENT ON COLUMN tales.stories.audio_file_url IS 
'URL of the generated audio file stored in Supabase storage';

-- Create index for querying by audio_file_url (useful for finding stories with audio)
CREATE INDEX IF NOT EXISTS idx_stories_audio_file_url 
ON tales.stories(audio_file_url) 
WHERE audio_file_url IS NOT NULL;