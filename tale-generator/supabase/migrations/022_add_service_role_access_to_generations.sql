-- Migration 022: Add service role access to generations table
-- Description: Allow service role (backend) to read all generations for admin endpoints
-- This is needed because RLS policies only allow users to see their own generations,
-- but admin endpoints need to see all generations
--
-- NOTE: If you're using service_role key in your backend, it automatically bypasses RLS
-- and this migration is not strictly necessary. However, if you're using anon key,
-- you'll need to either:
-- 1. Switch to service_role key (recommended for backend)
-- 2. Or apply this migration to allow service_role access
--
-- To check which key you're using:
-- - service_role key: starts with "eyJ..." and is much longer, found in Supabase Dashboard -> Settings -> API -> service_role key
-- - anon key: also starts with "eyJ..." but shorter, found in Supabase Dashboard -> Settings -> API -> anon public key

-- Drop existing policies if they exist (idempotent)
DROP POLICY IF EXISTS "Service role can view all generations" ON tales.generations;
DROP POLICY IF EXISTS "Service role can insert generations" ON tales.generations;
DROP POLICY IF EXISTS "Service role can update generations" ON tales.generations;

-- Policy: Service role can view all generations
-- This policy allows the service role key (used by backend) to bypass RLS
-- and read all generation records for admin purposes
CREATE POLICY "Service role can view all generations" 
ON tales.generations
FOR SELECT
TO service_role
USING (true);

-- Policy: Service role can insert generations
-- This allows backend to create generation records on behalf of users
CREATE POLICY "Service role can insert generations" 
ON tales.generations
FOR INSERT
TO service_role
WITH CHECK (true);

-- Policy: Service role can update generations
-- This allows backend to update generation records (e.g., status changes)
CREATE POLICY "Service role can update generations" 
ON tales.generations
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);








