-- Migration: Add status column to stories table
-- Description: Add status column to stories table to track read/archive status

-- Add status column to stories table with default value 'new'
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'new';

-- Create index on status for performance
CREATE INDEX IF NOT EXISTS idx_stories_status ON tales.stories(status);

-- Add constraint to ensure status is one of the allowed values
ALTER TABLE tales.stories 
ADD CONSTRAINT chk_stories_status 
CHECK (status IN ('new', 'read', 'archived'));

-- Add comment for documentation
COMMENT ON COLUMN tales.stories.status IS 'Status of the story: new, read, or archived';