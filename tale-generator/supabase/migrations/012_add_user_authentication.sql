-- Create user_profiles table to extend Supabase Auth
CREATE TABLE IF NOT EXISTS tales.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Create an index on the id column for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON tales.user_profiles(id);

-- Enable Row Level Security
ALTER TABLE tales.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_profiles
-- Users can view their own profile
CREATE POLICY "Users can view their own profile"
    ON tales.user_profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert their own profile"
    ON tales.user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
    ON tales.user_profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Add user_id column to existing children table
ALTER TABLE tales.children ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index on user_id for performance
CREATE INDEX IF NOT EXISTS idx_children_user_id ON tales.children(user_id);

-- Enable RLS on children table if not already enabled
ALTER TABLE tales.children ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own children" ON tales.children;
DROP POLICY IF EXISTS "Users can insert their own children" ON tales.children;
DROP POLICY IF EXISTS "Users can update their own children" ON tales.children;
DROP POLICY IF EXISTS "Users can delete their own children" ON tales.children;

-- Create RLS policies for children table
CREATE POLICY "Users can view their own children"
    ON tales.children
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own children"
    ON tales.children
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own children"
    ON tales.children
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own children"
    ON tales.children
    FOR DELETE
    USING (auth.uid() = user_id);

-- Add user_id column to existing stories table
ALTER TABLE tales.stories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create index on user_id for performance
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON tales.stories(user_id);

-- Enable RLS on stories table if not already enabled
ALTER TABLE tales.stories ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own stories" ON tales.stories;
DROP POLICY IF EXISTS "Users can insert their own stories" ON tales.stories;
DROP POLICY IF EXISTS "Users can update their own stories" ON tales.stories;
DROP POLICY IF EXISTS "Users can delete their own stories" ON tales.stories;

-- Create RLS policies for stories table
CREATE POLICY "Users can view their own stories"
    ON tales.stories
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own stories"
    ON tales.stories
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stories"
    ON tales.stories
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own stories"
    ON tales.stories
    FOR DELETE
    USING (auth.uid() = user_id);

-- Create a function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user_profiles updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON tales.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON tales.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Note: You may need to manually migrate existing data to set user_id values
-- This migration creates the schema but existing children and stories will need
-- their user_id fields populated manually or through a data migration script.
