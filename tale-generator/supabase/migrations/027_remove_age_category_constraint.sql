-- Remove strict age_category constraint to allow flexible age intervals
-- This migration removes the CHECK constraint that only allowed '2-3', '3-5', '5-7'
-- Now age_category can be any valid age interval string (e.g., '2-3 года', '4-5', '6-7 лет')

-- Drop the constraint from children table
ALTER TABLE tales.children
DROP CONSTRAINT IF EXISTS check_age_category;

-- Drop the constraint from free_stories table
ALTER TABLE tales.free_stories
DROP CONSTRAINT IF EXISTS free_stories_age_category_check;

-- Note: The application layer will handle validation and normalization of age_category
-- The database will store the normalized format (e.g., '2-3', '4-5', '6-7')

