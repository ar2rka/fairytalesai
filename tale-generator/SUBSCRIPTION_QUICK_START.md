# Subscription System Quick Start Guide

## Overview

The Tale Generator now has a subscription-based tariff plan system with 4 tiers: Free, Starter, Normal, and Premium.

## Quick Setup

### 1. Apply Database Migration

```bash
# Connect to your Supabase database and run:
psql -f supabase/migrations/018_add_subscription_system.sql
```

Or via Supabase Dashboard:
1. Go to SQL Editor
2. Copy contents of `supabase/migrations/018_add_subscription_system.sql`
3. Execute

### 2. Verify Migration

All existing users will be assigned the 'free' plan automatically.

```sql
-- Check user subscriptions
SELECT id, subscription_plan, subscription_status, monthly_story_count
FROM tales.user_profiles
LIMIT 10;
```

### 3. Start the API

```bash
uvicorn main:create_app --reload
```

## Plan Comparison

| Feature | Free | Starter | Normal | Premium |
|---------|------|---------|--------|---------|
| **Monthly Stories** | 5 | 25 | 100 | Unlimited |
| **Child Profiles** | 2 | 5 | 10 | Unlimited |
| **Max Story Length** | 5 min | 15 min | 30 min | 30 min |
| **Audio Generation** | ❌ | ✅ | ✅ | ✅ |
| **Hero Stories** | ❌ | ✅ | ✅ | ✅ |
| **Combined Stories** | ❌ | ✅ | ✅ | ✅ |
| **Support** | Community | Email | Email+ | Priority |

## Common Tasks

### Check User's Current Plan

```python
from src.supabase_client import SupabaseClient

client = SupabaseClient()
subscription = client.get_user_subscription(user_id)

print(f"Plan: {subscription.plan.value}")
print(f"Stories used: {subscription.monthly_story_count}")
```

### Manually Change User's Plan

```sql
UPDATE tales.user_profiles
SET subscription_plan = 'premium',
    subscription_status = 'active'
WHERE id = 'user-uuid';
```

### Check Usage for Current Month

```sql
SELECT 
    user_id,
    subscription_plan,
    monthly_story_count,
    last_reset_date
FROM tales.user_profiles
WHERE user_id = 'user-uuid';
```

### View Usage History

```sql
SELECT 
    action_type,
    action_timestamp,
    metadata->>'plan' as plan_at_time,
    metadata->>'story_type' as story_type
FROM tales.usage_tracking
WHERE user_id = 'user-uuid'
ORDER BY action_timestamp DESC
LIMIT 50;
```

## API Endpoints

### Get Subscription Info

```bash
curl -X GET "http://localhost:8000/api/v1/users/subscription" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

Response:
```json
{
  "subscription": {
    "plan": "free",
    "status": "active",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": null
  },
  "limits": {
    "monthly_stories": 5,
    "stories_used": 3,
    "stories_remaining": 2,
    "reset_date": "2025-01-01T00:00:00Z",
    "child_profiles_limit": 2,
    "child_profiles_count": 1,
    "audio_enabled": false,
    "hero_stories_enabled": false,
    "max_story_length": 5
  },
  "features": {
    "audio_generation": false,
    "hero_stories": false,
    "combined_stories": false,
    "priority_support": false
  }
}
```

### Generate Story (with validation)

```bash
curl -X POST "http://localhost:8000/api/v1/stories/generate" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "en",
    "child_id": "child-uuid",
    "story_type": "child",
    "story_length": 5,
    "generate_audio": false
  }'
```

### Create Child Profile (with validation)

```bash
curl -X POST "http://localhost:8000/api/v1/children" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Emma",
    "age": 7,
    "gender": "female",
    "interests": ["art", "music"]
  }'
```

## Error Responses

### Monthly Limit Exceeded

```json
{
  "detail": "Monthly story limit exceeded. You have used 5/5 stories...",
  "error_code": "MONTHLY_LIMIT_EXCEEDED",
  "limit_info": {
    "current_plan": "free",
    "monthly_limit": 5,
    "stories_used": 5,
    "reset_date": "2025-01-01T00:00:00Z"
  }
}
```

### Child Limit Exceeded

```json
{
  "detail": "Child profile limit exceeded for your free plan...",
  "error_code": "CHILD_LIMIT_EXCEEDED",
  "limit_info": {
    "current_plan": "free",
    "child_limit": 2,
    "children_count": 2
  }
}
```

### Feature Not Allowed

```json
{
  "detail": "Audio generation is not available in your free plan...",
  "error_code": "AUDIO_NOT_ALLOWED",
  "current_plan": "free"
}
```

## Frontend Integration

### Add Subscription Page Route

In your `App.tsx` or router configuration:

```typescript
import { SubscriptionPage } from './pages/subscription/SubscriptionPage';

// Add route
<Route path="/subscription" element={<SubscriptionPage />} />
```

### Display Subscription Badge in Navbar

```typescript
import { SubscriptionBadge } from './components/subscription/SubscriptionBadge';

// In navbar
<SubscriptionBadge plan={userPlan} />
```

### Show Usage Limits on Dashboard

```typescript
import { UsageLimitCard } from './components/subscription/UsageLimitCard';

<UsageLimitCard
  title="Monthly Stories"
  used={storiesUsed}
  limit={monthlyLimit}
  unit="stories"
  icon="📚"
/>
```

## Testing

### Run Test Suite

```bash
python3 test_subscription_system.py
```

Expected output:
```
TEST: Plan Registry
✅ Plan registry tests passed!

TEST: Subscription Service
✅ Subscription service tests passed!

TEST: Monthly Reset Logic
✅ Monthly reset logic tests passed!

✅ ALL TESTS PASSED!
```

## Troubleshooting

### Migration Fails

**Issue:** Column already exists
**Solution:** Migration uses `IF NOT EXISTS`, safe to re-run

### Users Not Getting Default Plan

**Issue:** New users have no subscription_plan
**Solution:** Check trigger on user creation, or manually set:

```sql
UPDATE tales.user_profiles
SET subscription_plan = 'free',
    subscription_status = 'active',
    subscription_start_date = NOW()
WHERE subscription_plan IS NULL;
```

### Monthly Counter Not Resetting

**Issue:** Counter stays high in new month
**Solution:** Function resets on first request. Or manually:

```sql
SELECT check_and_reset_monthly_counter('user-uuid');
```

### API Returns 500 on Subscription Check

**Issue:** Missing user_profiles record
**Solution:** Ensure user has profile created:

```sql
INSERT INTO tales.user_profiles (id, name, subscription_plan)
VALUES ('user-uuid', 'User Name', 'free')
ON CONFLICT (id) DO NOTHING;
```

## Admin Tasks

### Grant Premium to User

```sql
UPDATE tales.user_profiles
SET subscription_plan = 'premium',
    subscription_status = 'active',
    subscription_start_date = NOW()
WHERE id = 'user-uuid';
```

### Reset User's Monthly Counter

```sql
UPDATE tales.user_profiles
SET monthly_story_count = 0,
    last_reset_date = NOW()
WHERE id = 'user-uuid';
```

### View High Usage Users

```sql
SELECT 
    id,
    subscription_plan,
    monthly_story_count,
    (SELECT COUNT(*) FROM tales.children WHERE user_id = up.id) as child_count
FROM tales.user_profiles up
ORDER BY monthly_story_count DESC
LIMIT 20;
```

### Export Usage Analytics

```sql
SELECT 
    subscription_plan,
    COUNT(*) as user_count,
    AVG(monthly_story_count) as avg_stories,
    SUM(monthly_story_count) as total_stories
FROM tales.user_profiles
GROUP BY subscription_plan;
```

## Next Steps

1. ✅ Deploy database migration
2. ✅ Test API endpoints
3. ✅ Add frontend components
4. 📋 Configure email notifications (future)
5. 📋 Integrate payment provider (future)
6. 📋 Add plan upgrade UI (future)

## Support

For issues or questions:
- Check: `SUBSCRIPTION_SYSTEM_IMPLEMENTATION.md`
- Review: `.qoder/quests/tariff-plan-limits.md`
- Test: `python3 test_subscription_system.py`
