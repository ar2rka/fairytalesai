"""Purchase service for managing subscription purchases."""

import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional, Tuple
from dataclasses import dataclass

from src.domain.services.subscription_service import (
    SubscriptionPlan,
    SubscriptionStatus,
    UserSubscription,
    SubscriptionService
)
from src.domain.services.payment_provider import (
    PaymentProvider,
    PaymentRequest,
    PaymentResponse
)
from src.domain.services.plan_catalog import PlanCatalog, BillingCycle

logger = logging.getLogger("tale_generator.purchase")


@dataclass
class PurchaseTransaction:
    """Purchase transaction record."""
    id: Optional[str]
    user_id: str
    from_plan: str
    to_plan: str
    amount: Decimal
    currency: str
    payment_status: str
    payment_method: str
    payment_provider: str
    transaction_reference: str
    created_at: datetime
    completed_at: Optional[datetime]
    metadata: Optional[dict]


class PurchaseService:
    """Service for managing subscription purchases."""
    
    def __init__(
        self,
        payment_provider: PaymentProvider,
        subscription_service: Optional[SubscriptionService] = None
    ):
        """
        Initialize purchase service.
        
        Args:
            payment_provider: Payment provider instance
            subscription_service: Subscription service instance (creates new if None)
        """
        self.payment_provider = payment_provider
        self.subscription_service = subscription_service or SubscriptionService()
        logger.info(
            f"Purchase service initialized with {payment_provider.get_provider_name()} provider"
        )
    
    def validate_upgrade(
        self,
        current_subscription: UserSubscription,
        target_plan: SubscriptionPlan
    ) -> Tuple[bool, Optional[str]]:
        """
        Validate if user can upgrade to target plan.
        
        Args:
            current_subscription: User's current subscription
            target_plan: Desired plan tier
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check subscription status
        if current_subscription.status not in [SubscriptionStatus.ACTIVE, SubscriptionStatus.INACTIVE]:
            return False, "Cannot upgrade cancelled or expired subscription"
        
        # Check if it's a valid upgrade path
        if not PlanCatalog.is_valid_upgrade(current_subscription.plan, target_plan):
            if current_subscription.plan == target_plan:
                return False, f"You already have the {target_plan.value} plan"
            return False, f"Cannot upgrade from {current_subscription.plan.value} to {target_plan.value}"
        
        return True, None
    
    def calculate_price(
        self,
        plan: SubscriptionPlan,
        billing_cycle: BillingCycle
    ) -> Decimal:
        """
        Calculate price for a plan and billing cycle.
        
        Args:
            plan: Target plan tier
            billing_cycle: Monthly or annual
            
        Returns:
            Price in USD
        """
        return PlanCatalog.get_price(plan, billing_cycle)
    
    def initiate_purchase(
        self,
        user_id: str,
        current_subscription: UserSubscription,
        target_plan: SubscriptionPlan,
        billing_cycle: BillingCycle,
        payment_method: str
    ) -> Tuple[bool, Optional[PurchaseTransaction], Optional[str]]:
        """
        Initiate a subscription purchase.
        
        This method:
        1. Validates the upgrade is allowed
        2. Calculates the price
        3. Processes payment through provider
        4. Creates transaction record
        5. Updates subscription on success
        
        Args:
            user_id: User identifier
            current_subscription: User's current subscription
            target_plan: Desired plan tier
            billing_cycle: Monthly or annual
            payment_method: Payment method identifier
            
        Returns:
            Tuple of (success, transaction, error_message)
        """
        logger.info(
            f"Initiating purchase: user={user_id}, "
            f"from={current_subscription.plan.value}, "
            f"to={target_plan.value}, "
            f"cycle={billing_cycle.value}"
        )
        
        # Validate upgrade
        is_valid, error_msg = self.validate_upgrade(current_subscription, target_plan)
        if not is_valid:
            logger.warning(f"Purchase validation failed: {error_msg}")
            return False, None, error_msg
        
        # Validate payment method
        if not self.payment_provider.validate_payment_method(payment_method):
            error_msg = f"Invalid payment method: {payment_method}"
            logger.warning(error_msg)
            return False, None, error_msg
        
        # Calculate price
        try:
            amount = self.calculate_price(target_plan, billing_cycle)
        except ValueError as e:
            logger.error(f"Price calculation failed: {e}")
            return False, None, str(e)
        
        # Create payment request
        payment_request = PaymentRequest(
            amount=amount,
            currency="USD",
            payment_method=payment_method,
            user_id=user_id,
            plan_tier=target_plan.value,
            billing_cycle=billing_cycle.value,
            metadata={
                "from_plan": current_subscription.plan.value,
                "to_plan": target_plan.value,
                "billing_cycle": billing_cycle.value,
            }
        )
        
        # Process payment
        logger.info(f"Processing payment: amount=${amount}, method={payment_method}")
        payment_response = self.payment_provider.process_payment(payment_request)
        
        # Create transaction record
        transaction = PurchaseTransaction(
            id=None,  # Will be set by database
            user_id=user_id,
            from_plan=current_subscription.plan.value,
            to_plan=target_plan.value,
            amount=amount,
            currency="USD",
            payment_status="completed" if payment_response.success else "failed",
            payment_method=payment_method,
            payment_provider=self.payment_provider.get_provider_name(),
            transaction_reference=payment_response.reference,
            created_at=datetime.now(),
            completed_at=payment_response.timestamp if payment_response.success else None,
            metadata={
                "billing_cycle": billing_cycle.value,
                "error_code": payment_response.error_code,
                "error_message": payment_response.error_message,
            }
        )
        
        if not payment_response.success:
            error_msg = payment_response.error_message or "Payment processing failed"
            logger.warning(
                f"Payment failed: {payment_response.error_code} - {error_msg}"
            )
            return False, transaction, error_msg
        
        logger.info(
            f"Payment successful: reference={payment_response.reference}"
        )
        
        return True, transaction, None
    
    def calculate_subscription_end_date(
        self,
        billing_cycle: BillingCycle,
        start_date: Optional[datetime] = None
    ) -> datetime:
        """
        Calculate subscription end date based on billing cycle.
        
        Args:
            billing_cycle: Monthly or annual
            start_date: Start date (defaults to now)
            
        Returns:
            End date timestamp
        """
        if start_date is None:
            start_date = datetime.now()
        
        if billing_cycle == BillingCycle.MONTHLY:
            return start_date + timedelta(days=30)
        else:  # ANNUAL
            return start_date + timedelta(days=365)
    
    def create_updated_subscription(
        self,
        current_subscription: UserSubscription,
        new_plan: SubscriptionPlan,
        billing_cycle: BillingCycle
    ) -> UserSubscription:
        """
        Create updated subscription object after successful purchase.
        
        Args:
            current_subscription: Current subscription
            new_plan: New plan tier
            billing_cycle: Billing cycle for end date calculation
            
        Returns:
            Updated UserSubscription object
        """
        start_date = datetime.now()
        end_date = self.calculate_subscription_end_date(billing_cycle, start_date)
        
        return UserSubscription(
            user_id=current_subscription.user_id,
            plan=new_plan,
            status=SubscriptionStatus.ACTIVE,
            start_date=start_date,
            end_date=end_date,
            monthly_story_count=0,  # Reset counter on upgrade
            last_reset_date=start_date
        )
