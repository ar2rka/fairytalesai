-- Migration 029: Create prompts table for Jinja-based prompt templates
-- Description: Create table to store prompt templates with priority, language, and story_type
-- Prompts are stored as Jinja templates and combined by priority to form final prompts

-- Step 1: Create prompts table
CREATE TABLE IF NOT EXISTS tales.prompts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    priority INTEGER NOT NULL,
    language TEXT NOT NULL,  -- 'en', 'ru'
    story_type TEXT,  -- 'child', 'hero', 'combined', NULL for universal prompts
    prompt_text TEXT NOT NULL,  -- Jinja template
    is_active BOOLEAN DEFAULT true,
    description TEXT,  -- Optional description of the prompt part
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_prompt_combination UNIQUE(language, story_type, priority)
);

-- Step 2: Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_prompts_language_story_type 
ON tales.prompts(language, story_type);

CREATE INDEX IF NOT EXISTS idx_prompts_language 
ON tales.prompts(language);

CREATE INDEX IF NOT EXISTS idx_prompts_priority 
ON tales.prompts(priority);

CREATE INDEX IF NOT EXISTS idx_prompts_is_active 
ON tales.prompts(is_active);

-- Step 3: Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION tales.update_prompts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_prompts_updated_at
BEFORE UPDATE ON tales.prompts
FOR EACH ROW
EXECUTE FUNCTION tales.update_prompts_updated_at();

-- Step 5: Enable Row Level Security (RLS)
ALTER TABLE tales.prompts ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies
-- Allow read access for all authenticated users
CREATE POLICY "Enable read access for authenticated users" 
ON tales.prompts
AS PERMISSIVE FOR SELECT
TO authenticated
USING (true);

-- Allow insert/update/delete only for service role (admin operations)
-- Regular users should not modify prompts directly

-- Step 7: Add comments for documentation
COMMENT ON TABLE tales.prompts IS 
'Stores prompt templates as Jinja templates. Prompts are combined by priority to form final prompts.';

COMMENT ON COLUMN tales.prompts.priority IS 
'Priority determines the order of prompt parts. Lower numbers come first.';

COMMENT ON COLUMN tales.prompts.language IS 
'Language code: ''en'' for English, ''ru'' for Russian.';

COMMENT ON COLUMN tales.prompts.story_type IS 
'Story type: ''child'', ''hero'', ''combined'', or NULL for universal prompts that apply to all types.';

COMMENT ON COLUMN tales.prompts.prompt_text IS 
'Jinja template text that will be rendered with context variables.';

COMMENT ON COLUMN tales.prompts.is_active IS 
'Whether this prompt part is active. Inactive prompts are not used.';

-- Verify migration results
DO $$
DECLARE
    prompts_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO prompts_count FROM tales.prompts;
    
    RAISE NOTICE 'Migration 029 Summary:';
    RAISE NOTICE '  Prompts table created successfully';
    RAISE NOTICE '  Current prompts count: %', prompts_count;
    RAISE NOTICE '  Indexes created: idx_prompts_language_story_type, idx_prompts_language, idx_prompts_priority, idx_prompts_is_active';
    RAISE NOTICE '  RLS enabled with read access for authenticated users';
END $$;

