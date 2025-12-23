"""Script to apply the rating column migration."""

import os
import sys
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def apply_rating_migration():
    """Apply the rating column migration."""
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
        migration_file = "supabase/migrations/006_add_rating_to_stories.sql"
        if len(sys.argv) > 1:
            migration_file = sys.argv[1]
            
        with open(migration_file, "r") as f:
            migration_sql = f.read()
        
        print(f"Applying rating column migration from {migration_file}...")
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
    apply_rating_migration()