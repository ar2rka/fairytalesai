-- Migration: Add user_id column to heroes table
-- Description: Add user_id column to heroes table to track ownership

-- Add user_id column to heroes table
ALTER TABLE tales.heroes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index on user_id for performance
CREATE INDEX IF NOT EXISTS idx_heroes_user_id ON tales.heroes(user_id);

-- Enable RLS on heroes table if not already enabled
ALTER TABLE tales.heroes ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own heroes or unowned heroes" ON tales.heroes;
DROP POLICY IF EXISTS "Users can insert their own heroes" ON tales.heroes;
DROP POLICY IF EXISTS "Users can update their own heroes" ON tales.heroes;
DROP POLICY IF EXISTS "Users can delete their own heroes" ON tales.heroes;

-- Create RLS policies for heroes table
-- Users can view their own heroes or heroes without owners
CREATE POLICY "Users can view their own heroes or unowned heroes"
    ON tales.heroes
    FOR SELECT
    USING (user_id IS NULL OR auth.uid() = user_id);

-- Users can insert their own heroes
CREATE POLICY "Users can insert their own heroes"
    ON tales.heroes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own heroes
CREATE POLICY "Users can update their own heroes"
    ON tales.heroes
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own heroes
CREATE POLICY "Users can delete their own heroes"
    ON tales.heroes
    FOR DELETE
    USING (auth.uid() = user_id);