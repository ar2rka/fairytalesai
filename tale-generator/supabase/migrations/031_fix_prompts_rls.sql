-- Migration 031: Fix RLS policies for prompts table
-- Description: Add anonymous read access to prompts table for public access
-- Prompts should be readable by everyone (they are templates, not sensitive data)

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON tales.prompts;

-- Create policy for anonymous read access (public access)
CREATE POLICY "Enable read access for all users" 
ON tales.prompts
AS PERMISSIVE FOR SELECT
TO public
USING (true);

-- Also keep authenticated users access (for consistency)
CREATE POLICY "Enable read access for authenticated users" 
ON tales.prompts
AS PERMISSIVE FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Service role can view all prompts" 
ON tales.generations
FOR SELECT
TO service_role
USING (true);


-- Verify migration results
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE schemaname = 'tales' AND tablename = 'prompts';
    
    RAISE NOTICE 'Migration 031 Summary:';
    RAISE NOTICE '  RLS policies updated for prompts table';
    RAISE NOTICE '  Total policies: %', policy_count;
    RAISE NOTICE '  Public read access enabled';
END $$;

