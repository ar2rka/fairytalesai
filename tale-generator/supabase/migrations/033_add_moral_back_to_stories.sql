-- Migration 033: Add moral column back to stories table
-- Description: Add moral field back to stories table (it was removed in migration 017)
-- The moral is also stored in generations table, but we need it in stories for easier queries
-- and to match the application code expectations

-- Step 1: Add moral column to stories table (nullable initially for existing stories)
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS moral TEXT;

-- Step 2: Migrate existing data from generations table if possible
-- This will populate moral for stories that have a generation_id
DO $$
BEGIN
    UPDATE tales.stories s
    SET moral = (
        SELECT g.moral 
        FROM tales.generations g 
        WHERE g.generation_id = s.generation_id 
        AND g.attempt_number = (
            SELECT MAX(attempt_number) 
            FROM tales.generations 
            WHERE generation_id = s.generation_id
        )
        LIMIT 1
    )
    WHERE s.moral IS NULL 
    AND s.generation_id IS NOT NULL;
    
    RAISE NOTICE 'Migrated moral from generations table for existing stories';
END $$;

-- Step 3: Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_stories_moral 
ON tales.stories(moral) 
WHERE moral IS NOT NULL;

-- Step 4: Add comment to document the column
COMMENT ON COLUMN tales.stories.moral IS 
'The moral value or lesson of the story, denormalized from generations table for easier queries';

-- Step 5: Verify migration
DO $$
DECLARE
    stories_count INTEGER;
    stories_with_moral INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories;
    SELECT COUNT(*) INTO stories_with_moral FROM tales.stories WHERE moral IS NOT NULL;
    
    RAISE NOTICE 'Migration 033 Summary:';
    RAISE NOTICE '  Total stories: %', stories_count;
    RAISE NOTICE '  Stories with moral: %', stories_with_moral;
    RAISE NOTICE 'moral column added successfully to stories table';
END $$;

