-- Migration 017: Update stories table structure
-- Description: Add generation_id to stories and drop deprecated columns
-- This completes the separation of story content from generation metadata

-- Step 1: Add generation_id column to stories (initially nullable)
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS generation_id UUID;

-- Step 2: Populate generation_id from the mapping table
UPDATE tales.stories s
SET generation_id = m.generation_id
FROM tales.story_generation_id_mapping m
WHERE s.id = m.story_id;

-- Step 3: Add NOT NULL constraint to generation_id
-- First check if there are any NULL values
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count 
    FROM tales.stories 
    WHERE generation_id IS NULL AND user_id IS NOT NULL;
    
    IF null_count > 0 THEN
        RAISE WARNING '% stories have NULL generation_id', null_count;
        RAISE EXCEPTION 'Cannot add NOT NULL constraint - some stories missing generation_id';
    END IF;
END $$;

-- Add NOT NULL constraint
ALTER TABLE tales.stories 
ALTER COLUMN generation_id SET NOT NULL;

-- Step 4: Add foreign key constraint to generations table
ALTER TABLE tales.stories
ADD CONSTRAINT fk_stories_generation_id 
FOREIGN KEY (generation_id) 
REFERENCES tales.generations(generation_id)
ON DELETE RESTRICT;

-- Step 5: Create index on generation_id for join performance
CREATE INDEX IF NOT EXISTS idx_stories_generation_id 
ON tales.stories(generation_id);

-- Step 6: Drop deprecated columns from stories table
-- These are now stored in the generations table

-- Drop model_used column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS model_used;

-- Drop full_response column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS full_response;

-- Drop generation_info column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS generation_info;

-- Drop story_type column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS story_type;

-- Drop story_length column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS story_length;

-- Drop moral column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS moral;

-- Drop hero_appearance column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS hero_appearance;

-- Drop relationship_description column
ALTER TABLE tales.stories 
DROP COLUMN IF EXISTS relationship_description;

-- Step 7: Drop indexes that are no longer needed
DROP INDEX IF EXISTS tales.idx_stories_model_used;
DROP INDEX IF EXISTS tales.idx_stories_story_type;
DROP INDEX IF EXISTS tales.idx_stories_generation_info;

-- Step 8: Clean up the mapping table (optional - can be kept for audit)
-- Uncomment the following line if you want to drop the mapping table after migration
-- DROP TABLE IF EXISTS tales.story_generation_id_mapping;

-- Add comment to document the change
COMMENT ON COLUMN tales.stories.generation_id IS 
'Foreign key reference to generations table containing generation metadata';

-- Verify migration results
DO $$
DECLARE
    stories_count INTEGER;
    stories_with_gen_id INTEGER;
    orphaned_stories INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories;
    SELECT COUNT(*) INTO stories_with_gen_id FROM tales.stories WHERE generation_id IS NOT NULL;
    
    -- Check for orphaned stories (stories without valid generation_id)
    SELECT COUNT(*) INTO orphaned_stories 
    FROM tales.stories s
    LEFT JOIN tales.generations g ON s.generation_id = g.generation_id
    WHERE g.generation_id IS NULL;
    
    RAISE NOTICE 'Migration 017 Summary:';
    RAISE NOTICE '  Total stories: %', stories_count;
    RAISE NOTICE '  Stories with generation_id: %', stories_with_gen_id;
    RAISE NOTICE '  Orphaned stories: %', orphaned_stories;
    
    IF orphaned_stories > 0 THEN
        RAISE WARNING 'Found % orphaned stories without valid generation_id', orphaned_stories;
    END IF;
    
    RAISE NOTICE 'Stories table restructuring complete';
    RAISE NOTICE 'Deprecated columns removed: model_used, full_response, generation_info, story_type, story_length, moral, hero_appearance, relationship_description';
END $$;
