"""Plan pricing configuration and definitions."""

from dataclasses import dataclass
from decimal import Decimal
from typing import Dict, List
from enum import Enum

from src.domain.services.subscription_service import SubscriptionPlan, PlanLimits, PlanRegistry


class BillingCycle(str, Enum):
    """Billing cycle options."""
    MONTHLY = "monthly"
    ANNUAL = "annual"


@dataclass(frozen=True)
class PlanPricing:
    """Pricing information for a subscription plan."""
    monthly_price: Decimal
    annual_price: Decimal
    
    def get_price(self, billing_cycle: BillingCycle) -> Decimal:
        """Get price for specified billing cycle."""
        if billing_cycle == BillingCycle.MONTHLY:
            return self.monthly_price
        return self.annual_price
    
    def get_monthly_equivalent(self, billing_cycle: BillingCycle) -> Decimal:
        """Get monthly equivalent price for comparison."""
        if billing_cycle == BillingCycle.MONTHLY:
            return self.monthly_price
        return self.annual_price / 12


@dataclass(frozen=True)
class PlanDefinition:
    """Complete plan definition with features, limits, and pricing."""
    plan_tier: SubscriptionPlan
    display_name: str
    description: str
    monthly_price: Decimal
    annual_price: Decimal
    features: List[str]
    limits: PlanLimits
    is_purchasable: bool = True
    
    @property
    def pricing(self) -> PlanPricing:
        """Get pricing object for this plan."""
        return PlanPricing(
            monthly_price=self.monthly_price,
            annual_price=self.annual_price
        )
    
    def get_price(self, billing_cycle: BillingCycle) -> Decimal:
        """Get price for specified billing cycle."""
        return self.pricing.get_price(billing_cycle)


class PlanCatalog:
    """Catalog of all available subscription plans with pricing."""
    
    # Plan pricing (in USD)
    _PRICING = {
        SubscriptionPlan.STARTER: PlanPricing(
            monthly_price=Decimal("9.99"),
            annual_price=Decimal("99.99")  # 17% discount
        ),
        SubscriptionPlan.NORMAL: PlanPricing(
            monthly_price=Decimal("19.99"),
            annual_price=Decimal("199.99")  # 17% discount
        ),
        SubscriptionPlan.PREMIUM: PlanPricing(
            monthly_price=Decimal("39.99"),
            annual_price=Decimal("399.99")  # 17% discount
        ),
    }
    
    # Plan descriptions
    _DESCRIPTIONS = {
        SubscriptionPlan.FREE: "Perfect for trying out our service",
        SubscriptionPlan.STARTER: "Great for families getting started",
        SubscriptionPlan.NORMAL: "Best for regular storytelling",
        SubscriptionPlan.PREMIUM: "Ultimate unlimited experience",
    }
    
    # Plan display names
    _DISPLAY_NAMES = {
        SubscriptionPlan.FREE: "Free Plan",
        SubscriptionPlan.STARTER: "Starter Plan",
        SubscriptionPlan.NORMAL: "Normal Plan",
        SubscriptionPlan.PREMIUM: "Premium Plan",
    }
    
    # Feature highlights for each plan
    _FEATURES = {
        SubscriptionPlan.FREE: [
            "5 stories per month",
            "Up to 2 child profiles",
            "Child-focused stories only",
            "4 minute story length",
            "Text stories only",
        ],
        SubscriptionPlan.STARTER: [
            "25 stories per month",
            "Up to 5 child profiles",
            "Hero and combined stories",
            "8 minute story length",
            "Audio narration included",
            "Email support",
        ],
        SubscriptionPlan.NORMAL: [
            "100 stories per month",
            "Up to 10 child profiles",
            "Hero and combined stories",
            "30 minute story length",
            "Audio narration included",
            "Priority email support",
        ],
        SubscriptionPlan.PREMIUM: [
            "Unlimited stories",
            "Unlimited child profiles",
            "Hero and combined stories",
            "30 minute story length",
            "Audio narration included",
            "Priority support",
            "Early access to new features",
        ],
    }
    
    @classmethod
    def get_plan_definition(cls, plan: SubscriptionPlan) -> PlanDefinition:
        """
        Get complete plan definition.
        
        Args:
            plan: Plan tier
            
        Returns:
            PlanDefinition object
        """
        limits = PlanRegistry.get_limits(plan)
        pricing = cls._PRICING.get(plan, PlanPricing(Decimal("0"), Decimal("0")))
        
        return PlanDefinition(
            plan_tier=plan,
            display_name=cls._DISPLAY_NAMES[plan],
            description=cls._DESCRIPTIONS[plan],
            monthly_price=pricing.monthly_price,
            annual_price=pricing.annual_price,
            features=cls._FEATURES[plan],
            limits=limits,
            is_purchasable=plan != SubscriptionPlan.FREE
        )
    
    @classmethod
    def get_all_plans(cls) -> Dict[SubscriptionPlan, PlanDefinition]:
        """
        Get all plan definitions.
        
        Returns:
            Dictionary mapping plan tiers to definitions
        """
        return {
            plan: cls.get_plan_definition(plan)
            for plan in SubscriptionPlan
        }
    
    @classmethod
    def get_purchasable_plans(cls) -> Dict[SubscriptionPlan, PlanDefinition]:
        """
        Get only purchasable plans (excludes free).
        
        Returns:
            Dictionary of purchasable plan definitions
        """
        return {
            plan: definition
            for plan, definition in cls.get_all_plans().items()
            if definition.is_purchasable
        }
    
    @classmethod
    def get_price(cls, plan: SubscriptionPlan, billing_cycle: BillingCycle) -> Decimal:
        """
        Get price for a plan and billing cycle.
        
        Args:
            plan: Plan tier
            billing_cycle: Monthly or annual
            
        Returns:
            Price in USD
            
        Raises:
            ValueError: If plan is not purchasable
        """
        if plan == SubscriptionPlan.FREE:
            raise ValueError("Free plan is not purchasable")
        
        pricing = cls._PRICING.get(plan)
        if not pricing:
            raise ValueError(f"No pricing defined for plan: {plan}")
        
        return pricing.get_price(billing_cycle)
    
    @classmethod
    def is_valid_upgrade(cls, from_plan: SubscriptionPlan, to_plan: SubscriptionPlan) -> bool:
        """
        Check if upgrade from one plan to another is valid.
        
        Args:
            from_plan: Current plan
            to_plan: Target plan
            
        Returns:
            True if valid upgrade path, False otherwise
        """
        # Cannot upgrade to free
        if to_plan == SubscriptionPlan.FREE:
            return False
        
        # Cannot "upgrade" to same plan
        if from_plan == to_plan:
            return False
        
        # Define valid upgrade paths
        plan_hierarchy = {
            SubscriptionPlan.FREE: 0,
            SubscriptionPlan.STARTER: 1,
            SubscriptionPlan.NORMAL: 2,
            SubscriptionPlan.PREMIUM: 3,
        }
        
        # Valid upgrade means moving to higher tier
        return plan_hierarchy[to_plan] > plan_hierarchy[from_plan]
