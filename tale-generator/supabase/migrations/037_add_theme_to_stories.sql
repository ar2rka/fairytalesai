-- Migration 037: Add theme column to stories table
-- Description: Store story theme (e.g. adventure, space, fantasy) for filtering and display.
-- Theme is passed from the API during story generation and used in prompt templates.

-- Step 1: Add theme column (nullable for existing stories)
ALTER TABLE tales.stories
ADD COLUMN IF NOT EXISTS theme TEXT;

-- Step 2: Comment
COMMENT ON COLUMN tales.stories.theme IS
'Story theme/type (e.g. adventure, space, fantasy) - used in prompt generation, stored in English';

-- Step 3: Optional index for theme-based filtering
CREATE INDEX IF NOT EXISTS idx_stories_theme
ON tales.stories(theme)
WHERE theme IS NOT NULL;
