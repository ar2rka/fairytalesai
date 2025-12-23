# Supabase Migrations for Tale Generator

This directory contains SQL migration files for setting up the Supabase database schema for the tale generator application.

## Migration Files

1. `001_create_heroes_table.sql` - Creates the heroes table structure
2. `002_populate_heroes_table.sql` - Populates the heroes table with predefined heroes
3. `003_add_new_hero_example.sql` - Example of how to add a new hero to the database

## How to Run Migrations

### Method 1: Using the run_migrations.py script

```bash
cd /Users/igorkram/projects/tale-generator
uv run src/run_migrations.py
```

This script will display the SQL commands that need to be executed in your Supabase SQL editor.

### Method 2: Manual execution in Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and execute each migration file in numerical order:
   - First: `001_create_heroes_table.sql`
   - Second: `002_populate_heroes_table.sql`

## Predefined Heroes

The migrations will populate the database with these predefined heroes:

### English Heroes
- **Captain Wonder** - A brave male hero who explores space
- **Starlight** - A wise female hero who glows with light

### Russian Heroes
- **Капитан Чудо** (Captain Wonder) - A brave female hero who travels through space
- **Ледяная Волшебница** (Ice Witch) - A calm female hero who controls ice

## Verifying the Migration

After running the migrations, you can verify the data was inserted correctly by running:

```sql
SELECT * FROM heroes;
```

This should return 4 rows with the predefined heroes.