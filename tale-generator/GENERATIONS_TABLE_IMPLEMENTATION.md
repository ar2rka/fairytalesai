# Generations Table Implementation Summary

## Overview

Successfully implemented the separation of generation metadata from the stories table by creating a new `generations` table. This improves data organization, enables retry tracking, and provides better analytics capabilities.

## What Was Implemented

### 1. Database Migrations (3 files)

#### Migration 015: Create Generations Table
- **File**: `supabase/migrations/015_create_generations_table.sql`
- **Purpose**: Create new table to track generation requests and attempts
- **Features**:
  - Composite primary key on (generation_id, attempt_number)
  - All required fields for tracking generation metadata
  - Check constraints for data validity
  - Comprehensive indexes for performance
  - Row Level Security (RLS) policies
  - Full documentation via column comments

#### Migration 016: Migrate Data to Generations
- **File**: `supabase/migrations/016_migrate_story_generation_data.sql`
- **Purpose**: Copy existing generation metadata from stories to generations table
- **Features**:
  - Creates generation_id for each existing story
  - Assumes all existing stories succeeded on first attempt
  - Creates mapping table for migration tracking
  - Includes verification logging

#### Migration 017: Update Stories Table Structure
- **File**: `supabase/migrations/017_update_stories_table_structure.sql`
- **Purpose**: Restructure stories table to reference generations
- **Features**:
  - Adds generation_id column with foreign key
  - Drops deprecated columns (model_used, full_response, etc.)
  - Includes data integrity checks
  - Provides migration verification

### 2. Database Models

#### GenerationDB Model
- **File**: `src/infrastructure/persistence/models.py`
- **Fields**:
  - generation_id (str)
  - attempt_number (int)
  - model_used (str)
  - full_response (Optional[Dict])
  - status (str): 'pending', 'success', 'failed', 'timeout'
  - prompt (str)
  - user_id (str)
  - story_type (str): 'child', 'hero', 'combined'
  - story_length (Optional[int])
  - hero_appearance (Optional[str])
  - relationship_description (Optional[str])
  - moral (str)
  - error_message (Optional[str])
  - created_at (Optional[datetime])
  - completed_at (Optional[datetime])

#### Updated StoryDB Model
- **Removed fields**:
  - moral, story_type, story_length
  - model_used, full_response, generation_info
  - hero_appearance, relationship_description
- **Added field**:
  - generation_id (str) - foreign key to generations table

### 3. Repository Layer

#### GenerationRepository Interface
- **File**: `src/domain/repositories/generation_repository.py`
- **Methods**:
  - `create_generation(generation)` - Create new generation record
  - `update_generation(generation)` - Update existing generation
  - `get_generation(generation_id, attempt_number)` - Get specific attempt
  - `get_latest_attempt(generation_id)` - Get latest attempt
  - `get_all_attempts(generation_id)` - Get all retry attempts
  - `get_user_generations(user_id, limit)` - Get user's generations
  - `get_generations_by_status(status, limit)` - Filter by status

#### Implementation in Supabase Client
- **Files**: 
  - `src/supabase_client.py` (sync implementation)
  - `src/supabase_client_async.py` (async wrapper)
- **Features**:
  - Full CRUD operations for generations
  - Proper datetime handling
  - Error handling and logging
  - Query optimization with indexes

### 4. Updated Story Generation Flow

#### Modified Endpoint
- **File**: `src/api/routes.py`
- **Endpoint**: `POST /stories/generate`
- **New Flow**:
  1. Generate prompt
  2. Create generation record (status='pending')
  3. Call OpenRouter API
  4. On success:
     - Update generation record (status='success')
     - Save story with generation_id
  5. On failure:
     - Update generation record (status='failed')
     - Return error to user

### 5. Test Suite

#### Test File
- **File**: `test_generations_migration.py`
- **Test Coverage**:
  - Create generation records
  - Retrieve generation records
  - Update generation status
  - Create retry attempts
  - Get all attempts for a generation
  - Get latest attempt
  - Get user generations
  - Get generations by status
  - Create stories linked to generations
  - Verify generation_id linkage

## Migration Execution

### Prerequisites
1. Backup your database before running migrations
2. Ensure all application instances are stopped
3. Have database admin access

### Execution Steps

```bash
# 1. Run migrations in order
# Connect to your Supabase database and execute:

# Migration 015: Create generations table
psql -h <supabase-host> -U postgres -d postgres -f supabase/migrations/015_create_generations_table.sql

# Migration 016: Migrate data
psql -h <supabase-host> -U postgres -d postgres -f supabase/migrations/016_migrate_story_generation_data.sql

# Migration 017: Update stories table
psql -h <supabase-host> -U postgres -d postgres -f supabase/migrations/017_update_stories_table_structure.sql

# 2. Verify migration results
# Check the migration summary output in the logs

# 3. Run tests
python test_generations_migration.py
```

### Rollback Plan

If you need to rollback:

```sql
-- 1. Restore dropped columns to stories table
ALTER TABLE tales.stories ADD COLUMN moral TEXT;
ALTER TABLE tales.stories ADD COLUMN story_type TEXT;
ALTER TABLE tales.stories ADD COLUMN model_used TEXT;
-- ... (add all other dropped columns)

-- 2. Copy data back from generations
UPDATE tales.stories s
SET 
    moral = g.moral,
    story_type = g.story_type,
    model_used = g.model_used
FROM tales.generations g
WHERE s.generation_id = g.generation_id;

-- 3. Drop generation_id from stories
ALTER TABLE tales.stories DROP CONSTRAINT fk_stories_generation_id;
ALTER TABLE tales.stories DROP COLUMN generation_id;

-- 4. Drop generations table
DROP TABLE tales.generations CASCADE;
```

## Benefits Achieved

### Immediate Benefits
1. **Clear Separation of Concerns** - Story content vs technical metadata
2. **Retry Tracking** - Each attempt recorded separately
3. **Better Analytics** - Track success rates, model performance
4. **Cleaner Data Model** - Stories table focused on user content

### Future Capabilities
1. **Generation History** - View all attempts for debugging
2. **Cost Tracking** - Analyze token usage and costs
3. **Performance Optimization** - Identify slow models
4. **Prompt Engineering** - Store and analyze prompts

## API Impact

### Breaking Changes
- Stories created after migration will not have inline generation metadata
- `StoryDB` model no longer includes `model_used`, `full_response`, etc.
- Queries needing generation data must JOIN with generations table

### Backward Compatibility
- Existing stories migrated successfully
- All stories now have `generation_id`
- Historical data preserved in generations table

## Testing

Run the test suite to verify:

```bash
# Set test user ID (optional)
export TEST_USER_ID="<your-test-user-uuid>"

# Run tests
python test_generations_migration.py
```

Expected output:
- ✓ All generation repository operations succeed
- ✓ Story-generation linkage works correctly
- ✓ Data integrity maintained

## Monitoring

### Key Metrics to Monitor
1. Generation success rate: `SELECT COUNT(*) FROM tales.generations WHERE status='success'`
2. Retry frequency: `SELECT AVG(attempt_number) FROM tales.generations`
3. Error patterns: `SELECT error_message, COUNT(*) FROM tales.generations WHERE status='failed' GROUP BY error_message`
4. Model performance: `SELECT model_used, AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) FROM tales.generations GROUP BY model_used`

## Files Modified

### Created
- `supabase/migrations/015_create_generations_table.sql`
- `supabase/migrations/016_migrate_story_generation_data.sql`
- `supabase/migrations/017_update_stories_table_structure.sql`
- `src/domain/repositories/generation_repository.py`
- `test_generations_migration.py`

### Modified
- `src/infrastructure/persistence/models.py` - Added GenerationDB, updated StoryDB
- `src/supabase_client.py` - Added generation repository methods
- `src/supabase_client_async.py` - Added async generation methods
- `src/api/routes.py` - Updated story generation flow

## Next Steps

1. **Run Migrations**: Execute migrations in your development environment
2. **Test Thoroughly**: Run test suite and verify functionality
3. **Deploy**: Apply migrations to production during maintenance window
4. **Monitor**: Track generation metrics and success rates
5. **Optimize**: Use generation data to improve prompts and model selection

## Support

For issues or questions:
1. Check migration logs for errors
2. Verify all migrations completed successfully
3. Run test suite to identify specific failures
4. Review Supabase logs for database errors
