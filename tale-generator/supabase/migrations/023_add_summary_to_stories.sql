-- Migration 023: Add summary column to stories table
-- Description: Add summary field to store brief story summaries (2-3 sentences)

-- Step 1: Add summary column to stories table (nullable initially for existing stories)
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS summary TEXT;

-- Step 2: Add comment to document the column
COMMENT ON COLUMN tales.stories.summary IS 
'Brief summary of the story in 2-3 sentences, generated automatically from the story content';

-- Step 3: Verify migration
DO $$
DECLARE
    stories_count INTEGER;
    stories_with_summary INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories;
    SELECT COUNT(*) INTO stories_with_summary FROM tales.stories WHERE summary IS NOT NULL;
    
    RAISE NOTICE 'Migration 023 Summary:';
    RAISE NOTICE '  Total stories: %', stories_count;
    RAISE NOTICE '  Stories with summary: %', stories_with_summary;
    RAISE NOTICE 'Summary column added successfully to stories table';
END $$;
