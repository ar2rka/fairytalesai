#!/usr/bin/env python3
"""Script to apply the prompts RLS fix migration."""

import os
from supabase import create_client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def apply_prompts_rls_fix():
    """Apply the prompts RLS fix migration."""
    try:
        # Get Supabase credentials
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_KEY")
        
        if not supabase_url or not supabase_key:
            print("Error: SUPABASE_URL and SUPABASE_KEY must be set in .env file")
            return
        
        # Read the migration file
        migration_file = "supabase/migrations/031_fix_prompts_rls.sql"
        with open(migration_file, "r") as f:
            migration_sql = f.read()
        
        print("="*80)
        print("MIGRATION 031: Fix RLS Policies for Prompts Table")
        print("="*80)
        print("\nThis migration will:")
        print("  1. Drop existing RLS policy for authenticated users")
        print("  2. Create new policy for public read access (all users)")
        print("  3. Create policy for authenticated users (for consistency)")
        print("\nMigration SQL:")
        print("-"*80)
        print(migration_sql)
        print("-"*80)
        
        print("\n" + "="*80)
        print("TO APPLY THIS MIGRATION:")
        print("="*80)
        print("\n** OPTION 1: Via Supabase Dashboard (Recommended) **")
        print("  1. Go to your Supabase project dashboard")
        print("  2. Navigate to: SQL Editor")
        print("  3. Copy and paste the migration SQL above")
        print("  4. Click 'RUN' to execute")
        print("  5. Verify: You should see 'Success. No rows returned'")
        
        print("\n** OPTION 2: Via Supabase CLI **")
        print("  Run: supabase db push")
        print("  Or:  psql -h <host> -U postgres -d postgres -f supabase/migrations/031_fix_prompts_rls.sql")
        
        print("\n** OPTION 3: Try to apply via Python (requires service_role key) **")
        try:
            # Try to use service_role key if available
            service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
            if service_role_key:
                print("\nAttempting to apply migration using service_role key...")
                supabase = create_client(supabase_url, service_role_key)
                # Execute via RPC or direct SQL
                result = supabase.rpc('exec_sql', {'sql': migration_sql}).execute()
                print("✅ Migration applied successfully!")
            else:
                print("\n⚠️  SUPABASE_SERVICE_ROLE_KEY not found.")
                print("   Using anon key - migration must be applied manually via Dashboard.")
        except Exception as e:
            print(f"\n⚠️  Could not apply automatically: {e}")
            print("   Please apply manually via Supabase Dashboard (Option 1)")
        
        print("\n" + "="*80)
        print("VERIFICATION:")
        print("="*80)
        print("\nAfter applying, verify with this SQL query:")
        print("""
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'tales' AND tablename = 'prompts';
        """)
        print("\nExpected: 2 policies (one for 'public', one for 'authenticated')")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    apply_prompts_rls_fix()

