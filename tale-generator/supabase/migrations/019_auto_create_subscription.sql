-- Migration 019: Automatic subscription creation on user registration
-- Description: Create database trigger to automatically initialize subscription fields
--              when a new user profile is created

-- Step 1: Create trigger function to initialize subscription fields
CREATE OR REPLACE FUNCTION initialize_user_subscription()
RETURNS TRIGGER AS $$
BEGIN
    -- Only set subscription fields if they are NULL
    -- This preserves any explicitly provided values
    
    IF NEW.subscription_plan IS NULL THEN
        NEW.subscription_plan := 'free';
    END IF;
    
    IF NEW.subscription_status IS NULL THEN
        NEW.subscription_status := 'active';
    END IF;
    
    IF NEW.subscription_start_date IS NULL THEN
        NEW.subscription_start_date := NOW();
    END IF;
    
    -- subscription_end_date should remain NULL for free plan
    -- Only set if explicitly provided
    
    IF NEW.monthly_story_count IS NULL THEN
        NEW.monthly_story_count := 0;
    END IF;
    
    IF NEW.last_reset_date IS NULL THEN
        NEW.last_reset_date := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create trigger to invoke the initialization function
DROP TRIGGER IF EXISTS trigger_initialize_user_subscription ON tales.user_profiles;

CREATE TRIGGER trigger_initialize_user_subscription
    BEFORE INSERT ON tales.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_subscription();

-- Add comments for documentation
COMMENT ON FUNCTION initialize_user_subscription() IS 
'Automatically initializes subscription fields with default values when a new user profile is created. Sets free plan, active status, zero story count, and current timestamps.';

COMMENT ON TRIGGER trigger_initialize_user_subscription ON tales.user_profiles IS 
'Ensures every new user gets a free subscription automatically upon registration without requiring application-level logic.';
