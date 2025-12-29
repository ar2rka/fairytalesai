-- Migration 032: Add child_age_category column to stories table
-- Description: Add child_age_category field to replace child_age (which was removed)
-- This aligns with the change from age to age_category in children table

-- Step 1: Add child_age_category column to stories table (nullable initially for existing stories)
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS child_age_category TEXT;

-- Step 2: Migrate existing data from child_age to child_age_category if child_age still exists
-- Age mapping: 
--   age 1-3 -> '2-3'
--   age 4-5 -> '3-5'
--   age 6+ -> '5-7'
DO $$
BEGIN
    -- Check if child_age column still exists
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'tales' 
        AND table_name = 'stories' 
        AND column_name = 'child_age'
    ) THEN
        -- Migrate existing data
        UPDATE tales.stories
        SET child_age_category = CASE
            WHEN child_age >= 1 AND child_age <= 3 THEN '2-3'
            WHEN child_age >= 4 AND child_age <= 5 THEN '3-5'
            WHEN child_age >= 6 THEN '5-7'
            ELSE '3-5'  -- Default fallback
        END
        WHERE child_age_category IS NULL AND child_age IS NOT NULL;
        
        RAISE NOTICE 'Migrated child_age to child_age_category for existing stories';
    ELSE
        RAISE NOTICE 'child_age column does not exist, skipping migration';
    END IF;
END $$;

-- Step 3: Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_stories_child_age_category 
ON tales.stories(child_age_category) 
WHERE child_age_category IS NOT NULL;

-- Step 4: Add comment to document the column
COMMENT ON COLUMN tales.stories.child_age_category IS 
'Age category of the child (e.g., "2-3", "3-5", "5-7"), denormalized from children table for easier queries';

-- Step 5: Verify migration
DO $$
DECLARE
    stories_count INTEGER;
    stories_with_age_category INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories;
    SELECT COUNT(*) INTO stories_with_age_category FROM tales.stories WHERE child_age_category IS NOT NULL;
    
    RAISE NOTICE 'Migration 032 Summary:';
    RAISE NOTICE '  Total stories: %', stories_count;
    RAISE NOTICE '  Stories with child_age_category: %', stories_with_age_category;
    RAISE NOTICE 'child_age_category column added successfully to stories table';
END $$;

