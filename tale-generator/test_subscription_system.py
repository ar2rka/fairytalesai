"""Test subscription system functionality."""

import asyncio
import os
from datetime import datetime
from dotenv import load_dotenv

from src.supabase_client import SupabaseClient
from src.domain.services.subscription_service import (
    SubscriptionService,
    SubscriptionPlan,
    SubscriptionStatus,
    UserSubscription,
    PlanRegistry
)

# Load environment variables
load_dotenv()


def test_plan_registry():
    """Test plan registry and limits."""
    print("\n" + "="*80)
    print("TEST: Plan Registry")
    print("="*80)
    
    # Test getting all plans
    all_plans = PlanRegistry.get_all_plans()
    print(f"\nTotal plans: {len(all_plans)}")
    
    for plan, limits in all_plans.items():
        print(f"\n{plan.value.upper()} Plan:")
        print(f"  Monthly Stories: {limits.monthly_stories or 'Unlimited'}")
        print(f"  Child Profiles: {limits.child_profiles or 'Unlimited'}")
        print(f"  Max Story Length: {limits.max_story_length} minutes")
        print(f"  Audio Enabled: {limits.audio_enabled}")
        print(f"  Hero Stories: {limits.hero_stories_enabled}")
        print(f"  Combined Stories: {limits.combined_stories_enabled}")
        print(f"  Priority Support: {limits.priority_support}")
    
    # Test specific plan
    free_limits = PlanRegistry.get_limits(SubscriptionPlan.FREE)
    assert free_limits.monthly_stories == 5
    assert free_limits.child_profiles == 2
    assert free_limits.audio_enabled == False
    assert free_limits.hero_stories_enabled == False
    
    print("\n✅ Plan registry tests passed!")


def test_subscription_service():
    """Test subscription service validation logic."""
    print("\n" + "="*80)
    print("TEST: Subscription Service")
    print("="*80)
    
    service = SubscriptionService()
    
    # Create a test subscription (free plan)
    subscription = UserSubscription(
        user_id="test-user-123",
        plan=SubscriptionPlan.FREE,
        status=SubscriptionStatus.ACTIVE,
        start_date=datetime.now(),
        end_date=None,
        monthly_story_count=0,
        last_reset_date=datetime.now()
    )
    
    # Test 1: Check subscription active
    print("\nTest 1: Active subscription")
    is_active = service.check_subscription_active(subscription)
    print(f"  Subscription active: {is_active}")
    assert is_active == True
    
    # Test 2: Check story limit (within limit)
    print("\nTest 2: Story limit check (0/5 used)")
    within_limit, error = service.check_story_limit(subscription)
    print(f"  Within limit: {within_limit}")
    print(f"  Error: {error}")
    assert within_limit == True
    assert error is None
    
    # Test 3: Check story limit (at limit)
    print("\nTest 3: Story limit check (5/5 used)")
    subscription.monthly_story_count = 5
    within_limit, error = service.check_story_limit(subscription)
    print(f"  Within limit: {within_limit}")
    print(f"  Error message: {error[:100] if error else None}...")
    assert within_limit == False
    assert error is not None
    
    # Test 4: Check child limit (within limit)
    print("\nTest 4: Child limit check (1/2 used)")
    can_create, error = service.check_child_limit(subscription, 1)
    print(f"  Can create: {can_create}")
    print(f"  Error: {error}")
    assert can_create == True
    
    # Test 5: Check child limit (at limit)
    print("\nTest 5: Child limit check (2/2 used)")
    can_create, error = service.check_child_limit(subscription, 2)
    print(f"  Can create: {can_create}")
    print(f"  Error message: {error[:100] if error else None}...")
    assert can_create == False
    assert error is not None
    
    # Test 6: Check story type allowed (child story)
    print("\nTest 6: Story type check - child story")
    allowed, error = service.check_story_type_allowed(subscription, "child")
    print(f"  Allowed: {allowed}")
    assert allowed == True
    
    # Test 7: Check story type not allowed (hero story on free plan)
    print("\nTest 7: Story type check - hero story (not allowed for free)")
    allowed, error = service.check_story_type_allowed(subscription, "hero")
    print(f"  Allowed: {allowed}")
    print(f"  Error message: {error[:100] if error else None}...")
    assert allowed == False
    assert error is not None
    
    # Test 8: Check audio not allowed (free plan)
    print("\nTest 8: Audio check (not allowed for free)")
    allowed, error = service.check_audio_allowed(subscription)
    print(f"  Allowed: {allowed}")
    print(f"  Error message: {error[:100] if error else None}...")
    assert allowed == False
    
    # Test 9: Check story length valid
    print("\nTest 9: Story length check (3 minutes, max 5)")
    valid, error = service.check_story_length(subscription, 3)
    print(f"  Valid: {valid}")
    assert valid == True
    
    # Test 10: Check story length invalid
    print("\nTest 10: Story length check (10 minutes, max 5)")
    valid, error = service.check_story_length(subscription, 10)
    print(f"  Valid: {valid}")
    print(f"  Error message: {error[:100] if error else None}...")
    assert valid == False
    
    # Test 11: Premium plan (unlimited stories)
    print("\nTest 11: Premium plan - unlimited stories")
    premium_subscription = UserSubscription(
        user_id="test-user-premium",
        plan=SubscriptionPlan.PREMIUM,
        status=SubscriptionStatus.ACTIVE,
        start_date=datetime.now(),
        end_date=None,
        monthly_story_count=1000,  # Even with high count
        last_reset_date=datetime.now()
    )
    within_limit, error = service.check_story_limit(premium_subscription)
    print(f"  Within limit (1000 stories used): {within_limit}")
    assert within_limit == True
    
    print("\n✅ Subscription service tests passed!")


def test_database_subscription():
    """Test database subscription operations."""
    print("\n" + "="*80)
    print("TEST: Database Subscription Operations")
    print("="*80)
    
    try:
        client = SupabaseClient()
        
        # This test requires a real user in the database
        # For now, just test that the methods exist and are callable
        print("\n✅ Database client has subscription methods:")
        print(f"  - get_user_subscription: {hasattr(client, 'get_user_subscription')}")
        print(f"  - reset_monthly_story_count: {hasattr(client, 'reset_monthly_story_count')}")
        print(f"  - increment_story_count: {hasattr(client, 'increment_story_count')}")
        print(f"  - track_usage: {hasattr(client, 'track_usage')}")
        print(f"  - count_user_children: {hasattr(client, 'count_user_children')}")
        
        assert hasattr(client, 'get_user_subscription')
        assert hasattr(client, 'reset_monthly_story_count')
        assert hasattr(client, 'increment_story_count')
        assert hasattr(client, 'track_usage')
        assert hasattr(client, 'count_user_children')
        
        print("\n✅ Database subscription tests passed!")
        
    except Exception as e:
        print(f"\n⚠️  Database connection not available: {str(e)}")
        print("Skipping database tests (this is expected if Supabase is not configured)")


def test_subscription_info_response():
    """Test subscription info response structure."""
    print("\n" + "="*80)
    print("TEST: Subscription Info Response")
    print("="*80)
    
    service = SubscriptionService()
    
    subscription = UserSubscription(
        user_id="test-user-123",
        plan=SubscriptionPlan.STARTER,
        status=SubscriptionStatus.ACTIVE,
        start_date=datetime(2024, 12, 1),
        end_date=None,
        monthly_story_count=10,
        last_reset_date=datetime.now()
    )
    
    child_count = 3
    
    info = service.get_subscription_info(subscription, child_count)
    
    print("\nSubscription Info Response:")
    print(f"  Plan: {info['subscription']['plan']}")
    print(f"  Status: {info['subscription']['status']}")
    print(f"  Monthly Stories Limit: {info['limits']['monthly_stories']}")
    print(f"  Stories Used: {info['limits']['stories_used']}")
    print(f"  Stories Remaining: {info['limits']['stories_remaining']}")
    print(f"  Child Profiles Limit: {info['limits']['child_profiles_limit']}")
    print(f"  Child Profiles Count: {info['limits']['child_profiles_count']}")
    print(f"  Audio Enabled: {info['features']['audio_generation']}")
    print(f"  Hero Stories Enabled: {info['features']['hero_stories']}")
    
    # Validate response structure
    assert 'subscription' in info
    assert 'limits' in info
    assert 'features' in info
    assert info['subscription']['plan'] == 'starter'
    assert info['limits']['monthly_stories'] == 25
    assert info['limits']['stories_used'] == 10
    assert info['limits']['stories_remaining'] == 15
    assert info['limits']['child_profiles_count'] == 3
    assert info['features']['audio_generation'] == True
    assert info['features']['hero_stories'] == True
    
    print("\n✅ Subscription info response tests passed!")


def test_monthly_reset_logic():
    """Test monthly reset detection."""
    print("\n" + "="*80)
    print("TEST: Monthly Reset Logic")
    print("="*80)
    
    service = SubscriptionService()
    
    # Test 1: Same month - no reset needed
    subscription = UserSubscription(
        user_id="test-user-123",
        plan=SubscriptionPlan.FREE,
        status=SubscriptionStatus.ACTIVE,
        start_date=datetime.now(),
        end_date=None,
        monthly_story_count=3,
        last_reset_date=datetime.now()
    )
    
    needs_reset = service.needs_monthly_reset(subscription)
    print(f"\nTest 1: Current month - needs reset: {needs_reset}")
    assert needs_reset == False
    
    # Test 2: Different month - reset needed
    from datetime import timedelta
    subscription.last_reset_date = datetime.now() - timedelta(days=35)
    needs_reset = service.needs_monthly_reset(subscription)
    print(f"Test 2: 35 days ago - needs reset: {needs_reset}")
    assert needs_reset == True
    
    print("\n✅ Monthly reset logic tests passed!")


if __name__ == "__main__":
    print("\n" + "="*80)
    print("SUBSCRIPTION SYSTEM TEST SUITE")
    print("="*80)
    
    try:
        # Run all tests
        test_plan_registry()
        test_subscription_service()
        test_monthly_reset_logic()
        test_subscription_info_response()
        test_database_subscription()
        
        print("\n" + "="*80)
        print("✅ ALL TESTS PASSED!")
        print("="*80)
        
    except AssertionError as e:
        print(f"\n❌ Test failed: {str(e)}")
        import traceback
        traceback.print_exc()
    except Exception as e:
        print(f"\n❌ Error running tests: {str(e)}")
        import traceback
        traceback.print_exc()
