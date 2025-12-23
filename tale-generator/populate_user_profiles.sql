-- SQL script to populate user_profiles table for all existing users
-- This script will create user profiles for all users in auth.users that don't already have profiles

-- First, let's check what users exist in auth.users
SELECT 
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC;

-- Check existing user profiles
SELECT 
    id,
    name,
    created_at
FROM tales.user_profiles;

-- Insert user profiles for users who don't have them yet
-- We'll use the email as the name for now, which can be updated later
INSERT INTO tales.user_profiles (id, name, created_at, updated_at)
SELECT 
    u.id,
    COALESCE(u.email, 'User ' || LEFT(u.id::text, 8)) as name,
    u.created_at,
    NOW() as updated_at
FROM auth.users u
LEFT JOIN tales.user_profiles up ON u.id = up.id
WHERE up.id IS NULL;

-- Now let's also populate the subscription data for all users
UPDATE tales.user_profiles
SET 
    subscription_plan = COALESCE(subscription_plan, 'free'),
    subscription_status = COALESCE(subscription_status, 'active'),
    subscription_start_date = COALESCE(subscription_start_date, created_at),
    last_reset_date = COALESCE(last_reset_date, NOW()),
    monthly_story_count = COALESCE(monthly_story_count, 0)
WHERE 
    subscription_plan IS NULL 
    OR subscription_status IS NULL 
    OR subscription_start_date IS NULL 
    OR last_reset_date IS NULL;

-- For users with no stories counted yet, count their existing stories for the current month
UPDATE tales.user_profiles up
SET monthly_story_count = (
    SELECT COUNT(*)
    FROM tales.stories s
    WHERE s.user_id = up.id
    AND EXTRACT(YEAR FROM s.created_at) = EXTRACT(YEAR FROM NOW())
    AND EXTRACT(MONTH FROM s.created_at) = EXTRACT(MONTH FROM NOW())
)
WHERE monthly_story_count = 0
AND EXISTS (
    SELECT 1 FROM tales.stories s WHERE s.user_id = up.id
);

-- Assign different plans based on user activity (example logic)
-- Premium users: More than 50 stories generated
UPDATE tales.user_profiles up
SET subscription_plan = 'premium'
WHERE (
    SELECT COUNT(*) 
    FROM tales.stories s 
    WHERE s.user_id = up.id
) > 50;

-- Normal users: 10-50 stories generated
UPDATE tales.user_profiles up
SET subscription_plan = 'normal'
WHERE subscription_plan = 'free'
AND (
    SELECT COUNT(*) 
    FROM tales.stories s 
    WHERE s.user_id = up.id
) BETWEEN 10 AND 50;

-- Starter users: 1-9 stories generated
UPDATE tales.user_profiles up
SET subscription_plan = 'starter'
WHERE subscription_plan = 'free'
AND (
    SELECT COUNT(*) 
    FROM tales.stories s 
    WHERE s.user_id = up.id
) BETWEEN 1 AND 9;

-- Verify the results
SELECT 
    'Total Users' as metric,
    COUNT(*) as count
FROM tales.user_profiles
UNION ALL
SELECT 
    subscription_plan as metric,
    COUNT(*) as count
FROM tales.user_profiles
GROUP BY subscription_plan
ORDER BY count DESC;

-- View all users with their subscription details
SELECT 
    up.id,
    up.name,
    u.email,
    up.subscription_plan,
    up.subscription_status,
    up.subscription_start_date,
    up.monthly_story_count,
    up.last_reset_date
FROM tales.user_profiles up
JOIN auth.users u ON up.id = u.id
ORDER BY up.created_at DESC;