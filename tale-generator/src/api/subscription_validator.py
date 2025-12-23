"""Subscription validation middleware for API endpoints."""

import logging
from typing import Optional
from fastapi import HTTPException, Depends, status
from src.api.auth import AuthUser, get_current_user
from src.supabase_client_async import AsyncSupabaseClient
from src.domain.services.subscription_service import SubscriptionService, UserSubscription

logger = logging.getLogger("tale_generator.subscription_validator")


class SubscriptionValidator:
    """Validates user subscription limits and permissions."""
    
    def __init__(self):
        self.supabase_client = AsyncSupabaseClient()
        self.subscription_service = SubscriptionService()
    
    async def get_and_validate_subscription(
        self, 
        user: AuthUser
    ) -> UserSubscription:
        """
        Get user subscription and validate it's active.
        
        Args:
            user: Authenticated user
            
        Returns:
            UserSubscription object
            
        Raises:
            HTTPException: If subscription not found or inactive
        """
        try:
            subscription = await self.supabase_client.get_user_subscription(user.user_id)
            
            if not subscription:
                logger.error(f"Subscription not found for user {user.user_id}")
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User subscription not found"
                )
            
            logger.info(f"Subscription found for user {user.user_id}, plan: {subscription.plan.value}, status: {subscription.status.value}")
            
            # Check if subscription is active
            if not self.subscription_service.check_subscription_active(subscription):
                logger.warning(f"Subscription inactive for user {user.user_id}, status: {subscription.status.value}")
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "detail": "Your subscription is not active",
                        "error_code": "SUBSCRIPTION_INACTIVE",
                        "subscription_status": subscription.status.value
                    }
                )
            
            # Check if monthly reset is needed
            if self.subscription_service.needs_monthly_reset(subscription):
                logger.info(f"Resetting monthly counter for user {user.user_id}")
                await self.supabase_client.reset_monthly_story_count(user.user_id)
                # Reload subscription to get updated counter
                subscription = await self.supabase_client.get_user_subscription(user.user_id)
            
            return subscription
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error validating subscription: {str(e)}", exc_info=True)
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Error validating subscription"
            )
    
    async def validate_story_generation(
        self,
        user: AuthUser,
        story_type: str,
        story_length: int,
        generate_audio: bool
    ) -> UserSubscription:
        """
        Validate story generation request against subscription limits.
        
        Args:
            user: Authenticated user
            story_type: Type of story (child, hero, combined)
            story_length: Requested story length in minutes
            generate_audio: Whether audio generation is requested
            
        Returns:
            UserSubscription object if all validations pass
            
        Raises:
            HTTPException: If any limit is exceeded
        """
        logger.info(f"Validating story generation for user {user.user_id}: type={story_type}, length={story_length}, audio={generate_audio}")
        subscription = await self.get_and_validate_subscription(user)
        
        # Check monthly story limit
        logger.debug(f"Checking monthly story limit: {subscription.monthly_story_count} stories used")
        within_limit, error_msg = self.subscription_service.check_story_limit(subscription)
        if not within_limit:
            logger.warning(f"Monthly limit exceeded for user {user.user_id}")
            limits = self.subscription_service.get_plan_limits(subscription.plan)
            next_reset = self.subscription_service.needs_monthly_reset(subscription)
            
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={
                    "detail": error_msg,
                    "error_code": "MONTHLY_LIMIT_EXCEEDED",
                    "limit_info": {
                        "current_plan": subscription.plan.value,
                        "monthly_limit": limits.monthly_stories,
                        "stories_used": subscription.monthly_story_count,
                        "reset_date": self._get_reset_date().isoformat()
                    }
                }
            )
        
        logger.debug(f"Monthly limit check passed")
        
        # Check story type allowed
        logger.debug(f"Checking story type allowed: {story_type}")
        type_allowed, error_msg = self.subscription_service.check_story_type_allowed(
            subscription, story_type
        )
        if not type_allowed:
            logger.warning(f"Story type {story_type} not allowed for user {user.user_id} with plan {subscription.plan.value}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "detail": error_msg,
                    "error_code": "STORY_TYPE_NOT_ALLOWED",
                    "current_plan": subscription.plan.value,
                    "story_type": story_type
                }
            )
        
        logger.debug(f"Story type check passed")
        
        # Check story length
        logger.debug(f"Checking story length: {story_length} minutes")
        length_valid, error_msg = self.subscription_service.check_story_length(
            subscription, story_length
        )
        if not length_valid:
            logger.warning(f"Story length {story_length} exceeds limit for user {user.user_id}")
            limits = self.subscription_service.get_plan_limits(subscription.plan)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "detail": error_msg,
                    "error_code": "STORY_LENGTH_EXCEEDED",
                    "current_plan": subscription.plan.value,
                    "max_length": limits.max_story_length,
                    "requested_length": story_length
                }
            )
        
        logger.debug(f"Story length check passed")
        
        # Check audio generation allowed
        if generate_audio:
            logger.debug(f"Checking audio generation allowed")
            audio_allowed, error_msg = self.subscription_service.check_audio_allowed(subscription)
            if not audio_allowed:
                logger.warning(f"Audio generation not allowed for user {user.user_id} with plan {subscription.plan.value}")
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail={
                        "detail": error_msg,
                        "error_code": "AUDIO_NOT_ALLOWED",
                        "current_plan": subscription.plan.value
                    }
                )
            logger.debug(f"Audio generation check passed")
        
        logger.info(f"All validation checks passed for user {user.user_id}")
        return subscription
    
    async def validate_child_creation(
        self,
        user: AuthUser
    ) -> UserSubscription:
        """
        Validate child profile creation request against subscription limits.
        
        Args:
            user: Authenticated user
            
        Returns:
            UserSubscription object if validation passes
            
        Raises:
            HTTPException: If child limit is exceeded
        """
        subscription = await self.get_and_validate_subscription(user)
        
        # Count existing children
        child_count = await self.supabase_client.count_user_children(user.user_id)
        
        # Check child limit
        can_create, error_msg = self.subscription_service.check_child_limit(
            subscription, child_count
        )
        if not can_create:
            limits = self.subscription_service.get_plan_limits(subscription.plan)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "detail": error_msg,
                    "error_code": "CHILD_LIMIT_EXCEEDED",
                    "limit_info": {
                        "current_plan": subscription.plan.value,
                        "child_limit": limits.child_profiles,
                        "children_count": child_count
                    }
                }
            )
        
        return subscription
    
    def _get_reset_date(self):
        """Calculate next monthly reset date."""
        from datetime import datetime
        current_date = datetime.now()
        if current_date.month == 12:
            return datetime(current_date.year + 1, 1, 1)
        else:
            return datetime(current_date.year, current_date.month + 1, 1)


# Dependency for FastAPI
def get_subscription_validator() -> SubscriptionValidator:
    """Dependency to get SubscriptionValidator instance."""
    return SubscriptionValidator()
