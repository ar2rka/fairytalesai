-- Migration: Create heroes table
-- Description: Create the heroes table to store hero information for story generation

-- Create the heroes table
CREATE TABLE IF NOT EXISTS tales.heroes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    gender TEXT NOT NULL,
    appearance TEXT NOT NULL,
    personality_traits TEXT[] NOT NULL,
    interests TEXT[] NOT NULL,
    strengths TEXT[] NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_heroes_name ON tales.heroes(name);
CREATE INDEX IF NOT EXISTS idx_heroes_language ON tales.heroes(language);

-- Add comments for documentation
COMMENT ON TABLE tales.heroes IS 'Table storing hero information for story generation';
COMMENT ON COLUMN tales.heroes.id IS 'Unique identifier for the hero';
COMMENT ON COLUMN tales.heroes.name IS 'Name of the hero';
COMMENT ON COLUMN tales.heroes.gender IS 'Gender of the hero';
COMMENT ON COLUMN tales.heroes.appearance IS 'Physical description of the hero';
COMMENT ON COLUMN tales.heroes.personality_traits IS 'List of personality traits';
COMMENT ON COLUMN tales.heroes.interests IS 'List of interests/hobbies';
COMMENT ON COLUMN tales.heroes.strengths IS 'List of strengths/powers';
COMMENT ON COLUMN tales.heroes.language IS 'Language code for the hero (en, ru)';
COMMENT ON COLUMN tales.heroes.created_at IS 'Timestamp when the hero was created';
COMMENT ON COLUMN tales.heroes.updated_at IS 'Timestamp when the hero was last updated';
