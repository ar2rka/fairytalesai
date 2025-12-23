# Quick Start: Combined Story Type Feature

## What Was Added

The tale generator now supports **combined stories** that feature both a child and a hero character together in the same narrative, creating mentor-mentee relationships and adventure partnerships.

## Files Created/Modified

### New Files
- `supabase/migrations/011_add_story_type_and_hero_fields.sql` - Database migration
- `apply_combined_story_migration.py` - Migration helper script
- `COMBINED_STORY_IMPLEMENTATION.md` - Detailed implementation documentation

### Modified Files
- `src/models.py` - Added hero fields to StoryDB
- `src/infrastructure/persistence/models.py` - Added hero fields to StoryDB
- `src/supabase_client.py` - Extended field mappings for hero data
- `populate_stories.py` - Added combined story generation support

## How to Use

### Step 1: Apply Database Migration

```bash
# Display migration instructions
python3 apply_combined_story_migration.py
```

Then:
1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy the migration SQL displayed by the script
4. Paste and run it in the SQL Editor

### Step 2: Generate Sample Stories

```bash
# Generate 10 sample stories (includes combined stories)
uv run python populate_stories.py
```

This will generate:
- 4 child stories (child-only narratives)
- 3 hero stories (hero-only narratives)
- 3 combined stories (child + hero together)

## What to Expect

### Combined Stories Include:

1. **Both Characters**:
   - Child with personalized interests
   - Hero with heroic attributes
   - Relationship description (e.g., "Emma meets the legendary Captain Wonder")

2. **Database Fields Populated**:
   - `story_type = "combined"`
   - `child_id`, `child_name`, `child_age`, `child_gender`, `child_interests`
   - `hero_id`, `hero_name`, `hero_gender`, `hero_appearance`
   - `relationship_description`

3. **Language Support**:
   - English and Russian both supported
   - Heroes are filtered by language to match story language
   - Relationship descriptions in appropriate language

### Example Log Output

```
Generating combined story 3/10 for Emma with moral 'kindness' using gpt-4o-mini in en...
Story saved with ID: abc-123-def, Type: combined
1. Emma's Adventure (Type: combined, Moral: kindness, Child: Emma, Hero: Captain Wonder, Model: gpt-4o-mini, Language: en)
```

## Story Type Options

The system now supports three story types:

| Type | Description | Characters |
|------|-------------|------------|
| `child` | Child-only story | Child protagonist |
| `hero` | Hero-only story | Hero protagonist |
| `combined` | Child + Hero story | Both child and hero |

## Verification

After running `populate_stories.py`, check your Supabase dashboard:

1. Go to Table Editor → stories table
2. Look for records with `story_type = 'combined'`
3. Verify these records have:
   - Non-null `hero_id`
   - Non-null `hero_name`, `hero_gender`, `hero_appearance`
   - Non-null `relationship_description`

## Backward Compatibility

✅ Existing child stories continue to work (story_type defaults to 'child')
✅ Existing hero stories work unchanged
✅ No changes required to existing code or workflows
✅ All hero fields are optional (NULL for child-only stories)

## Troubleshooting

### Issue: Migration fails with foreign key error
**Solution**: Ensure heroes table exists and has records before applying migration

### Issue: No combined stories generated
**Solution**: Verify at least one hero exists for each language (en, ru) in heroes table

### Issue: ValueError about no heroes found
**Solution**: 
```bash
# Check heroes in database
uv run python -c "from src.supabase_client import SupabaseClient; print(SupabaseClient().get_all_heroes())"
```

## Next Steps

1. Apply the migration (required before using combined stories)
2. Run populate_stories.py to generate sample combined stories
3. Review generated stories in Supabase dashboard
4. Integrate combined story generation into your application workflow

For detailed implementation information, see `COMBINED_STORY_IMPLEMENTATION.md`.
