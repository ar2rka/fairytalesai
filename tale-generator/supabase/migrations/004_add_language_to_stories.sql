-- Add language column to stories table
ALTER TABLE tales.stories 
ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'en';

-- Create index for the language column
CREATE INDEX IF NOT EXISTS idx_stories_language ON tales.stories(language);

-- Update existing rows to have a default language if needed
UPDATE tales.stories 
SET language = 'en' 
WHERE language IS NULL;