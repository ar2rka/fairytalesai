# Supabase Setup

This directory contains the SQL migrations for setting up the Supabase database for the Tale Generator API.

## Prerequisites

1. Create a Supabase account at [supabase.com](https://supabase.com/)
2. Create a new project
3. Get your project URL and anon key from the project settings

## Database Setup

### Option 1: Manual Setup via Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Run the migrations in order:
   - [001_create_stories_table.sql](migrations/001_create_stories_table.sql)
   - [002_add_model_info_to_stories.sql](migrations/002_add_model_info_to_stories.sql)
   - [004_add_language_to_stories.sql](migrations/004_add_language_to_stories.sql)
   - [005_create_children_table.sql](migrations/005_create_children_table.sql)
   - [006_add_rating_to_stories.sql](migrations/006_add_rating_to_stories.sql)
   - [007_add_generation_info_to_stories.sql](migrations/007_add_generation_info_to_stories.sql)
   - [008_add_audio_provider_tracking.sql](migrations/008_add_audio_provider_tracking.sql)
   - [009_add_audio_file_url_to_stories.sql](migrations/009_add_audio_file_url_to_stories.sql)
   - [010_add_story_length_to_stories.sql](migrations/010_add_story_length_to_stories.sql)

### Option 2: Using Supabase CLI (Recommended)

1. Install the Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Link your project:
   ```bash
   supabase link --project-ref your-project-ref
   ```

3. Apply migrations:
   ```bash
   supabase db push
   ```

## Table Structure

### Children Table

The `children` table has the following columns:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Unique identifier |
| name | TEXT | Child's name |
| age | INTEGER | Child's age |
| gender | TEXT | Child's gender |
| interests | TEXT[] | Child's interests (array) |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

### Stories Table

The `stories` table has the following columns:

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Unique identifier |
| title | TEXT | Story title |
| content | TEXT | Story content |
| moral | TEXT | The moral value of the story |
| child_id | UUID | Reference to the child profile (foreign key) |
| child_name | TEXT | Child's name (denormalized for easier queries) |
| child_age | INTEGER | Child's age (denormalized for easier queries) |
| child_gender | TEXT | Child's gender (denormalized for easier queries) |
| child_interests | TEXT[] | Child's interests (array, denormalized for easier queries) |
| model_used | TEXT | AI model used for generation |
| full_response | JSONB | Full LLM response |
| language | TEXT | Language of the story (default: 'en') |
| rating | INTEGER | Story rating (1-10) |
| story_length | INTEGER | Requested length of the story in minutes |
| audio_file_url | TEXT | URL of the generated audio file stored in Supabase storage |
| audio_provider | TEXT | Voice provider used for audio generation (e.g., elevenlabs, google, azure) |
| audio_generation_metadata | JSONB | Provider-specific metadata from audio generation including settings, voice IDs, and generation details |
| created_at | TIMESTAMP | Creation timestamp |
| updated_at | TIMESTAMP | Last update timestamp |

## Indexes

The following indexes are created for better query performance:

### Children Table Indexes
- `idx_children_name` on `name`
- `idx_children_age` on `age`
- `idx_children_gender` on `gender`

### Stories Table Indexes
- `idx_stories_child_name` on `child_name`
- `idx_stories_child_id` on `child_id`
- `idx_stories_created_at` on `created_at`
- `idx_stories_moral` on `moral`
- `idx_stories_model_used` on `model_used`
- `idx_stories_language` on `language`
- `idx_stories_rating` on `rating`
- `idx_stories_story_length` on `story_length`
- `idx_stories_audio_provider` on `audio_provider`
- `idx_stories_audio_file_url` on `audio_file_url`

## Row Level Security

Row Level Security (RLS) is enabled on both the `stories` and `children` tables with permissive policies that allow:
- Read access for all users
- Insert access for all users
- Update access for all users
- Delete access for all users

Note: You may need to adjust these policies based on your security requirements.