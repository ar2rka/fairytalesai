-- Migration 028: Add parent_id to stories table
-- Description: Add support for story continuations by adding parent_id field
-- This allows stories to reference a parent story, enabling continuation narratives

-- Step 1: Add parent_id column to stories (nullable, as not all stories have a parent)
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS parent_id UUID;

-- Step 2: Add foreign key constraint to self-reference stories table
ALTER TABLE tales.stories
ADD CONSTRAINT fk_stories_parent_id 
FOREIGN KEY (parent_id) 
REFERENCES tales.stories(id)
ON DELETE SET NULL;

-- Step 3: Create index on parent_id for query performance
CREATE INDEX IF NOT EXISTS idx_stories_parent_id 
ON tales.stories(parent_id);

-- Step 4: Add comment to document the change
COMMENT ON COLUMN tales.stories.parent_id IS 
'Foreign key reference to parent story for continuation narratives. NULL for standalone stories.';

-- Verify migration results
DO $$
DECLARE
    stories_count INTEGER;
    stories_with_parent INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories;
    SELECT COUNT(*) INTO stories_with_parent FROM tales.stories WHERE parent_id IS NOT NULL;
    
    RAISE NOTICE 'Migration 028 Summary:';
    RAISE NOTICE '  Total stories: %', stories_count;
    RAISE NOTICE '  Stories with parent_id: %', stories_with_parent;
    RAISE NOTICE '  Parent_id column added successfully';
END $$;

