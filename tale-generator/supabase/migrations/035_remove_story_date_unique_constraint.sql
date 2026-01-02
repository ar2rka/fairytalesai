-- Migration 035: Remove UNIQUE constraint from story_date column and grant INSERT to service_role
-- This allows multiple stories per day for different age categories and languages

-- Drop the UNIQUE constraint on story_date
-- PostgreSQL automatically creates constraint names like: {table_name}_{column_name}_key
-- We'll try to find and drop the constraint dynamically
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Find the unique constraint name on story_date column
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'tales.daily_free_stories'::regclass
      AND contype = 'u'
      AND array_length(conkey, 1) = 1
      AND conkey[1] = (
          SELECT attnum
          FROM pg_attribute
          WHERE attrelid = 'tales.daily_free_stories'::regclass
            AND attname = 'story_date'
      );
    
    -- Drop the constraint if it exists
    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE tales.daily_free_stories DROP CONSTRAINT %I', constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    END IF;
END $$;

-- Grant all necessary permissions to service_role
-- This allows backend to manage daily free stories
-- Note: service_role key bypasses RLS, but explicit GRANT ensures permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON tales.daily_free_stories TO service_role;

-- Also grant permissions to authenticated role (in case backend uses authenticated key)
GRANT INSERT, UPDATE, DELETE ON tales.daily_free_stories TO authenticated;

-- Grant usage on schema (if not already granted)
GRANT USAGE ON SCHEMA tales TO service_role;
GRANT USAGE ON SCHEMA tales TO authenticated;

-- Create RLS policies for service_role (for consistency)
-- Note: service_role typically bypasses RLS, but this ensures explicit permission
DROP POLICY IF EXISTS "Service role can view all daily free stories" ON tales.daily_free_stories;
DROP POLICY IF EXISTS "Service role can insert daily free stories" ON tales.daily_free_stories;
DROP POLICY IF EXISTS "Service role can update daily free stories" ON tales.daily_free_stories;
DROP POLICY IF EXISTS "Service role can delete daily free stories" ON tales.daily_free_stories;

CREATE POLICY "Service role can view all daily free stories" 
ON tales.daily_free_stories
FOR SELECT
TO service_role
USING (true);

CREATE POLICY "Service role can insert daily free stories" 
ON tales.daily_free_stories
FOR INSERT
TO service_role
WITH CHECK (true);

CREATE POLICY "Service role can update daily free stories" 
ON tales.daily_free_stories
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Service role can delete daily free stories" 
ON tales.daily_free_stories
FOR DELETE
TO service_role
USING (true);

