-- Migration 015: Create generations table
-- Description: Create table to track story generation requests and retry attempts
-- This separates generation metadata from story content for better analytics and tracking

-- Create generations table
CREATE TABLE IF NOT EXISTS tales.generations (
    generation_id UUID NOT NULL,
    attempt_number INTEGER NOT NULL,
    model_used TEXT NOT NULL,
    full_response JSONB,
    status TEXT NOT NULL,
    prompt TEXT NOT NULL,
    user_id UUID NOT NULL,
    story_type TEXT NOT NULL,
    story_length INTEGER,
    hero_appearance TEXT,
    relationship_description TEXT,
    moral TEXT NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Composite primary key on generation_id and attempt_number
    PRIMARY KEY (generation_id, attempt_number),
    
    -- Foreign key to auth.users
    CONSTRAINT fk_generations_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id)
    ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_generation_status 
    CHECK (status IN ('pending', 'success', 'failed', 'timeout')),
    
    CONSTRAINT chk_generation_story_type 
    CHECK (story_type IN ('child', 'hero', 'combined')),
    
    CONSTRAINT chk_generation_attempt_number 
    CHECK (attempt_number >= 1),
    
    CONSTRAINT chk_generation_story_length 
    CHECK (story_length IS NULL OR story_length > 0)
);

-- Create indexes for query performance
CREATE INDEX IF NOT EXISTS idx_generations_generation_id 
ON tales.generations(generation_id);

CREATE INDEX IF NOT EXISTS idx_generations_user_id 
ON tales.generations(user_id);

CREATE INDEX IF NOT EXISTS idx_generations_status 
ON tales.generations(status);

CREATE INDEX IF NOT EXISTS idx_generations_created_at 
ON tales.generations(created_at);

CREATE INDEX IF NOT EXISTS idx_generations_model_used 
ON tales.generations(model_used);

-- Create index for latest attempt per generation
CREATE INDEX IF NOT EXISTS idx_generations_latest_attempt 
ON tales.generations(generation_id, attempt_number DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE tales.generations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for generations table

-- Policy: Users can view their own generations
CREATE POLICY "Users can view their own generations" 
ON tales.generations
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: Users can insert their own generations
CREATE POLICY "Users can insert their own generations" 
ON tales.generations
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own generations
CREATE POLICY "Users can update their own generations" 
ON tales.generations
FOR UPDATE
USING (auth.uid() = user_id);

-- Policy: No delete allowed (maintain audit trail)
-- Intentionally no DELETE policy - generations should never be deleted

-- Add table comments for documentation
COMMENT ON TABLE tales.generations IS 
'Tracks story generation requests and retry attempts with full metadata';

COMMENT ON COLUMN tales.generations.generation_id IS 
'Unique identifier for the generation request, created before API call';

COMMENT ON COLUMN tales.generations.attempt_number IS 
'Retry attempt number (1 for first attempt, 2+ for retries)';

COMMENT ON COLUMN tales.generations.model_used IS 
'AI model identifier used for this attempt (e.g., openai/gpt-4o-mini)';

COMMENT ON COLUMN tales.generations.full_response IS 
'Complete OpenRouter API response in JSON format';

COMMENT ON COLUMN tales.generations.status IS 
'Execution status: pending, success, failed, or timeout';

COMMENT ON COLUMN tales.generations.prompt IS 
'Complete prompt sent to OpenRouter for this attempt';

COMMENT ON COLUMN tales.generations.user_id IS 
'Reference to the user who created this generation request';

COMMENT ON COLUMN tales.generations.story_type IS 
'Type of story: child (child-only), hero (hero-only), or combined';

COMMENT ON COLUMN tales.generations.story_length IS 
'Requested story length in minutes';

COMMENT ON COLUMN tales.generations.hero_appearance IS 
'Hero appearance description (for hero and combined stories)';

COMMENT ON COLUMN tales.generations.relationship_description IS 
'Child-hero relationship description (for combined stories)';

COMMENT ON COLUMN tales.generations.moral IS 
'Story moral or lesson to be conveyed';

COMMENT ON COLUMN tales.generations.error_message IS 
'Error details if status is failed or timeout';

COMMENT ON COLUMN tales.generations.created_at IS 
'Timestamp when the generation request was created';

COMMENT ON COLUMN tales.generations.completed_at IS 
'Timestamp when the generation completed (success or failure)';
