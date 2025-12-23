#!/usr/bin/env python3
"""Script to test if authentication migration has been applied."""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

def test_auth_migration():
    """Test if authentication migration has been applied."""
    # Load environment variables
    load_dotenv()
    
    # Get Supabase credentials from environment
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("Supabase credentials not found in environment variables")
        return
    
    try:
        # Create Supabase client with tales schema
        from supabase.client import ClientOptions
        supabase: Client = create_client(
            supabase_url, 
            supabase_key,
            options=ClientOptions(
                schema="tales"
            )
        )
        print(f"Connected to Supabase: {supabase_url}")
        
        # Try to access user_profiles table
        try:
            response = supabase.table('user_profiles').select('*').execute()
            print(f"Found {len(response.data)} user profiles")
            
            for profile in response.data[:3]:  # Show first 3 profiles
                print(f"  - ID: {profile.get('id')}, Name: {profile.get('name')}")
                
        except Exception as e:
            print(f"Error accessing user_profiles table: {e}")
        
        # Check if children table has user_id column
        try:
            response = supabase.table('children').select('id, name, user_id').limit(3).execute()
            print(f"Children table accessible with user_id column")
            for child in response.data:
                print(f"  - Child: {child.get('name')}, User ID: {child.get('user_id', 'NULL')}")
        except Exception as e:
            print(f"Error accessing children table: {e}")
            
        # Check if stories table has user_id column
        try:
            response = supabase.table('stories').select('id, title, user_id').limit(3).execute()
            print(f"Stories table accessible with user_id column")
            for story in response.data:
                print(f"  - Story: {story.get('title')[:30]}..., User ID: {story.get('user_id', 'NULL')}")
        except Exception as e:
            print(f"Error accessing stories table: {e}")
            
    except Exception as e:
        print(f"Error connecting to Supabase: {e}")

if __name__ == "__main__":
    test_auth_migration()