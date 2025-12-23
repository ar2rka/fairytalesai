-- Add age_category column to children table
ALTER TABLE tales.children 
ADD COLUMN IF NOT EXISTS age_category TEXT;

-- Create index for age_category
CREATE INDEX IF NOT EXISTS idx_children_age_category ON tales.children(age_category);

-- Migrate existing data: convert age to age_category
-- Age mapping: 
--   age 1-3 -> '2-3'
--   age 4-5 -> '3-5'
--   age 6+ -> '5-7'
UPDATE tales.children
SET age_category = CASE
    WHEN age >= 1 AND age <= 3 THEN '2-3'
    WHEN age >= 4 AND age <= 5 THEN '3-5'
    WHEN age >= 6 THEN '5-7'
    ELSE '3-5'  -- Default fallback for any edge cases
END
WHERE age_category IS NULL;

-- Make age_category NOT NULL after migration
ALTER TABLE tales.children 
ALTER COLUMN age_category SET NOT NULL;

-- Add constraint to ensure valid age categories
ALTER TABLE tales.children
ADD CONSTRAINT check_age_category 
CHECK (age_category IN ('2-3', '3-5', '5-7'));
