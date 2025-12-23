-- Add rating column to stories table
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS rating INTEGER CHECK (rating >= 1 AND rating <= 10);

-- Create index for the rating column
CREATE INDEX IF NOT EXISTS idx_stories_rating ON tales.stories(rating);

-- Update existing rows to have a default rating if needed
UPDATE tales.stories 
SET rating = NULL 
WHERE rating IS NULL;