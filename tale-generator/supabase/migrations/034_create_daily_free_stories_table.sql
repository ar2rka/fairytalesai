-- Create daily_free_stories table for daily free stories
-- These are stories that are published daily and available to all users
CREATE TABLE IF NOT EXISTS tales.daily_free_stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    story_date DATE NOT NULL, -- One story per day
    title TEXT NOT NULL, -- Заголовок истории
    name TEXT NOT NULL, -- Название истории
    content TEXT NOT NULL,
    moral TEXT NOT NULL, -- Мораль истории
    age_category TEXT NOT NULL CHECK (age_category IN ('2-3', '3-5', '5-7')),
    language TEXT NOT NULL CHECK (language IN ('en', 'ru')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_story_date ON tales.daily_free_stories(story_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_age_category ON tales.daily_free_stories(age_category);
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_language ON tales.daily_free_stories(language);
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_is_active ON tales.daily_free_stories(is_active);
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_created_at ON tales.daily_free_stories(created_at DESC);

-- Composite index for common queries (active stories by age and language, sorted by date)
CREATE INDEX IF NOT EXISTS idx_daily_free_stories_active_age_lang_date 
ON tales.daily_free_stories(is_active, age_category, language, story_date DESC);

-- Grant SELECT permissions to anon and authenticated roles for public access
GRANT SELECT ON tales.daily_free_stories TO anon;
GRANT SELECT ON tales.daily_free_stories TO authenticated;


-- Enable Row Level Security (RLS) but with a permissive policy
ALTER TABLE tales.daily_free_stories ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows everyone to read active stories
CREATE POLICY "Anyone can view active daily free stories" 
ON tales.daily_free_stories
FOR SELECT
TO public
USING (is_active = true);

-- Create table for story reactions (likes/dislikes)
CREATE TABLE IF NOT EXISTS tales.daily_story_reactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES tales.daily_free_stories(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL for anonymous users
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(story_id, user_id) -- One reaction per user per story
);

-- Create indexes for reactions
CREATE INDEX IF NOT EXISTS idx_daily_story_reactions_story_id ON tales.daily_story_reactions(story_id);
CREATE INDEX IF NOT EXISTS idx_daily_story_reactions_user_id ON tales.daily_story_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_story_reactions_reaction_type ON tales.daily_story_reactions(reaction_type);
CREATE INDEX IF NOT EXISTS idx_daily_story_reactions_story_user ON tales.daily_story_reactions(story_id, user_id);

-- Grant permissions for reactions
GRANT SELECT, INSERT, UPDATE, DELETE ON tales.daily_story_reactions TO authenticated;
GRANT SELECT ON tales.daily_story_reactions TO anon;

-- Enable RLS for reactions
ALTER TABLE tales.daily_story_reactions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view all reactions
CREATE POLICY "Anyone can view reactions" 
ON tales.daily_story_reactions
FOR SELECT
TO public
USING (true);

-- Policy: Authenticated users can create/update their own reactions
CREATE POLICY "Users can manage their own reactions" 
ON tales.daily_story_reactions
FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Anonymous users can create reactions (with NULL user_id)
CREATE POLICY "Anonymous users can create reactions" 
ON tales.daily_story_reactions
FOR INSERT
TO anon
WITH CHECK (user_id IS NULL);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_daily_free_stories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_daily_free_stories_updated_at_trigger
    BEFORE UPDATE ON tales.daily_free_stories
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_free_stories_updated_at();

-- Create function to update reactions updated_at timestamp
CREATE OR REPLACE FUNCTION update_daily_story_reactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for reactions updated_at
CREATE TRIGGER update_daily_story_reactions_updated_at_trigger
    BEFORE UPDATE ON tales.daily_story_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_story_reactions_updated_at();

