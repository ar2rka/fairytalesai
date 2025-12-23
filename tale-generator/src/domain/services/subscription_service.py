"""Subscription service for managing user plans and limits."""

import logging
from datetime import datetime
from typing import Optional, Dict, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger("tale_generator.subscription")


class SubscriptionPlan(str, Enum):
    """Subscription plan tiers."""
    FREE = "free"
    STARTER = "starter"
    NORMAL = "normal"
    PREMIUM = "premium"


class SubscriptionStatus(str, Enum):
    """Subscription status values."""
    ACTIVE = "active"
    INACTIVE = "inactive"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


@dataclass(frozen=True)
class PlanLimits:
    """Immutable plan limits configuration."""
    monthly_stories: Optional[int]  # None means unlimited
    child_profiles: Optional[int]  # None means unlimited
    max_story_length: int  # in minutes
    audio_enabled: bool
    hero_stories_enabled: bool
    combined_stories_enabled: bool
    priority_support: bool
    
    def is_unlimited_stories(self) -> bool:
        """Check if plan has unlimited stories."""
        return self.monthly_stories is None


@dataclass
class UserSubscription:
    """User subscription information."""
    user_id: str
    plan: SubscriptionPlan
    status: SubscriptionStatus
    start_date: Optional[datetime]
    end_date: Optional[datetime]
    monthly_story_count: int
    last_reset_date: datetime


class PlanRegistry:
    """Registry of plan definitions and their limits."""
    
    _PLAN_LIMITS: Dict[SubscriptionPlan, PlanLimits] = {
        SubscriptionPlan.FREE: PlanLimits(
            monthly_stories=5,
            child_profiles=2,
            max_story_length=4,
            audio_enabled=False,
            hero_stories_enabled=False,
            combined_stories_enabled=False,
            priority_support=False
        ),
        SubscriptionPlan.STARTER: PlanLimits(
            monthly_stories=25,
            child_profiles=5,
            max_story_length=8,
            audio_enabled=True,
            hero_stories_enabled=True,
            combined_stories_enabled=True,
            priority_support=False
        ),
        SubscriptionPlan.NORMAL: PlanLimits(
            monthly_stories=100,
            child_profiles=10,
            max_story_length=30,
            audio_enabled=True,
            hero_stories_enabled=True,
            combined_stories_enabled=True,
            priority_support=True
        ),
        SubscriptionPlan.PREMIUM: PlanLimits(
            monthly_stories=None,  # Unlimited
            child_profiles=None,   # Unlimited
            max_story_length=30,
            audio_enabled=True,
            hero_stories_enabled=True,
            combined_stories_enabled=True,
            priority_support=True
        )
    }
    
    @classmethod
    def get_limits(cls, plan: SubscriptionPlan) -> PlanLimits:
        """Get limits for a specific plan."""
        return cls._PLAN_LIMITS[plan]
    
    @classmethod
    def get_all_plans(cls) -> Dict[SubscriptionPlan, PlanLimits]:
        """Get all plan definitions."""
        return cls._PLAN_LIMITS.copy()


class SubscriptionService:
    """Service for subscription validation and management."""
    
    def __init__(self):
        self.plan_registry = PlanRegistry()
    
    def get_plan_limits(self, plan: SubscriptionPlan) -> PlanLimits:
        """Get limits for a specific plan."""
        return self.plan_registry.get_limits(plan)
    
    def check_subscription_active(self, subscription: UserSubscription) -> bool:
        """Check if subscription is active."""
        if subscription.status != SubscriptionStatus.ACTIVE:
            return False
        
        # Check if subscription has expired
        if subscription.end_date and subscription.end_date < datetime.now():
            return False
        
        return True
    
    def needs_monthly_reset(self, subscription: UserSubscription) -> bool:
        """Check if monthly counter needs to be reset."""
        current_month = datetime.now().strftime('%Y-%m')
        last_reset_month = subscription.last_reset_date.strftime('%Y-%m')
        return current_month != last_reset_month
    
    def check_story_limit(
        self, 
        subscription: UserSubscription,
        after_reset: bool = False
    ) -> tuple[bool, Optional[str]]:
        """
        Check if user is within monthly story limit.
        
        Args:
            subscription: User subscription info
            after_reset: Whether counter has already been reset
            
        Returns:
            Tuple of (is_within_limit, error_message)
        """
        limits = self.get_plan_limits(subscription.plan)
        
        # Premium has unlimited stories
        if limits.is_unlimited_stories():
            return True, None
        
        current_count = 0 if after_reset else subscription.monthly_story_count
        
        if current_count >= limits.monthly_stories:
            # Calculate reset date (first day of next month)
            current_date = datetime.now()
            if current_date.month == 12:
                reset_date = datetime(current_date.year + 1, 1, 1)
            else:
                reset_date = datetime(current_date.year, current_date.month + 1, 1)
            
            error_msg = (
                f"Monthly story limit exceeded. "
                f"You have used {current_count}/{limits.monthly_stories} stories. "
                f"Limit resets on {reset_date.strftime('%Y-%m-%d')}. "
                f"Upgrade your plan for more stories."
            )
            return False, error_msg
        
        return True, None
    
    def check_child_limit(
        self,
        subscription: UserSubscription,
        current_child_count: int
    ) -> tuple[bool, Optional[str]]:
        """
        Check if user can create another child profile.
        
        Args:
            subscription: User subscription info
            current_child_count: Current number of child profiles
            
        Returns:
            Tuple of (can_create, error_message)
        """
        limits = self.get_plan_limits(subscription.plan)
        
        # Premium has unlimited child profiles
        if limits.child_profiles is None:
            return True, None
        
        if current_child_count >= limits.child_profiles:
            error_msg = (
                f"Child profile limit exceeded for your {subscription.plan.value} plan. "
                f"You have {current_child_count}/{limits.child_profiles} profiles. "
                f"Upgrade your plan to create more child profiles."
            )
            return False, error_msg
        
        return True, None
    
    def check_story_type_allowed(
        self,
        subscription: UserSubscription,
        story_type: str
    ) -> tuple[bool, Optional[str]]:
        """
        Check if story type is allowed for user's plan.
        
        Args:
            subscription: User subscription info
            story_type: Type of story (child, hero, combined)
            
        Returns:
            Tuple of (is_allowed, error_message)
        """
        limits = self.get_plan_limits(subscription.plan)
        
        if story_type == "child":
            # Child-only stories are allowed for all plans
            return True, None
        
        if story_type == "hero":
            if not limits.hero_stories_enabled:
                error_msg = (
                    f"Hero stories are not available in your {subscription.plan.value} plan. "
                    f"Upgrade to Starter or higher to create hero stories."
                )
                return False, error_msg
            return True, None
        
        if story_type == "combined":
            if not limits.combined_stories_enabled:
                error_msg = (
                    f"Combined stories are not available in your {subscription.plan.value} plan. "
                    f"Upgrade to Starter or higher to create combined stories."
                )
                return False, error_msg
            return True, None
        
        return True, None
    
    def check_audio_allowed(
        self,
        subscription: UserSubscription
    ) -> tuple[bool, Optional[str]]:
        """
        Check if audio generation is allowed for user's plan.
        
        Args:
            subscription: User subscription info
            
        Returns:
            Tuple of (is_allowed, error_message)
        """
        limits = self.get_plan_limits(subscription.plan)
        
        if not limits.audio_enabled:
            error_msg = (
                f"Audio generation is not available in your {subscription.plan.value} plan. "
                f"Upgrade to Starter or higher to enable audio narration."
            )
            return False, error_msg
        
        return True, None
    
    def check_story_length(
        self,
        subscription: UserSubscription,
        requested_length: int
    ) -> tuple[bool, Optional[str]]:
        """
        Check if requested story length is within plan limits.
        
        Args:
            subscription: User subscription info
            requested_length: Requested story length in minutes
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        limits = self.get_plan_limits(subscription.plan)
        
        if requested_length > limits.max_story_length:
            error_msg = (
                f"Story length exceeds plan limit. "
                f"Your {subscription.plan.value} plan allows up to {limits.max_story_length} minutes, "
                f"but you requested {requested_length} minutes. "
                f"Please reduce story length or upgrade your plan."
            )
            return False, error_msg
        
        return True, None
    
    def get_subscription_info(
        self,
        subscription: UserSubscription,
        child_count: int
    ) -> Dict[str, Any]:
        """
        Get complete subscription information for API response.
        
        Args:
            subscription: User subscription info
            child_count: Current child profile count
            
        Returns:
            Dictionary with subscription details, limits, and features
        """
        limits = self.get_plan_limits(subscription.plan)
        
        # Calculate reset date
        current_date = datetime.now()
        if current_date.month == 12:
            reset_date = datetime(current_date.year + 1, 1, 1)
        else:
            reset_date = datetime(current_date.year, current_date.month + 1, 1)
        
        # Calculate remaining stories
        stories_remaining = None
        if limits.monthly_stories is not None:
            stories_remaining = max(0, limits.monthly_stories - subscription.monthly_story_count)
        
        return {
            "subscription": {
                "plan": subscription.plan.value,
                "status": subscription.status.value,
                "start_date": subscription.start_date.isoformat() if subscription.start_date else None,
                "end_date": subscription.end_date.isoformat() if subscription.end_date else None
            },
            "limits": {
                "monthly_stories": limits.monthly_stories,
                "stories_used": subscription.monthly_story_count,
                "stories_remaining": stories_remaining,
                "reset_date": reset_date.isoformat(),
                "child_profiles_limit": limits.child_profiles,
                "child_profiles_count": child_count,
                "audio_enabled": limits.audio_enabled,
                "hero_stories_enabled": limits.hero_stories_enabled,
                "max_story_length": limits.max_story_length
            },
            "features": {
                "audio_generation": limits.audio_enabled,
                "hero_stories": limits.hero_stories_enabled,
                "combined_stories": limits.combined_stories_enabled,
                "priority_support": limits.priority_support
            }
        }
