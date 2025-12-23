"""Script to apply the story_type and hero fields migration."""

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def display_migration_instructions():
    """Display instructions for applying the migration."""
    try:
        # Read the migration file
        with open("supabase/migrations/011_add_story_type_and_hero_fields.sql", "r") as f:
            migration_sql = f.read()
        
        print("=" * 80)
        print("MIGRATION: Add Story Type and Hero Fields to Stories Table")
        print("=" * 80)
        print("\nThis migration adds support for combined stories featuring both")
        print("child and hero characters together in the same narrative.")
        print("\nChanges:")
        print("  - Adds story_type column (child, hero, or combined)")
        print("  - Adds hero_id foreign key reference to heroes table")
        print("  - Adds denormalized hero fields (name, gender, appearance)")
        print("  - Adds relationship_description for combined stories")
        print("  - Creates indexes for query performance")
        print("  - Adds check constraints for data integrity")
        print("\n" + "=" * 80)
        print("MIGRATION SQL:")
        print("=" * 80)
        print(migration_sql)
        print("\n" + "=" * 80)
        print("TO APPLY THIS MIGRATION:")
        print("=" * 80)
        print("1. Go to your Supabase project dashboard")
        print("2. Navigate to the SQL Editor")
        print("3. Copy and paste the above SQL into the editor")
        print("4. Run the query")
        print("\nAfter applying the migration, you can run populate_stories.py")
        print("to generate sample stories including combined story types.")
        print("=" * 80)
        
    except Exception as e:
        print(f"Error reading migration file: {e}")

if __name__ == "__main__":
    display_migration_instructions()
