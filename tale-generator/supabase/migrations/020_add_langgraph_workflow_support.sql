-- Migration: Add LangGraph workflow support to stories and create generation_attempts table
-- This migration adds fields to track story quality, generation attempts, and validation results

-- Add new fields to stories table for LangGraph workflow metadata
ALTER TABLE stories
ADD COLUMN IF NOT EXISTS quality_score INTEGER CHECK (quality_score >= 1 AND quality_score <= 10),
ADD COLUMN IF NOT EXISTS generation_attempts_count INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS selected_attempt_number INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS quality_metadata JSONB,
ADD COLUMN IF NOT EXISTS validation_result JSONB,
ADD COLUMN IF NOT EXISTS workflow_metadata JSONB;

-- Add comments to document the new fields
COMMENT ON COLUMN stories.quality_score IS 'Overall quality score (1-10) from LLM assessment';
COMMENT ON COLUMN stories.generation_attempts_count IS 'Total number of generation attempts made';
COMMENT ON COLUMN stories.selected_attempt_number IS 'Which attempt number was selected as best';
COMMENT ON COLUMN stories.quality_metadata IS 'Detailed quality assessment data including scores for each criterion';
COMMENT ON COLUMN stories.validation_result IS 'Prompt validation outcome with safety checks';
COMMENT ON COLUMN stories.workflow_metadata IS 'LangGraph execution metadata including timing and state transitions';

-- Create generation_attempts table to track all generation attempts
CREATE TABLE IF NOT EXISTS generation_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    attempt_number INTEGER NOT NULL CHECK (attempt_number >= 1),
    generated_content TEXT NOT NULL,
    quality_score INTEGER CHECK (quality_score >= 1 AND quality_score <= 10),
    quality_details JSONB,
    model_used VARCHAR(255),
    generation_metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure unique attempt numbers per story
    UNIQUE (story_id, attempt_number)
);

-- Add index for efficient queries by story_id
CREATE INDEX IF NOT EXISTS idx_generation_attempts_story_id ON generation_attempts(story_id);

-- Add index for quality score queries
CREATE INDEX IF NOT EXISTS idx_generation_attempts_quality_score ON generation_attempts(quality_score);

-- Add index for stories quality_score
CREATE INDEX IF NOT EXISTS idx_stories_quality_score ON stories(quality_score);

-- Add comments to generation_attempts table
COMMENT ON TABLE generation_attempts IS 'Tracks all generation attempts for stories using LangGraph workflow';
COMMENT ON COLUMN generation_attempts.story_id IS 'Reference to the final story this attempt belongs to';
COMMENT ON COLUMN generation_attempts.attempt_number IS 'Sequence number of this attempt (1-3)';
COMMENT ON COLUMN generation_attempts.generated_content IS 'Story content generated in this attempt';
COMMENT ON COLUMN generation_attempts.quality_score IS 'Quality score (1-10) for this attempt';
COMMENT ON COLUMN generation_attempts.quality_details IS 'Detailed quality breakdown by criterion';
COMMENT ON COLUMN generation_attempts.model_used IS 'LLM model used for this attempt';
COMMENT ON COLUMN generation_attempts.generation_metadata IS 'Timing, tokens, temperature, and other metadata';

-- Enable Row Level Security on generation_attempts
ALTER TABLE generation_attempts ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for generation_attempts (users can view their own stories' attempts)
CREATE POLICY "Users can view their own story generation attempts"
ON generation_attempts FOR SELECT
USING (
    story_id IN (
        SELECT id FROM stories WHERE user_id = auth.uid()
    )
);

-- Create RLS policy for inserting generation attempts (authenticated users only)
CREATE POLICY "Authenticated users can insert generation attempts"
ON generation_attempts FOR INSERT
WITH CHECK (auth.role() = 'authenticated');
