"""Script to apply the children table migration."""

import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def apply_migration():
    """Apply the children table migration."""
    try:
        # Get Supabase credentials
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_KEY")
        
        if not supabase_url or not supabase_key:
            print("Error: SUPABASE_URL and SUPABASE_KEY must be set in .env file")
            return
        
        # Create Supabase client
        supabase = create_client(supabase_url, supabase_key)
        
        # Read the migration file
        with open("supabase/migrations/005_create_children_table.sql", "r") as f:
            migration_sql = f.read()
        
        print("Applying children table migration...")
        print("Migration SQL:")
        print(migration_sql)
        
        # Execute the migration
        # Note: Supabase Python client doesn't directly support executing raw SQL
        # We'll need to use the REST API or suggest manual execution
        
        print("\nTo apply this migration manually:")
        print("1. Go to your Supabase project dashboard")
        print("2. Navigate to the SQL Editor")
        print("3. Copy and paste the above SQL into the editor")
        print("4. Run the query")
        
    except Exception as e:
        print(f"Error applying migration: {e}")

if __name__ == "__main__":
    apply_migration()