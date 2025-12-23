-- Add model information columns to stories table
ALTER TABLE stories 
ADD COLUMN IF NOT EXISTS model_used TEXT,
ADD COLUMN IF NOT EXISTS full_response JSONB;

-- Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_stories_model_used ON stories(model_used);