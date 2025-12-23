-- Migration 016: Migrate story generation data to generations table
-- Description: Copy generation metadata from stories table to new generations table
-- This preserves historical generation data while preparing for table restructuring

-- Create a temporary table to store the mapping between stories and generation_ids
CREATE TEMP TABLE IF NOT EXISTS story_generation_mapping (
    story_id UUID PRIMARY KEY,
    generation_id UUID NOT NULL
);

-- Migrate data from stories to generations table
-- Generate a unique generation_id for each existing story
-- Assume all existing stories succeeded on first attempt (attempt_number = 1)
INSERT INTO tales.generations (
    generation_id,
    attempt_number,
    model_used,
    full_response,
    status,
    prompt,
    user_id,
    story_type,
    story_length,
    hero_appearance,
    relationship_description,
    moral,
    error_message,
    created_at,
    completed_at
)
SELECT 
    gen_random_uuid() AS generation_id,
    1 AS attempt_number,
    COALESCE(s.model_used, 'unknown') AS model_used,
    s.full_response,
    'success' AS status,
    '' AS prompt,  -- Historical prompts not available
    s.user_id,
    COALESCE(s.story_type, 'child') AS story_type,
    s.story_length,
    s.hero_appearance,
    s.relationship_description,
    COALESCE(s.moral, 'kindness') AS moral,
    NULL AS error_message,
    s.created_at,
    s.created_at AS completed_at
FROM tales.stories s
WHERE s.user_id IS NOT NULL  -- Only migrate stories with user_id
RETURNING generation_id, created_at;

-- Store the mapping for use in the next migration
-- We'll need to create a persistent mapping table since TEMP tables aren't accessible across migrations
CREATE TABLE IF NOT EXISTS tales.story_generation_id_mapping (
    story_id UUID PRIMARY KEY,
    generation_id UUID NOT NULL,
    migrated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Populate the mapping table by matching stories with generations based on user_id and created_at
-- This is a best-effort match since we don't have a direct link yet
WITH ranked_generations AS (
    SELECT 
        g.generation_id,
        g.user_id,
        g.created_at,
        ROW_NUMBER() OVER (PARTITION BY g.user_id, g.created_at ORDER BY g.generation_id) as gen_rn
    FROM tales.generations g
),
ranked_stories AS (
    SELECT 
        s.id as story_id,
        s.user_id,
        s.created_at,
        ROW_NUMBER() OVER (PARTITION BY s.user_id, s.created_at ORDER BY s.id) as story_rn
    FROM tales.stories s
    WHERE s.user_id IS NOT NULL
)
INSERT INTO tales.story_generation_id_mapping (story_id, generation_id)
SELECT 
    rs.story_id,
    rg.generation_id
FROM ranked_stories rs
INNER JOIN ranked_generations rg 
    ON rs.user_id = rg.user_id 
    AND rs.created_at = rg.created_at
    AND rs.story_rn = rg.gen_rn;

-- Add index on mapping table for quick lookups
CREATE INDEX IF NOT EXISTS idx_story_generation_mapping_story_id 
ON tales.story_generation_id_mapping(story_id);

CREATE INDEX IF NOT EXISTS idx_story_generation_mapping_generation_id 
ON tales.story_generation_id_mapping(generation_id);

-- Add comment to mapping table
COMMENT ON TABLE tales.story_generation_id_mapping IS 
'Temporary mapping table for migration - links stories to their generation_id';

-- Verify migration results
DO $$
DECLARE
    stories_count INTEGER;
    generations_count INTEGER;
    mapping_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO stories_count FROM tales.stories WHERE user_id IS NOT NULL;
    SELECT COUNT(*) INTO generations_count FROM tales.generations;
    SELECT COUNT(*) INTO mapping_count FROM tales.story_generation_id_mapping;
    
    RAISE NOTICE 'Migration 016 Summary:';
    RAISE NOTICE '  Stories with user_id: %', stories_count;
    RAISE NOTICE '  Generations created: %', generations_count;
    RAISE NOTICE '  Mappings created: %', mapping_count;
    
    IF generations_count <> stories_count THEN
        RAISE WARNING 'Generation count (%) does not match story count (%)', 
            generations_count, stories_count;
    END IF;
    
    IF mapping_count <> stories_count THEN
        RAISE WARNING 'Mapping count (%) does not match story count (%)', 
            mapping_count, stories_count;
    END IF;
END $$;
