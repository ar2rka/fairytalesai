#!/usr/bin/env python3
"""Test script to verify authentication implementation."""

import os
import sys
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

print("=" * 70)
print("Authentication Implementation Test")
print("=" * 70)

# Test 1: Import authentication modules
print("\n1. Testing module imports...")
try:
    from src.api.auth import get_current_user, AuthUser, verify_token
    print("   ✓ Authentication module imported successfully")
except Exception as e:
    print(f"   ✗ Failed to import auth module: {e}")
    sys.exit(1)

# Test 2: Import routes module with updated endpoints
print("\n2. Testing routes module...")
try:
    from src.api.routes import router
    print("   ✓ Routes module imported successfully")
except Exception as e:
    print(f"   ✗ Failed to import routes module: {e}")
    sys.exit(1)

# Test 3: Check environment variables
print("\n3. Checking environment variables...")
required_vars = ["SUPABASE_URL", "SUPABASE_KEY"]
optional_vars = ["SUPABASE_JWT_SECRET"]

missing_vars = []
for var in required_vars:
    if not os.getenv(var):
        missing_vars.append(var)
        print(f"   ✗ Missing required variable: {var}")
    else:
        print(f"   ✓ Found {var}")

for var in optional_vars:
    if os.getenv(var):
        print(f"   ✓ Found {var}")
    else:
        print(f"   ⚠ Optional variable {var} not set (will use JWKS)")

if missing_vars:
    print(f"\n   ✗ Missing required environment variables: {', '.join(missing_vars)}")
    sys.exit(1)

# Test 4: Verify SupabaseClient has user filtering
print("\n4. Testing SupabaseClient user filtering...")
try:
    from src.supabase_client import SupabaseClient
    import inspect
    
    client_methods = [
        ('get_story', ['story_id', 'user_id']),
        ('get_all_stories', ['user_id']),
        ('get_child', ['child_id', 'user_id']),
        ('get_all_children', ['user_id']),
        ('delete_story', ['story_id', 'user_id']),
        ('delete_child', ['child_id', 'user_id']),
    ]
    
    all_methods_ok = True
    for method_name, expected_params in client_methods:
        method = getattr(SupabaseClient, method_name)
        sig = inspect.signature(method)
        params = list(sig.parameters.keys())
        
        # Check if all expected params exist
        has_all_params = all(param in params for param in expected_params)
        
        if has_all_params:
            print(f"   ✓ {method_name} has user_id parameter")
        else:
            print(f"   ✗ {method_name} missing expected parameters")
            all_methods_ok = False
    
    if not all_methods_ok:
        print("\n   ✗ Some methods don't have proper user_id parameters")
        sys.exit(1)
        
except Exception as e:
    print(f"   ✗ Error checking SupabaseClient: {e}")
    sys.exit(1)

# Test 5: Verify models have user_id field
print("\n5. Testing model definitions...")
try:
    from src.models import StoryDB, ChildDB
    
    # Check StoryDB
    story_fields = StoryDB.model_fields
    if 'user_id' in story_fields:
        print("   ✓ StoryDB has user_id field")
    else:
        print("   ✗ StoryDB missing user_id field")
        sys.exit(1)
    
    # Check ChildDB
    child_fields = ChildDB.model_fields
    if 'user_id' in child_fields:
        print("   ✓ ChildDB has user_id field")
    else:
        print("   ✗ ChildDB missing user_id field")
        sys.exit(1)
        
except Exception as e:
    print(f"   ✗ Error checking models: {e}")
    sys.exit(1)

# Test 6: Verify routes use authentication
print("\n6. Testing route authentication...")
try:
    from src.api.routes import (
        generate_story,
        generate_story_new,
        get_story,
        get_all_stories,
        create_child,
        get_child,
        get_all_children
    )
    
    routes_to_check = [
        ('generate_story', generate_story),
        ('generate_story_new', generate_story_new),
        ('get_story', get_story),
        ('get_all_stories', get_all_stories),
        ('create_child', create_child),
        ('get_child', get_child),
        ('get_all_children', get_all_children),
    ]
    
    all_routes_ok = True
    for route_name, route_func in routes_to_check:
        sig = inspect.signature(route_func)
        params = list(sig.parameters.keys())
        
        if 'user' in params:
            print(f"   ✓ {route_name} requires authentication")
        else:
            print(f"   ✗ {route_name} missing user parameter")
            all_routes_ok = False
    
    if not all_routes_ok:
        print("\n   ✗ Some routes don't require authentication")
        sys.exit(1)
        
except Exception as e:
    print(f"   ✗ Error checking routes: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 70)
print("✓ All authentication implementation tests passed!")
print("=" * 70)
print("\nNext steps:")
print("1. Start the backend server: uv run python main.py")
print("2. Start the frontend: cd frontend && npm run dev")
print("3. Test story generation with authentication")
print("=" * 70)
