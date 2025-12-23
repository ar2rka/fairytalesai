# Automatic Subscription Creation on User Registration

## Overview

When a new user registers in the tale-generator application, the system must automatically create a subscription record with default settings. This ensures every user has an active free-tier subscription from the moment of account creation, enabling immediate access to platform features within free plan limits.

## Background

Currently, the system has:
- User authentication via Supabase Auth
- User profiles stored in `tales.user_profiles` table
- Subscription fields added to user_profiles table (migration 018)
- Frontend registration flow that manually creates user profiles
- Default subscription plan set to 'free' at database level

The current registration process creates user profiles manually in the frontend (AuthContext.tsx), but subscription fields rely on database defaults. This approach has limitations and lacks explicit subscription initialization logic.

## Objectives

- Ensure every new user receives an active subscription automatically
- Initialize subscription with proper default values (free plan)
- Set appropriate monthly usage counters and reset dates
- Maintain consistency between frontend and backend registration flows
- Provide a foundation for future subscription management features

## Strategic Approach

### Database-Level Automation

Implement automatic subscription creation using PostgreSQL database trigger that fires when a new user profile is created. This ensures subscription initialization regardless of the entry point (frontend signup, backend API, admin creation, etc.).

### Rationale

**Why database trigger over application-level logic:**
- Guarantees execution for all registration paths
- Eliminates risk of frontend/backend inconsistency
- Simplifies application code
- Provides single source of truth
- Ensures data integrity at the lowest level

**Benefits:**
- Zero-touch subscription setup
- Consistent behavior across all clients
- Reduced code duplication
- Easier testing and maintenance

## Design Specification

### Database Migration

Create a new migration file to implement automatic subscription initialization.

**Migration file:** `supabase/migrations/019_auto_create_subscription.sql`

**Components:**

#### Trigger Function

Create a PostgreSQL function that initializes subscription fields when a user profile is inserted.

**Function name:** `initialize_user_subscription()`

**Trigger behavior:**
- Executes BEFORE INSERT on `tales.user_profiles`
- Sets subscription fields if they are NULL
- Does not override explicitly provided values
- Returns the modified NEW record

**Field initialization logic:**

| Field | Default Value | Description |
|-------|---------------|-------------|
| subscription_plan | 'free' | Default plan tier for new users |
| subscription_status | 'active' | Subscription is immediately active |
| subscription_start_date | NOW() | Subscription begins at registration time |
| subscription_end_date | NULL | Free plan has no expiration date |
| monthly_story_count | 0 | User starts with zero stories generated |
| last_reset_date | NOW() | Initialize monthly reset tracking |

**Conditional logic:**
- Only set values if the corresponding field is NULL
- Preserve any explicitly provided values (supports future flexibility)

#### Database Trigger

Create a trigger that invokes the initialization function.

**Trigger name:** `trigger_initialize_user_subscription`

**Configuration:**
- Event: BEFORE INSERT
- Target table: `tales.user_profiles`
- Timing: FOR EACH ROW
- Function: `initialize_user_subscription()`

### Frontend Simplification

Modify the frontend registration flow to remove manual subscription field initialization, relying entirely on the database trigger.

**File to modify:** `frontend/src/contexts/AuthContext.tsx`

**Changes in `signUp` function:**

**Current behavior:**
- Creates user via Supabase Auth
- Manually inserts user_profiles record with name only
- No subscription fields specified

**Updated behavior:**
- Creates user via Supabase Auth
- Inserts user_profiles record with name only
- Database trigger automatically initializes subscription fields
- No application code changes needed for subscription logic

**Code structure:**

The user profile insert operation should specify only:
- id (user identifier from auth.users)
- name (from registration form)
- created_at (current timestamp)
- updated_at (current timestamp)

All subscription-related fields will be populated automatically by the trigger.

### Backend Consistency

Ensure backend processes that create user profiles are compatible with the trigger-based approach.

**Current state:**
- No backend registration endpoint exists
- User creation happens through Supabase Auth directly

**Future considerations:**
If backend registration endpoints are added, they should:
- Insert user_profiles records without subscription fields
- Trust the database trigger for initialization
- Follow the same pattern as frontend

## Data Model

### user_profiles Table Structure

Existing schema with subscription fields (from migration 018):

| Column | Type | Constraints | Purpose |
|--------|------|-------------|---------|
| id | UUID | PRIMARY KEY, references auth.users(id) | User identifier |
| name | TEXT | NOT NULL | User display name |
| created_at | TIMESTAMPTZ | DEFAULT NOW(), NOT NULL | Profile creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW(), NOT NULL | Last profile update timestamp |
| subscription_plan | TEXT | NOT NULL, DEFAULT 'free', CHECK constraint | Plan tier: free, starter, normal, premium |
| subscription_status | TEXT | NOT NULL, DEFAULT 'active', CHECK constraint | Status: active, inactive, cancelled, expired |
| subscription_start_date | TIMESTAMPTZ | DEFAULT NOW() | When subscription began |
| subscription_end_date | TIMESTAMPTZ | nullable | When subscription expires (NULL for free plan) |
| monthly_story_count | INTEGER | NOT NULL, DEFAULT 0 | Stories generated in current month |
| last_reset_date | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last monthly counter reset |

**No schema changes required** - migration builds upon existing structure.

## Subscription Plan Defaults

### Free Plan Specifications

New users automatically receive the free plan with these limits:

| Limit Type | Value | Enforcement |
|------------|-------|-------------|
| Monthly Stories | 5 | Hard limit, enforced by SubscriptionService |
| Child Profiles | 2 | Hard limit, enforced by SubscriptionService |
| Max Story Length | 5 minutes | Validation at story generation time |
| Audio Generation | Disabled | Feature flag check |
| Hero Stories | Disabled | Feature flag check |
| Combined Stories | Disabled | Feature flag check |
| Priority Support | Disabled | Feature flag |

**Enforcement location:** `src/domain/services/subscription_service.py` (PlanRegistry)

## Integration Points

### Registration Flow

```
User submits registration form
    ↓
Frontend: AuthContext.signUp(email, password, name)
    ↓
Supabase Auth: Create user in auth.users
    ↓
Frontend: Insert record into tales.user_profiles (id, name, timestamps)
    ↓
Database: BEFORE INSERT trigger fires
    ↓
Database: initialize_user_subscription() function executes
    ↓
Database: Sets subscription_plan, subscription_status, counts, dates
    ↓
Database: INSERT completes with full subscription data
    ↓
User: Has active free subscription immediately
```

### Validation Flow

After registration, when user attempts to generate a story:

```
User requests story generation
    ↓
Backend: Validates authentication (auth.py)
    ↓
Backend: Fetches user subscription from user_profiles
    ↓
Backend: SubscriptionService validates request
    ↓
Backend: Checks monthly_story_count against plan limit (5 for free)
    ↓
Backend: Checks story_type, audio_enabled, story_length
    ↓
If valid: Process story generation, increment monthly_story_count
If invalid: Return error with upgrade suggestion
```

## Migration Strategy

### Deployment Steps

1. **Apply database migration**
   - Run migration 019 in Supabase dashboard or via CLI
   - Creates trigger function and trigger
   - Does not affect existing users

2. **Verify trigger installation**
   - Confirm function exists in database
   - Confirm trigger is attached to user_profiles table
   - Check trigger is set to BEFORE INSERT

3. **Test registration flow**
   - Register a new test user via frontend
   - Query user_profiles table for the new user
   - Verify all subscription fields are populated
   - Confirm values match expected defaults

4. **Monitor existing users**
   - Existing users already have subscription data (from migration 018 backfill)
   - No changes to existing records
   - Trigger only affects new registrations

5. **Deploy frontend changes (optional)**
   - Frontend already compatible with trigger approach
   - No code changes strictly required
   - Can optionally remove redundant field specifications

### Rollback Plan

If issues arise:

1. **Disable trigger**
   - Drop trigger: `DROP TRIGGER IF EXISTS trigger_initialize_user_subscription ON tales.user_profiles`
   - Leaves function intact for potential reactivation

2. **Revert to defaults**
   - Database column defaults still present
   - System falls back to column-level DEFAULT values
   - Basic functionality maintained

3. **Full rollback**
   - Drop function: `DROP FUNCTION IF EXISTS initialize_user_subscription()`
   - Remove migration from migration history
   - Return to pre-migration state

## Testing Strategy

### Unit Testing

**Database function test:**
- Insert user_profiles record with minimal fields (id, name)
- Verify all subscription fields are populated
- Confirm default values are correct
- Test that explicit values are not overridden

**Test query:**
```sql
-- Insert test user profile
INSERT INTO tales.user_profiles (id, name)
VALUES ('test-uuid-123', 'Test User')
RETURNING *;

-- Verify subscription fields
-- Expected: subscription_plan='free', subscription_status='active', monthly_story_count=0
```

### Integration Testing

**Frontend registration test:**
- Complete registration form with valid data
- Submit registration
- Check user_profiles table for new record
- Verify subscription fields are initialized
- Confirm user can access dashboard
- Attempt story generation (should succeed within limits)

**Backend validation test:**
- Use test user credentials
- Call story generation API
- Verify subscription validation executes
- Confirm monthly_story_count increments
- Test limit enforcement (generate 5 stories, attempt 6th)

### Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Profile created with explicit subscription_plan | Trigger preserves provided value, does not override |
| Profile created with NULL subscription_status | Trigger sets status to 'active' |
| Concurrent registrations | Each trigger execution is isolated, no conflicts |
| Database constraint violation | Trigger does not mask constraint errors |
| Profile update (not insert) | Trigger does not fire, no subscription changes |

## Success Criteria

The implementation is successful when:

1. **Automatic initialization:** Every new user registration results in a fully initialized subscription record without manual intervention

2. **Correct defaults:** New users receive free plan with status 'active', counts at 0, and proper timestamps

3. **Immediate functionality:** Users can generate stories immediately after registration within free plan limits

4. **Data consistency:** No user profiles exist with NULL or invalid subscription fields after registration

5. **System simplicity:** Application code does not need to manage subscription initialization logic

6. **Backward compatibility:** Existing users retain their subscription data, no disruption to current functionality

## Future Considerations

### Subscription Management Features

This design provides foundation for:

- **Plan upgrades:** Modify subscription_plan and adjust limits
- **Trial periods:** Set subscription_end_date for trial expiration
- **Subscription expiration:** Automated status changes when end_date is reached
- **Usage analytics:** Track usage patterns via usage_tracking table
- **Payment integration:** Link payment events to subscription status changes

### Potential Enhancements

- **Welcome email trigger:** Send onboarding email when subscription is created
- **Analytics event:** Log subscription creation events for metrics
- **Admin notifications:** Alert admins when new users register
- **Custom welcome offers:** Provide time-limited bonuses for new users
- **Referral tracking:** Initialize referral credits in subscription metadata

### Scalability Notes

- Database trigger adds minimal overhead (simple field assignments)
- No additional database queries required
- Trigger executes within same transaction as profile insert
- Performance impact negligible even at high registration volume

## Dependencies

### Required Components

- Supabase database with tales schema
- Existing user_profiles table (migration 012)
- Existing subscription fields (migration 018)
- PostgreSQL trigger support (built-in)

### No External Dependencies

- No third-party services required
- No API calls needed
- No additional infrastructure

## Security Considerations

### Row Level Security

The trigger operates at database level, before RLS policies apply. This is appropriate because:

- Trigger runs in database security context
- INSERT operation already validated by RLS policy "Users can insert their own profile"
- Trigger only modifies NEW record, does not access other users' data

### Data Privacy

- Trigger does not log or expose user data
- All operations are internal to the database
- No external calls or data leakage

### Validation

- Existing CHECK constraints ensure plan and status values are valid
- Trigger respects all table constraints
- Invalid data cannot be inserted even via trigger

## Monitoring and Observability

### Health Checks

Monitor subscription creation success:

**Query: Count users without subscriptions**
```sql
SELECT COUNT(*) 
FROM tales.user_profiles 
WHERE subscription_plan IS NULL 
   OR subscription_status IS NULL;
```
Expected result: 0

**Query: Recent registrations with subscription data**
```sql
SELECT id, name, subscription_plan, subscription_status, created_at
FROM tales.user_profiles
WHERE created_at > NOW() - INTERVAL '1 day'
ORDER BY created_at DESC;
```
Expected: All recent users have free plan and active status

### Error Scenarios

If trigger fails:
- Database will reject INSERT operation
- Frontend receives error from Supabase
- User sees registration error message
- No partial user records created (transaction rollback)

### Alerting

Set up alerts for:
- Registration failures (track error rates)
- Users with missing subscription data
- Unusual subscription patterns (mass registrations)
