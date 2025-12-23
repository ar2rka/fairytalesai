#!/usr/bin/env python3
"""Script to check user profiles in the database."""

from src.supabase_client import SupabaseClient

def check_user_profiles():
    """Check if user profiles are being populated during registration."""
    try:
        client = SupabaseClient()
        response = client.client.table('user_profiles').select('*').execute()
        print(f"Found {len(response.data)} user profiles")
        
        for profile in response.data[:5]:  # Show first 5 profiles
            print(f"Profile: {profile}")
            
        if not response.data:
            print("No user profiles found in the database")
            
    except Exception as e:
        print(f"Error checking user profiles: {e}")

if __name__ == "__main__":
    check_user_profiles()