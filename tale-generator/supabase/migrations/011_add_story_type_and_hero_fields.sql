-- Migration: Add story_type and hero-related fields to stories table
-- This enables storing combined stories featuring both child and hero characters

-- Add story_type column to discriminate between child, hero, and combined stories
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS story_type TEXT NOT NULL DEFAULT 'child';

-- Add hero_id column as foreign key reference to heroes table
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS hero_id UUID;

-- Add denormalized hero fields for performance
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS hero_name TEXT;

ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS hero_gender TEXT;

ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS hero_appearance TEXT;

-- Add relationship description for combined stories
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS relationship_description TEXT;

-- Add foreign key constraint to heroes table
ALTER TABLE tales.stories
ADD CONSTRAINT fk_stories_hero_id 
FOREIGN KEY (hero_id) 
REFERENCES tales.heroes(id)
ON DELETE RESTRICT;

-- Add check constraint to ensure story_type is valid
ALTER TABLE tales.stories
ADD CONSTRAINT chk_story_type 
CHECK (story_type IN ('child', 'hero', 'combined'));

-- Add check constraint to ensure hero_id is NOT NULL when story_type is hero or combined
ALTER TABLE tales.stories
ADD CONSTRAINT chk_hero_id_required 
CHECK (
    (story_type = 'child' AND hero_id IS NULL) OR
    (story_type IN ('hero', 'combined') AND hero_id IS NOT NULL)
);

-- Create indexes for query performance
CREATE INDEX IF NOT EXISTS idx_stories_story_type 
ON tales.stories(story_type);

CREATE INDEX IF NOT EXISTS idx_stories_hero_id 
ON tales.stories(hero_id) 
WHERE hero_id IS NOT NULL;

-- Add comments to document the columns
COMMENT ON COLUMN tales.stories.story_type IS 
'Type of story: child (child-only), hero (hero-only), or combined (child and hero together)';

COMMENT ON COLUMN tales.stories.hero_id IS 
'Foreign key reference to heroes table, required when story_type is hero or combined';

COMMENT ON COLUMN tales.stories.hero_name IS 
'Denormalized hero name for performance, populated when story_type is hero or combined';

COMMENT ON COLUMN tales.stories.hero_gender IS 
'Denormalized hero gender, populated when story_type is hero or combined';

COMMENT ON COLUMN tales.stories.hero_appearance IS 
'Denormalized hero appearance, populated when story_type is hero or combined';

COMMENT ON COLUMN tales.stories.relationship_description IS 
'Optional description of child-hero relationship, used when story_type is combined';
