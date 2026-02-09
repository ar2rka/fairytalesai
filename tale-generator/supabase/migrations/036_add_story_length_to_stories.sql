-- Migration 036: Add story_length column to stories table
-- Description: Store story length (minutes) in tales.stories for easier queries.
-- Length is also stored in tales.generations; this denormalization matches application expectations.

-- Step 1: Add story_length column (nullable for existing rows)
ALTER TABLE tales.stories
ADD COLUMN IF NOT EXISTS story_length INTEGER;

-- Step 2: Backfill existing stories from generations table
DO $$
BEGIN
    UPDATE tales.stories s
    SET story_length = g.story_length
    FROM tales.generations g
    WHERE s.generation_id = g.generation_id
      AND g.story_length IS NOT NULL
      AND g.attempt_number = (
          SELECT MAX(attempt_number)
          FROM tales.generations
          WHERE generation_id = s.generation_id
      );
    RAISE NOTICE 'Backfilled story_length from generations for existing stories';
END $$;

-- Step 3: Comment
COMMENT ON COLUMN tales.stories.story_length IS
'Requested length of the story in minutes; denormalized from generations for easier queries';
