# Quick Start: Automatic Subscription Creation

## What This Does

When a user registers, they automatically get a free subscription with:
- ✅ Free plan tier
- ✅ Active status
- ✅ 5 stories per month limit
- ✅ 2 child profiles limit
- ✅ Ready to use immediately

## 3-Step Deployment

### Step 1: Apply Migration

Run the helper script to see the SQL:
```bash
uv run python apply_subscription_trigger_migration.py
```

Then apply via **Supabase Dashboard**:
1. Go to SQL Editor
2. Copy the SQL from the script output
3. Click "RUN"

**✅ Done!** The trigger is now installed.

### Step 2: Verify

Run the test script:
```bash
uv run python test_subscription_auto_creation.py
```

**Expected output:**
```
✓ All tests PASSED!

The subscription auto-creation trigger is working correctly:
  • New users receive 'free' plan automatically
  • Subscription status is set to 'active'
  • Monthly story count starts at 0
  • Timestamps are properly initialized
  • Explicit values are preserved
```

### Step 3: Test Registration

Register a new user via frontend:
```
http://localhost:5173/register
```

Then check the database:
```sql
SELECT id, name, subscription_plan, subscription_status, monthly_story_count
FROM tales.user_profiles
ORDER BY created_at DESC
LIMIT 1;
```

**Expected result:**
- `subscription_plan` = `free`
- `subscription_status` = `active`
- `monthly_story_count` = `0`

## That's It! 🎉

New users now get subscriptions automatically. No code changes needed in your app!

## How It Works

```
User registers → Profile created → Trigger fires → Subscription initialized
```

The database trigger runs automatically before inserting the user profile and sets all subscription defaults.

## Rollback (If Needed)

To disable the trigger:
```sql
DROP TRIGGER IF EXISTS trigger_initialize_user_subscription ON tales.user_profiles;
```

To re-enable, just re-run the migration SQL.

## Need Help?

- **View migration SQL:** `uv run python apply_subscription_trigger_migration.py`
- **Run tests:** `uv run python test_subscription_auto_creation.py`
- **Check docs:** See `SUBSCRIPTION_AUTO_CREATION_SUMMARY.md`
