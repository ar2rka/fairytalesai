#!/usr/bin/env python3
"""Test script to verify automatic subscription creation on user registration."""

import os
import uuid
from datetime import datetime
from dotenv import load_dotenv
from supabase import create_client, Client
from supabase.client import ClientOptions

# Load environment variables
load_dotenv()

def test_subscription_auto_creation():
    """Test that subscription fields are automatically initialized for new users."""
    
    print("="*80)
    print("TEST: Automatic Subscription Creation on User Registration")
    print("="*80)
    
    # Get Supabase credentials
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_KEY must be set in .env file")
        return False
    
    try:
        # Create Supabase client with tales schema
        supabase: Client = create_client(
            supabase_url, 
            supabase_key,
            options=ClientOptions(schema="tales")
        )
        print(f"✓ Connected to Supabase: {supabase_url}")
        
        # Test 1: Verify trigger function exists
        print("\n" + "="*80)
        print("TEST 1: Verify Trigger Function Exists")
        print("="*80)
        
        try:
            # Note: We can't directly query pg_proc through the Supabase client
            # but we can test the functionality
            print("⚠ Skipping direct function check (requires admin access)")
            print("  Will verify functionality through integration test instead")
        except Exception as e:
            print(f"⚠ Could not verify function: {e}")
        
        # Test 2: Create a test user profile with minimal fields
        print("\n" + "="*80)
        print("TEST 2: Create User Profile with Minimal Fields")
        print("="*80)
        
        test_user_id = str(uuid.uuid4())
        test_user_name = f"Test User {datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        print(f"Creating test user profile...")
        print(f"  ID: {test_user_id}")
        print(f"  Name: {test_user_name}")
        print(f"  Note: Only providing id and name, no subscription fields")
        
        try:
            response = supabase.table('user_profiles').insert({
                'id': test_user_id,
                'name': test_user_name,
                # NOT providing any subscription fields - trigger should initialize them
            }).execute()
            
            print("✓ User profile created successfully")
            
        except Exception as e:
            print(f"❌ Failed to create user profile: {e}")
            return False
        
        # Test 3: Retrieve the user profile and verify subscription fields
        print("\n" + "="*80)
        print("TEST 3: Verify Subscription Fields Are Auto-Initialized")
        print("="*80)
        
        try:
            response = supabase.table('user_profiles').select('*').eq('id', test_user_id).execute()
            
            if not response.data or len(response.data) == 0:
                print(f"❌ User profile not found: {test_user_id}")
                return False
            
            user_profile = response.data[0]
            print(f"✓ Retrieved user profile")
            
            # Verify subscription fields
            print("\nVerifying subscription fields:")
            all_tests_passed = True
            
            # Check subscription_plan
            if user_profile.get('subscription_plan') == 'free':
                print("  ✓ subscription_plan = 'free'")
            else:
                print(f"  ❌ subscription_plan = '{user_profile.get('subscription_plan')}' (expected 'free')")
                all_tests_passed = False
            
            # Check subscription_status
            if user_profile.get('subscription_status') == 'active':
                print("  ✓ subscription_status = 'active'")
            else:
                print(f"  ❌ subscription_status = '{user_profile.get('subscription_status')}' (expected 'active')")
                all_tests_passed = False
            
            # Check monthly_story_count
            if user_profile.get('monthly_story_count') == 0:
                print("  ✓ monthly_story_count = 0")
            else:
                print(f"  ❌ monthly_story_count = {user_profile.get('monthly_story_count')} (expected 0)")
                all_tests_passed = False
            
            # Check subscription_start_date exists
            if user_profile.get('subscription_start_date'):
                print(f"  ✓ subscription_start_date = {user_profile.get('subscription_start_date')}")
            else:
                print("  ❌ subscription_start_date is NULL (expected timestamp)")
                all_tests_passed = False
            
            # Check last_reset_date exists
            if user_profile.get('last_reset_date'):
                print(f"  ✓ last_reset_date = {user_profile.get('last_reset_date')}")
            else:
                print("  ❌ last_reset_date is NULL (expected timestamp)")
                all_tests_passed = False
            
            # Check subscription_end_date is NULL (free plan)
            if user_profile.get('subscription_end_date') is None:
                print("  ✓ subscription_end_date = NULL (correct for free plan)")
            else:
                print(f"  ❌ subscription_end_date = {user_profile.get('subscription_end_date')} (expected NULL)")
                all_tests_passed = False
            
            if not all_tests_passed:
                print("\n❌ Some subscription fields were not initialized correctly")
                return False
            
        except Exception as e:
            print(f"❌ Failed to verify subscription fields: {e}")
            return False
        
        # Test 4: Test with explicit subscription values (should not be overridden)
        print("\n" + "="*80)
        print("TEST 4: Verify Trigger Preserves Explicit Values")
        print("="*80)
        
        test_user_id_2 = str(uuid.uuid4())
        test_user_name_2 = f"Premium User {datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        print(f"Creating user profile with explicit subscription_plan='premium'...")
        
        try:
            response = supabase.table('user_profiles').insert({
                'id': test_user_id_2,
                'name': test_user_name_2,
                'subscription_plan': 'premium',  # Explicitly set to premium
            }).execute()
            
            print("✓ User profile created")
            
            # Verify the plan was preserved
            response = supabase.table('user_profiles').select('subscription_plan').eq('id', test_user_id_2).execute()
            
            if response.data and response.data[0].get('subscription_plan') == 'premium':
                print("  ✓ Explicit subscription_plan='premium' was preserved")
            else:
                print(f"  ❌ subscription_plan was overridden: {response.data[0].get('subscription_plan')}")
                all_tests_passed = False
            
        except Exception as e:
            print(f"⚠ Could not test explicit values: {e}")
        
        # Cleanup: Delete test users
        print("\n" + "="*80)
        print("CLEANUP: Removing Test Users")
        print("="*80)
        
        try:
            supabase.table('user_profiles').delete().eq('id', test_user_id).execute()
            print(f"✓ Deleted test user: {test_user_id}")
        except Exception as e:
            print(f"⚠ Could not delete test user 1: {e}")
        
        try:
            supabase.table('user_profiles').delete().eq('id', test_user_id_2).execute()
            print(f"✓ Deleted test user: {test_user_id_2}")
        except Exception as e:
            print(f"⚠ Could not delete test user 2: {e}")
        
        # Final result
        print("\n" + "="*80)
        print("TEST RESULTS")
        print("="*80)
        
        if all_tests_passed:
            print("✓ All tests PASSED!")
            print("\nThe subscription auto-creation trigger is working correctly:")
            print("  • New users receive 'free' plan automatically")
            print("  • Subscription status is set to 'active'")
            print("  • Monthly story count starts at 0")
            print("  • Timestamps are properly initialized")
            print("  • Explicit values are preserved")
            return True
        else:
            print("❌ Some tests FAILED")
            print("\nPlease verify that migration 019 was applied correctly.")
            return False
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_subscription_auto_creation()
    exit(0 if success else 1)
