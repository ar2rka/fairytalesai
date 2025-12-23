-- Create free_stories table for publicly accessible stories
-- This table has no RLS - it's fully public and accessible to everyone
CREATE TABLE IF NOT EXISTS tales.free_stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    age_category TEXT NOT NULL CHECK (age_category IN ('2-3', '3-5', '5-7')),
    language TEXT NOT NULL CHECK (language IN ('en', 'ru')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_free_stories_age_category ON tales.free_stories(age_category);
CREATE INDEX IF NOT EXISTS idx_free_stories_language ON tales.free_stories(language);
CREATE INDEX IF NOT EXISTS idx_free_stories_is_active ON tales.free_stories(is_active);
CREATE INDEX IF NOT EXISTS idx_free_stories_created_at ON tales.free_stories(created_at DESC);

-- Composite index for common queries (active stories by age and language, sorted by created_at)
CREATE INDEX IF NOT EXISTS idx_free_stories_active_age_lang_created 
ON tales.free_stories(is_active, age_category, language, created_at DESC);

-- Grant SELECT permissions to anon and authenticated roles for public access
-- This allows the table to be accessible through Supabase PostgREST API
GRANT SELECT ON tales.free_stories TO anon;
GRANT SELECT ON tales.free_stories TO authenticated;

-- Enable Row Level Security (RLS) but with a permissive policy
-- This allows the table to be accessible while still using RLS framework
ALTER TABLE tales.free_stories ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows everyone to read active stories
CREATE POLICY "Anyone can view active free stories" 
ON tales.free_stories
FOR SELECT
TO public
USING (is_active = true);

