"""Test subscription purchase system functionality."""

import asyncio
import os
from datetime import datetime
from decimal import Decimal
from dotenv import load_dotenv

from src.domain.services.subscription_service import (
    SubscriptionPlan,
    SubscriptionStatus,
    UserSubscription
)
from src.domain.services.payment_provider import MockPaymentProvider, PaymentRequest
from src.domain.services.plan_catalog import PlanCatalog, BillingCycle
from src.domain.services.purchase_service import PurchaseService

# Load environment variables
load_dotenv()


def test_plan_catalog():
    """Test plan catalog and pricing."""
    print("\n" + "="*80)
    print("TEST: Plan Catalog")
    print("="*80)
    
    # Test getting all plans
    all_plans = PlanCatalog.get_all_plans()
    print(f"\nTotal plans: {len(all_plans)}")
    
    for plan_tier, plan_def in all_plans.items():
        print(f"\n{plan_def.display_name}:")
        print(f"  Tier: {plan_tier.value}")
        print(f"  Monthly Price: ${plan_def.monthly_price}")
        print(f"  Annual Price: ${plan_def.annual_price}")
        print(f"  Is Purchasable: {plan_def.is_purchasable}")
        print(f"  Features: {len(plan_def.features)}")
    
    # Test pricing
    starter_monthly = PlanCatalog.get_price(SubscriptionPlan.STARTER, BillingCycle.MONTHLY)
    starter_annual = PlanCatalog.get_price(SubscriptionPlan.STARTER, BillingCycle.ANNUAL)
    
    assert starter_monthly == Decimal("9.99")
    assert starter_annual == Decimal("99.99")
    
    print("\n✅ Plan catalog tests passed!")


def test_upgrade_validation():
    """Test subscription upgrade validation."""
    print("\n" + "="*80)
    print("TEST: Upgrade Validation")
    print("="*80)
    
    # Test valid upgrade paths
    valid_upgrades = [
        (SubscriptionPlan.FREE, SubscriptionPlan.STARTER),
        (SubscriptionPlan.FREE, SubscriptionPlan.NORMAL),
        (SubscriptionPlan.FREE, SubscriptionPlan.PREMIUM),
        (SubscriptionPlan.STARTER, SubscriptionPlan.NORMAL),
        (SubscriptionPlan.STARTER, SubscriptionPlan.PREMIUM),
        (SubscriptionPlan.NORMAL, SubscriptionPlan.PREMIUM),
    ]
    
    for from_plan, to_plan in valid_upgrades:
        is_valid = PlanCatalog.is_valid_upgrade(from_plan, to_plan)
        print(f"{from_plan.value} → {to_plan.value}: {is_valid}")
        assert is_valid, f"Expected {from_plan.value} → {to_plan.value} to be valid"
    
    # Test invalid upgrade paths
    invalid_upgrades = [
        (SubscriptionPlan.STARTER, SubscriptionPlan.FREE),
        (SubscriptionPlan.PREMIUM, SubscriptionPlan.NORMAL),
        (SubscriptionPlan.NORMAL, SubscriptionPlan.STARTER),
        (SubscriptionPlan.FREE, SubscriptionPlan.FREE),
    ]
    
    for from_plan, to_plan in invalid_upgrades:
        is_valid = PlanCatalog.is_valid_upgrade(from_plan, to_plan)
        print(f"{from_plan.value} → {to_plan.value}: {is_valid}")
        assert not is_valid, f"Expected {from_plan.value} → {to_plan.value} to be invalid"
    
    print("\n✅ Upgrade validation tests passed!")


def test_mock_payment_provider():
    """Test mock payment provider."""
    print("\n" + "="*80)
    print("TEST: Mock Payment Provider")
    print("="*80)
    
    provider = MockPaymentProvider(success_rate=1.0, processing_delay_ms=100)
    
    # Test successful payment
    request = PaymentRequest(
        amount=Decimal("9.99"),
        currency="USD",
        payment_method="mock_card",
        user_id="test-user-123",
        plan_tier="starter",
        billing_cycle="monthly"
    )
    
    print("\nTest 1: Successful payment")
    response = provider.process_payment(request)
    print(f"  Success: {response.success}")
    print(f"  Reference: {response.reference}")
    assert response.success
    assert response.reference.startswith("MOCK-")
    assert len(response.reference) == 17  # MOCK- + 12 digits
    
    # Test declined payment
    request.payment_method = "mock_card_declined"
    print("\nTest 2: Declined payment")
    response = provider.process_payment(request)
    print(f"  Success: {response.success}")
    print(f"  Error Code: {response.error_code}")
    print(f"  Error Message: {response.error_message}")
    assert not response.success
    assert response.error_code == "CARD_DECLINED"
    
    # Test expired card
    request.payment_method = "mock_card_expired"
    print("\nTest 3: Expired card")
    response = provider.process_payment(request)
    print(f"  Success: {response.success}")
    print(f"  Error Code: {response.error_code}")
    assert not response.success
    assert response.error_code == "CARD_EXPIRED"
    
    print("\n✅ Mock payment provider tests passed!")


def test_purchase_service():
    """Test purchase service workflow."""
    print("\n" + "="*80)
    print("TEST: Purchase Service")
    print("="*80)
    
    # Create mock subscription
    current_subscription = UserSubscription(
        user_id="test-user-123",
        plan=SubscriptionPlan.FREE,
        status=SubscriptionStatus.ACTIVE,
        start_date=datetime.now(),
        end_date=None,
        monthly_story_count=3,
        last_reset_date=datetime.now()
    )
    
    # Initialize services
    payment_provider = MockPaymentProvider(success_rate=1.0, processing_delay_ms=100)
    purchase_service = PurchaseService(payment_provider)
    
    # Test successful upgrade
    print("\nTest 1: Successful purchase")
    success, transaction, error = purchase_service.initiate_purchase(
        user_id=current_subscription.user_id,
        current_subscription=current_subscription,
        target_plan=SubscriptionPlan.STARTER,
        billing_cycle=BillingCycle.MONTHLY,
        payment_method="mock_card"
    )
    
    print(f"  Success: {success}")
    if transaction:
        print(f"  From Plan: {transaction.from_plan}")
        print(f"  To Plan: {transaction.to_plan}")
        print(f"  Amount: ${transaction.amount}")
        print(f"  Status: {transaction.payment_status}")
        print(f"  Reference: {transaction.transaction_reference}")
    
    assert success
    assert transaction is not None
    assert transaction.payment_status == "completed"
    assert transaction.amount == Decimal("9.99")
    
    # Test invalid upgrade
    print("\nTest 2: Invalid upgrade (same plan)")
    success, transaction, error = purchase_service.initiate_purchase(
        user_id=current_subscription.user_id,
        current_subscription=current_subscription,
        target_plan=SubscriptionPlan.FREE,
        billing_cycle=BillingCycle.MONTHLY,
        payment_method="mock_card"
    )
    
    print(f"  Success: {success}")
    print(f"  Error: {error}")
    assert not success
    assert error is not None
    
    # Test payment failure
    print("\nTest 3: Payment failure")
    success, transaction, error = purchase_service.initiate_purchase(
        user_id=current_subscription.user_id,
        current_subscription=current_subscription,
        target_plan=SubscriptionPlan.STARTER,
        billing_cycle=BillingCycle.MONTHLY,
        payment_method="mock_card_declined"
    )
    
    print(f"  Success: {success}")
    print(f"  Error: {error}")
    if transaction:
        print(f"  Status: {transaction.payment_status}")
    
    assert not success
    assert transaction is not None
    assert transaction.payment_status == "failed"
    
    # Test subscription update creation
    print("\nTest 4: Updated subscription creation")
    updated_sub = purchase_service.create_updated_subscription(
        current_subscription=current_subscription,
        new_plan=SubscriptionPlan.PREMIUM,
        billing_cycle=BillingCycle.ANNUAL
    )
    
    print(f"  New Plan: {updated_sub.plan.value}")
    print(f"  Status: {updated_sub.status.value}")
    print(f"  Story Count: {updated_sub.monthly_story_count}")
    print(f"  End Date: {updated_sub.end_date}")
    
    assert updated_sub.plan == SubscriptionPlan.PREMIUM
    assert updated_sub.status == SubscriptionStatus.ACTIVE
    assert updated_sub.monthly_story_count == 0
    assert updated_sub.end_date is not None
    
    print("\n✅ Purchase service tests passed!")


def test_billing_cycle_pricing():
    """Test different billing cycle pricing."""
    print("\n" + "="*80)
    print("TEST: Billing Cycle Pricing")
    print("="*80)
    
    plans = [SubscriptionPlan.STARTER, SubscriptionPlan.NORMAL, SubscriptionPlan.PREMIUM]
    
    for plan in plans:
        monthly = PlanCatalog.get_price(plan, BillingCycle.MONTHLY)
        annual = PlanCatalog.get_price(plan, BillingCycle.ANNUAL)
        monthly_equiv = annual / 12
        savings_percent = ((monthly * 12 - annual) / (monthly * 12)) * 100
        
        print(f"\n{plan.value.upper()} Plan:")
        print(f"  Monthly: ${monthly}/month")
        print(f"  Annual: ${annual}/year (${monthly_equiv:.2f}/month)")
        print(f"  Savings: {savings_percent:.1f}%")
        
        # Verify annual discount is approximately 17%
        assert 15 <= savings_percent <= 18
    
    print("\n✅ Billing cycle pricing tests passed!")


def main():
    """Run all tests."""
    print("\n" + "="*80)
    print("SUBSCRIPTION PURCHASE SYSTEM TESTS")
    print("="*80)
    
    try:
        test_plan_catalog()
        test_upgrade_validation()
        test_mock_payment_provider()
        test_purchase_service()
        test_billing_cycle_pricing()
        
        print("\n" + "="*80)
        print("✅ ALL TESTS PASSED!")
        print("="*80)
        print("\nThe subscription purchase system is working correctly:")
        print("  • Plan catalog and pricing configured")
        print("  • Upgrade validation logic functional")
        print("  • Mock payment provider operational")
        print("  • Purchase workflow complete")
        print("  • Billing cycles and discounts verified")
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        raise
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        raise


if __name__ == "__main__":
    main()
