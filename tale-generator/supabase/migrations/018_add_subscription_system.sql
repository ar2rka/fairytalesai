-- Migration: Add subscription system to user_profiles and create usage_tracking table
-- Description: Implements tariff plan limits with subscription tiers and usage tracking

-- Step 1: Add subscription fields to user_profiles table
ALTER TABLE tales.user_profiles 
ADD COLUMN IF NOT EXISTS subscription_plan TEXT NOT NULL DEFAULT 'free',
ADD COLUMN IF NOT EXISTS subscription_status TEXT NOT NULL DEFAULT 'active',
ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS subscription_end_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS monthly_story_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_reset_date TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Add check constraint for valid subscription plans
ALTER TABLE tales.user_profiles 
ADD CONSTRAINT check_subscription_plan 
CHECK (subscription_plan IN ('free', 'starter', 'normal', 'premium'));

-- Add check constraint for valid subscription status
ALTER TABLE tales.user_profiles 
ADD CONSTRAINT check_subscription_status 
CHECK (subscription_status IN ('active', 'inactive', 'cancelled', 'expired'));

-- Create index for efficient subscription queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription 
ON tales.user_profiles(subscription_plan, subscription_status);

-- Step 2: Create usage_tracking table
CREATE TABLE IF NOT EXISTS tales.usage_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    action_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resource_id UUID,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add check constraint for valid action types
ALTER TABLE tales.usage_tracking 
ADD CONSTRAINT check_action_type 
CHECK (action_type IN ('story_generation', 'audio_generation', 'child_creation'));

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_id 
ON tales.usage_tracking(user_id);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_timestamp 
ON tales.usage_tracking(user_id, action_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_usage_tracking_action_type 
ON tales.usage_tracking(action_type);

-- Enable Row Level Security
ALTER TABLE tales.usage_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies for usage_tracking table

-- Policy: Users can view their own usage tracking
CREATE POLICY "Users can view their own usage tracking" 
ON tales.usage_tracking
FOR SELECT
USING (auth.uid() = user_id);

-- Policy: System can insert usage tracking (service role only)
-- Note: In production, this should be restricted to service role
CREATE POLICY "Service can insert usage tracking" 
ON tales.usage_tracking
FOR INSERT
WITH CHECK (true);

-- Policy: No updates or deletes allowed (append-only audit trail)
-- Intentionally no UPDATE or DELETE policies

-- Step 3: Create helper function to check if monthly reset is needed
CREATE OR REPLACE FUNCTION tales.check_and_reset_monthly_counter(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_last_reset_date TIMESTAMPTZ;
    v_current_month TEXT;
    v_last_reset_month TEXT;
BEGIN
    -- Get the last reset date
    SELECT last_reset_date INTO v_last_reset_date
    FROM tales.user_profiles
    WHERE id = p_user_id;
    
    -- Extract month-year strings for comparison
    v_current_month := TO_CHAR(NOW(), 'YYYY-MM');
    v_last_reset_month := TO_CHAR(v_last_reset_date, 'YYYY-MM');
    
    -- If we're in a different month, reset the counter
    IF v_current_month != v_last_reset_month THEN
        UPDATE tales.user_profiles
        SET monthly_story_count = 0,
            last_reset_date = NOW()
        WHERE id = p_user_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Backfill existing users with default subscription data
-- Set subscription_start_date to user creation date for existing users
UPDATE tales.user_profiles
SET subscription_start_date = created_at
WHERE subscription_start_date IS NULL;

-- Count stories for current month and set monthly_story_count for existing users
UPDATE tales.user_profiles up
SET monthly_story_count = (
    SELECT COUNT(*)
    FROM tales.stories s
    WHERE s.user_id = up.id
    AND EXTRACT(YEAR FROM s.created_at) = EXTRACT(YEAR FROM NOW())
    AND EXTRACT(MONTH FROM s.created_at) = EXTRACT(MONTH FROM NOW())
)
WHERE EXISTS (
    SELECT 1 FROM tales.stories s WHERE s.user_id = up.id
);

-- Add table comments for documentation
COMMENT ON TABLE tales.usage_tracking IS 
'Tracks user actions for subscription limit enforcement and analytics';

COMMENT ON COLUMN tales.user_profiles.subscription_plan IS 
'User subscription tier: free, starter, normal, or premium';

COMMENT ON COLUMN tales.user_profiles.subscription_status IS 
'Subscription status: active, inactive, cancelled, or expired';

COMMENT ON COLUMN tales.user_profiles.monthly_story_count IS 
'Number of stories generated in current calendar month';

COMMENT ON COLUMN tales.user_profiles.last_reset_date IS 
'Timestamp of last monthly counter reset';

COMMENT ON COLUMN tales.usage_tracking.action_type IS 
'Type of action: story_generation, audio_generation, or child_creation';

COMMENT ON COLUMN tales.usage_tracking.metadata IS 
'Additional context such as plan at time of action, feature used, etc.';
