-- Add generation_info column to stories table
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS generation_info JSONB;

-- Create index for the generation_info column
CREATE INDEX IF NOT EXISTS idx_stories_generation_info ON tales.stories USING GIN (generation_info);