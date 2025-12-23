#!/usr/bin/env python3
"""Script to apply the automatic subscription creation migration."""

import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def apply_subscription_trigger_migration():
    """Apply the subscription trigger migration."""
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
        migration_file = "supabase/migrations/019_auto_create_subscription.sql"
        with open(migration_file, "r") as f:
            migration_sql = f.read()
        
        print("="*80)
        print("MIGRATION 019: Automatic Subscription Creation on User Registration")
        print("="*80)
        print("\nThis migration will:")
        print("  1. Create a trigger function: initialize_user_subscription()")
        print("  2. Create a BEFORE INSERT trigger on tales.user_profiles")
        print("  3. Automatically set subscription defaults for new users")
        print("\nMigration SQL:")
        print("-"*80)
        print(migration_sql)
        print("-"*80)
        
        print("\n" + "="*80)
        print("TO APPLY THIS MIGRATION:")
        print("="*80)
        print("\n** OPTION 1: Via Supabase Dashboard **")
        print("  1. Go to your Supabase project dashboard")
        print("  2. Navigate to: SQL Editor")
        print("  3. Copy and paste the migration SQL above")
        print("  4. Click 'RUN' to execute")
        
        print("\n** OPTION 2: Via Supabase CLI **")
        print("  Run: supabase db push")
        print("  Or:  psql -h <host> -U postgres -d postgres -f supabase/migrations/019_auto_create_subscription.sql")
        
        print("\n" + "="*80)
        print("VERIFICATION AFTER APPLYING:")
        print("="*80)
        print("\nRun these queries to verify the trigger is installed:")
        print("\n-- Check function exists:")
        print("SELECT proname FROM pg_proc WHERE proname = 'initialize_user_subscription';")
        print("\n-- Check trigger exists:")
        print("SELECT tgname FROM pg_trigger WHERE tgname = 'trigger_initialize_user_subscription';")
        print("\n-- Test the trigger (creates a test user profile):")
        print("INSERT INTO tales.user_profiles (id, name)")
        print("VALUES (gen_random_uuid(), 'Test User')")
        print("RETURNING *;")
        print("\n-- Verify subscription fields are populated:")
        print("-- Expected: subscription_plan='free', subscription_status='active', monthly_story_count=0")
        
    except FileNotFoundError:
        print(f"Error: Migration file not found: {migration_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    apply_subscription_trigger_migration()
