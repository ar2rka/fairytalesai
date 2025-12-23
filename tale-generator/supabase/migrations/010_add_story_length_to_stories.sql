-- Migration: Add story_length column to stories table
-- This enables storing the requested length of the story in minutes

-- Add story_length column to store the requested story length
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS story_length INTEGER;

-- Add comment to document the column
COMMENT ON COLUMN tales.stories.story_length IS 
'Requested length of the story in minutes';

-- Create index for querying by story_length (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_stories_story_length 
ON tales.stories(story_length) 
WHERE story_length IS NOT NULL;