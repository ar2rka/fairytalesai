"""API routes for the tale generator service."""

import logging
import uuid
from fastapi import APIRouter, HTTPException, Depends
from typing import Optional, List
from datetime import datetime

from src.models import StoryDB
from src.application.dto import (
    GenerateStoryRequestDTO, 
    GenerateStoryResponseDTO,
    FreeStoryResponseDTO,
    DailyFreeStoryResponseDTO,
    DailyStoryReactionRequestDTO,
    DailyStoryReactionResponseDTO
)
from src.api.auth import get_current_user, AuthUser, get_optional_user
from src.api.subscription_validator import SubscriptionValidator
from src.domain.services.subscription_service import SubscriptionService
from src.domain.value_objects import Language, StoryLength

# Import helpers
from src.api.helpers.services import (
    initialize_openrouter_client,
    initialize_supabase_client,
    initialize_voice_service,
    initialize_prompt_service
)
from src.api.helpers.validators import (
    validate_language,
    validate_story_type,
    validate_services
)
from src.api.helpers.entities import (
    fetch_and_convert_child,
    fetch_and_convert_hero
)
from src.api.helpers.story_generation import (
    determine_moral,
    generate_prompt,
    create_generation_record,
    generate_story_content,
    clean_story_content,
    extract_title,
    generate_summary
)
from src.api.helpers.audio import generate_audio
from src.api.helpers.responses import (
    generate_relationship_description,
    save_story,
    build_response
)

# Set up logger
logger = logging.getLogger("tale_generator.api")

router = APIRouter()


# ============================================================================
# SERVICE INITIALIZATION
# ============================================================================

# Initialize services
openrouter_client = initialize_openrouter_client()
supabase_client = initialize_supabase_client()
voice_service = initialize_voice_service()
prompt_service = initialize_prompt_service(supabase_client)


# ============================================================================
# API ENDPOINTS
# ============================================================================

@router.post("/stories/generate", response_model=GenerateStoryResponseDTO)
async def generate_story(
    request: GenerateStoryRequestDTO,
    user: AuthUser = Depends(get_current_user)
):
    """Generate a bedtime story with support for child, hero, and combined types."""
    try:
        # Initialize subscription validator
        subscription_validator = SubscriptionValidator()
        
        # Validate subscription and limits BEFORE processing
        subscription = await subscription_validator.validate_story_generation(
            user=user,
            story_type=request.story_type,
            story_length=request.story_length or 5,
            generate_audio=request.generate_audio or False
        )
        
        logger.info(f"Subscription validated for user {user.user_id}, plan: {subscription.plan.value}")
        
        # Validate services
        validate_services(openrouter_client, supabase_client)
        
        # Validate request
        language = validate_language(request.language)
        validate_story_type(request.story_type, request.hero_id)
        
        # Fetch and convert entities
        child = await fetch_and_convert_child(request.child_id, user.user_id, supabase_client)
        
        hero = None
        if request.story_type in ["hero", "combined"]:
            hero = await fetch_and_convert_hero(request.hero_id, language, supabase_client)
        
        # Determine story parameters
        moral = determine_moral(request)
        story_length = StoryLength(minutes=request.story_length or 5)
        
        logger.debug(f"Using moral: {moral}")
        
        # Fetch parent story if parent_id is provided
        parent_story = None
        if request.parent_id:
            parent_story = await supabase_client.get_story(request.parent_id, user.user_id)
            if not parent_story:
                raise HTTPException(
                    status_code=404,
                    detail=f"Parent story with ID {request.parent_id} not found or access denied"
                )
            logger.info(f"Using parent story: {parent_story.title} (ID: {parent_story.id})")
        
        # Generate prompt
        prompt = generate_prompt(
            request.story_type,
            child,
            hero,
            moral,
            language,
            story_length,
            prompt_service,
            parent_story
        )
        
        # Generate story content
        generation_id = str(uuid.uuid4())
        logger.info(f"Created generation ID: {generation_id}")

        await create_generation_record(
            generation_id=generation_id,
            user_id=user.user_id,
            story_type=request.story_type,
            story_length=story_length.minutes,
            hero=hero,
            moral=moral,
            prompt=prompt,
            supabase_client=supabase_client
        )
        
        result = await generate_story_content(
            prompt=prompt,
            generation_id=generation_id,
            user_id=user.user_id,
            story_type=request.story_type,
            story_length=story_length.minutes,
            hero=hero,
            moral=moral,
            child=child,
            language=language,
            openrouter_client=openrouter_client,
            supabase_client=supabase_client
        )
        
        # Clean the content to remove formatting markers
        cleaned_content = clean_story_content(result.content)
        
        # Use title from result if available and not empty, otherwise extract from content
        result_title = getattr(result, 'title', None)
        title = result_title if result_title else extract_title(cleaned_content)
        
        # Generate summary
        summary = await generate_summary(cleaned_content, title, language, openrouter_client)
        
        # Generate relationship description
        relationship_description = generate_relationship_description(
            request.story_type,
            child,
            hero,
            language
        )
        
        # Save story to database first (to get story_id)
        now = datetime.now()
        saved_story = await save_story(
            title=title,
            content=cleaned_content,
            summary=summary,
            generation_id=generation_id,
            moral=moral,
            child=child,
            hero=hero,
            language=language,
            audio_file_url=None,  # Will be updated after audio generation
            user_id=user.user_id,
            supabase_client=supabase_client,
            parent_id=request.parent_id
        )
        
        # Get story ID (fallback to uuid if save failed)
        story_id = saved_story.id if saved_story else str(uuid.uuid4())
        
        # Generate audio if requested (now we have story_id)
        audio_file_url, audio_provider, audio_metadata = None, None, None
        if request.generate_audio:
            audio_file_url, audio_provider, audio_metadata = await generate_audio(
                content=cleaned_content,
                language=language.value,
                provider_name=request.voice_provider,
                voice_options=request.voice_options,
                story_id=story_id,
                voice_service=voice_service,
                supabase_client=supabase_client
            )
            
            # Update story with audio URL if generation was successful
            if audio_file_url and saved_story:
                try:
                    await supabase_client.update_story_audio(
                        story_id=story_id,
                        audio_file_url=audio_file_url,
                        audio_provider=audio_provider,
                        audio_metadata=audio_metadata
                    )
                    logger.info(f"Story {story_id} updated with audio URL")
                except Exception as audio_update_error:
                    logger.warning(f"Failed to update story with audio URL: {str(audio_update_error)}")
        
        # Increment story count and track usage AFTER successful generation
        try:
            await supabase_client.increment_story_count(user.user_id)
            await supabase_client.track_usage(
                user_id=user.user_id,
                action_type='story_generation',
                resource_id=story_id,
                metadata={
                    'plan': subscription.plan.value,
                    'story_type': request.story_type,
                    'story_length': story_length.minutes,
                    'audio_generated': request.generate_audio or False
                }
            )
            logger.info(f"Usage tracked for user {user.user_id}, story {story_id}")
        except Exception as tracking_error:
            # Don't fail the request if tracking fails, just log it
            logger.warning(f"Failed to track usage: {str(tracking_error)}")
        
        logger.info(f"Story generation completed successfully for {request.story_type} story")
        
        return build_response(
            story_id=story_id,
            title=title,
            content=cleaned_content,
            moral=moral,
            language=language,
            story_type=request.story_type,
            story_length=story_length.minutes,
            child=child,
            hero=hero,
            relationship_description=relationship_description,
            audio_file_url=audio_file_url,
            created_at=now
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generating story: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error generating story: {str(e)}"
        )


@router.get("/users/subscription")
async def get_user_subscription(
    user: AuthUser = Depends(get_current_user)
):
    """Get current user's subscription information and usage statistics."""
    try:
        # Initialize services
        subscription_validator = SubscriptionValidator()
        subscription_service = SubscriptionService()
        
        # Get subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        
        if not subscription:
            logger.warning(f"Subscription not found for user {user.user_id}")
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Check if monthly reset is needed
        if subscription_service.needs_monthly_reset(subscription):
            logger.info(f"Resetting monthly counter for user {user.user_id}")
            await supabase_client.reset_monthly_story_count(user.user_id)
            # Reload subscription to get updated counter
            subscription = await supabase_client.get_user_subscription(user.user_id)
        
        # Get child count
        child_count = await supabase_client.count_user_children(user.user_id)
        
        # Build response with full subscription info
        subscription_info = subscription_service.get_subscription_info(
            subscription=subscription,
            child_count=child_count
        )
        
        logger.info(f"Subscription info retrieved for user {user.user_id}")
        return subscription_info
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting subscription info: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting subscription info: {str(e)}"
        )


# ============================================================================
# PURCHASE & PLAN ENDPOINTS
# ============================================================================

@router.get("/subscription/plans")
async def get_available_plans(
    user: AuthUser = Depends(get_current_user)
):
    """Get all available subscription plans with pricing and features."""
    try:
        from src.domain.services.plan_catalog import PlanCatalog
        
        # Get user's current subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        
        if not subscription:
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Get all plan definitions
        all_plans = PlanCatalog.get_all_plans()
        
        # Convert to API response format
        plans_list = []
        for plan_tier, plan_def in all_plans.items():
            plans_list.append({
                "tier": plan_tier.value,
                "display_name": plan_def.display_name,
                "description": plan_def.description,
                "monthly_price": float(plan_def.monthly_price),
                "annual_price": float(plan_def.annual_price),
                "features": plan_def.features,
                "limits": {
                    "monthly_stories": plan_def.limits.monthly_stories,
                    "child_profiles": plan_def.limits.child_profiles,
                    "max_story_length": plan_def.limits.max_story_length,
                    "audio_enabled": plan_def.limits.audio_enabled,
                    "hero_stories_enabled": plan_def.limits.hero_stories_enabled,
                    "combined_stories_enabled": plan_def.limits.combined_stories_enabled,
                    "priority_support": plan_def.limits.priority_support,
                },
                "is_purchasable": plan_def.is_purchasable,
                "is_current": plan_tier == subscription.plan,
            })
        
        logger.info(f"Retrieved {len(plans_list)} plans for user {user.user_id}")
        return {
            "plans": plans_list,
            "current_plan": subscription.plan.value
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting available plans: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting available plans: {str(e)}"
        )


@router.post("/subscription/purchase")
async def purchase_subscription(
    plan_tier: str,
    billing_cycle: str,
    payment_method: str,
    user: AuthUser = Depends(get_current_user)
):
    """Purchase a subscription plan upgrade."""
    try:
        from src.domain.services.plan_catalog import BillingCycle, PlanCatalog
        from src.domain.services.purchase_service import PurchaseService
        from src.domain.services.payment_provider import MockPaymentProvider
        from src.domain.services.subscription_service import SubscriptionPlan
        
        logger.info(
            f"Purchase request: user={user.user_id}, "
            f"plan={plan_tier}, cycle={billing_cycle}, method={payment_method}"
        )
        
        # Validate inputs
        try:
            target_plan = SubscriptionPlan(plan_tier)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid plan tier: {plan_tier}"
            )
        
        try:
            cycle = BillingCycle(billing_cycle)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid billing cycle: {billing_cycle}. Must be 'monthly' or 'annual'"
            )
        
        # Get current subscription
        subscription = await supabase_client.get_user_subscription(user.user_id)
        if not subscription:
            raise HTTPException(
                status_code=404,
                detail="User subscription not found"
            )
        
        # Initialize purchase service with mock payment provider
        payment_provider = MockPaymentProvider()
        purchase_service = PurchaseService(payment_provider)
        
        # Initiate purchase
        success, transaction, error_msg = purchase_service.initiate_purchase(
            user_id=user.user_id,
            current_subscription=subscription,
            target_plan=target_plan,
            billing_cycle=cycle,
            payment_method=payment_method
        )
        
        if not success:
            # Save failed transaction to database
            if transaction:
                await supabase_client.create_purchase_transaction({
                    "user_id": transaction.user_id,
                    "from_plan": transaction.from_plan,
                    "to_plan": transaction.to_plan,
                    "amount": float(transaction.amount),
                    "currency": transaction.currency,
                    "payment_status": transaction.payment_status,
                    "payment_method": transaction.payment_method,
                    "payment_provider": transaction.payment_provider,
                    "transaction_reference": transaction.transaction_reference,
                    "metadata": transaction.metadata
                })
            
            logger.warning(f"Purchase failed for user {user.user_id}: {error_msg}")
            raise HTTPException(
                status_code=402,
                detail=error_msg or "Payment processing failed"
            )
        
        # Save successful transaction to database
        saved_transaction = await supabase_client.create_purchase_transaction({
            "user_id": transaction.user_id,
            "from_plan": transaction.from_plan,
            "to_plan": transaction.to_plan,
            "amount": float(transaction.amount),
            "currency": transaction.currency,
            "payment_status": transaction.payment_status,
            "payment_method": transaction.payment_method,
            "payment_provider": transaction.payment_provider,
            "transaction_reference": transaction.transaction_reference,
            "completed_at": transaction.completed_at.isoformat() if transaction.completed_at else None,
            "metadata": transaction.metadata
        })
        
        # Update user subscription
        updated_subscription = purchase_service.create_updated_subscription(
            current_subscription=subscription,
            new_plan=target_plan,
            billing_cycle=cycle
        )
        
        await supabase_client.update_subscription_plan(
            user_id=user.user_id,
            plan=updated_subscription.plan.value,
            start_date=updated_subscription.start_date,
            end_date=updated_subscription.end_date
        )
        
        logger.info(
            f"Purchase successful: user={user.user_id}, "
            f"transaction={saved_transaction['id']}, "
            f"new_plan={target_plan.value}"
        )
        
        # Return success response
        return {
            "success": True,
            "transaction_id": saved_transaction['id'],
            "subscription": {
                "plan": updated_subscription.plan.value,
                "status": updated_subscription.status.value,
                "start_date": updated_subscription.start_date.isoformat(),
                "end_date": updated_subscription.end_date.isoformat() if updated_subscription.end_date else None,
            },
            "message": f"Successfully upgraded to {target_plan.value} plan"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing purchase: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error processing purchase: {str(e)}"
        )


@router.get("/subscription/purchases")
async def get_purchase_history(
    status: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    user: AuthUser = Depends(get_current_user)
):
    """Get user's purchase transaction history."""
    try:
        # Validate limit
        if limit > 100:
            limit = 100
        if limit < 1:
            limit = 10
        
        # Validate offset
        if offset < 0:
            offset = 0
        
        # Validate status if provided
        if status and status not in ['pending', 'completed', 'failed', 'refunded']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {status}"
            )
        
        # Get purchase history
        history = await supabase_client.get_user_purchase_history(
            user_id=user.user_id,
            status=status,
            limit=limit,
            offset=offset
        )
        
        logger.info(
            f"Retrieved {len(history['transactions'])} transactions for user {user.user_id}"
        )
        
        return history
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting purchase history: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting purchase history: {str(e)}"
        )


@router.get("/admin/generations/test")
async def test_generations_access(
    user: AuthUser = Depends(get_current_user)
):
    """Test endpoint to check if we can access generations table."""
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Try a simple query to test access
        logger.info("Testing generations table access...")
        test_result = await supabase_client.get_all_generations(limit=1)
        
        return {
            "success": True,
            "message": "Access to generations table is working",
            "count": len(test_result),
            "sample": test_result[0].model_dump() if test_result else None
        }
    except Exception as e:
        logger.error(f"Test failed: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__
        }


@router.get("/admin/generations/{generation_id}/test")
async def test_generation_detail(
    generation_id: str,
    user: AuthUser = Depends(get_current_user)
):
    """Test endpoint to check if we can access a specific generation."""
    try:
        logger.info(f"Testing generation detail access for ID: {generation_id}")
        
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Test get_all_attempts
        logger.info("Testing get_all_attempts...")
        all_attempts = await supabase_client.get_all_attempts(generation_id)
        
        # Test get_latest_attempt
        logger.info("Testing get_latest_attempt...")
        latest_attempt = await supabase_client.get_latest_attempt(generation_id)
        
        return {
            "success": True,
            "generation_id": generation_id,
            "all_attempts_count": len(all_attempts),
            "latest_attempt": latest_attempt.model_dump() if latest_attempt else None,
            "all_attempts": [attempt.model_dump() for attempt in all_attempts]
        }
    except Exception as e:
        logger.error(f"Test failed: {str(e)}", exc_info=True)
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__,
            "generation_id": generation_id
        }


@router.get("/admin/generations")
async def get_generations(
    limit: int = 100,
    status: Optional[str] = None,
    model_used: Optional[str] = None,
    story_type: Optional[str] = None,
    user: AuthUser = Depends(get_current_user)
):
    """Get all generations with optional filters (admin endpoint)."""
    try:
        # Validate services
        if supabase_client is None:
            logger.error("Supabase not configured")
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured"
            )
        
        # Validate limit
        if limit > 500:
            limit = 500
        if limit < 1:
            limit = 50
        
        # Validate status if provided
        if status and status not in ['pending', 'success', 'failed', 'timeout']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {status}. Must be one of: pending, success, failed, timeout"
            )
        
        # Validate story_type if provided
        if story_type and story_type not in ['child', 'hero', 'combined']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid story_type: {story_type}. Must be one of: child, hero, combined"
            )
        
        # Get generations
        logger.info(f"Fetching generations with filters: limit={limit}, status={status}, model={model_used}, story_type={story_type}")
        generations = await supabase_client.get_all_generations(
            limit=limit,
            status=status,
            model_used=model_used,
            story_type=story_type
        )
        
        logger.info(f"Retrieved {len(generations)} generations from database")
        
        # Convert to dict format for JSON response
        generations_list = []
        for gen in generations:
            try:
                gen_dict = gen.model_dump()
                # Convert datetime to ISO format strings
                if gen_dict.get('created_at'):
                    gen_dict['created_at'] = gen_dict['created_at'].isoformat() if hasattr(gen_dict['created_at'], 'isoformat') else str(gen_dict['created_at'])
                if gen_dict.get('completed_at'):
                    gen_dict['completed_at'] = gen_dict['completed_at'].isoformat() if hasattr(gen_dict['completed_at'], 'isoformat') else str(gen_dict['completed_at'])
                generations_list.append(gen_dict)
            except Exception as e:
                logger.error(f"Error converting generation to dict: {str(e)}", exc_info=True)
                continue
        
        logger.info(f"Successfully converted {len(generations_list)} generations to response format")
        
        return {
            "generations": generations_list,
            "count": len(generations_list)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting generations: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting generations: {str(e)}"
        )


@router.get("/admin/generations/{generation_id}")
async def get_generation_detail(
    generation_id: str,
    user: AuthUser = Depends(get_current_user)
):
    """Get detailed information about a specific generation including all attempts (admin endpoint)."""
    try:
        logger.info(f"Fetching generation detail for ID: {generation_id}")
        
        # Validate services
        if supabase_client is None:
            logger.error("Supabase not configured")
            raise HTTPException(
                status_code=500,
                detail="Supabase not configured"
            )
        
        # Get all attempts for this generation
        logger.debug(f"Fetching all attempts for generation {generation_id}")
        all_attempts = await supabase_client.get_all_attempts(generation_id)
        logger.info(f"Retrieved {len(all_attempts)} attempts for generation {generation_id}")
        
        if not all_attempts:
            logger.warning(f"No attempts found for generation_id: {generation_id}")
            raise HTTPException(
                status_code=404,
                detail=f"Generation with ID {generation_id} not found"
            )
        
        # Get latest attempt
        logger.debug(f"Fetching latest attempt for generation {generation_id}")
        latest_attempt = await supabase_client.get_latest_attempt(generation_id)
        logger.info(f"Latest attempt retrieved: {latest_attempt.attempt_number if latest_attempt else 'None'}")
        
        # Convert to dict format for JSON response
        attempts_list = []
        for attempt in all_attempts:
            attempt_dict = attempt.model_dump()
            # Convert datetime to ISO format strings
            if attempt_dict.get('created_at'):
                attempt_dict['created_at'] = attempt_dict['created_at'].isoformat() if hasattr(attempt_dict['created_at'], 'isoformat') else str(attempt_dict['created_at'])
            if attempt_dict.get('completed_at'):
                attempt_dict['completed_at'] = attempt_dict['completed_at'].isoformat() if hasattr(attempt_dict['completed_at'], 'isoformat') else str(attempt_dict['completed_at'])
            attempts_list.append(attempt_dict)
        
        latest_dict = None
        if latest_attempt:
            latest_dict = latest_attempt.model_dump()
            if latest_dict.get('created_at'):
                latest_dict['created_at'] = latest_dict['created_at'].isoformat() if hasattr(latest_dict['created_at'], 'isoformat') else str(latest_dict['created_at'])
            if latest_dict.get('completed_at'):
                latest_dict['completed_at'] = latest_dict['completed_at'].isoformat() if hasattr(latest_dict['completed_at'], 'isoformat') else str(latest_dict['completed_at'])
        
        logger.info(f"Retrieved generation detail for {generation_id} with {len(attempts_list)} attempts")
        
        return {
            "generation_id": generation_id,
            "latest_attempt": latest_dict,
            "all_attempts": attempts_list,
            "total_attempts": len(attempts_list)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting generation detail: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error getting generation detail: {str(e)}"
        )


# ============================================================================
# FREE STORIES ENDPOINTS
# ============================================================================

@router.get("/free-stories", response_model=List[FreeStoryResponseDTO])
async def get_free_stories(
    age_category: Optional[str] = None,
    language: Optional[str] = None,
    limit: Optional[int] = None
):
    """Get active free stories, optionally filtered by age category and language.
    
    This endpoint is publicly accessible and requires no authentication.
    Stories are sorted by creation date in descending order (newest first).
    
    Args:
        age_category: Optional age category filter ('2-3', '3-5', '5-7')
        language: Optional language filter ('en', 'ru')
        limit: Optional limit on number of results
        
    Returns:
        List of active free stories
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Validate and normalize age_category if provided
        if age_category:
            try:
                from src.utils.age_category_utils import normalize_age_category
                age_category = normalize_age_category(age_category)
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid age_category: {str(e)}"
                )
        
        # Validate language if provided
        if language and language not in ['en', 'ru']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language: {language}. Must be one of: 'en', 'ru'"
            )
        
        # Validate limit if provided
        if limit is not None and (limit < 1 or limit > 1000):
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 1000"
            )
        
        # Get free stories from database
        free_stories = await supabase_client.get_free_stories(
            age_category=age_category,
            language=language,
            limit=limit
        )
        
        # Convert to response DTOs
        response_stories = []
        for story in free_stories:
            if not story.id or not story.created_at:
                continue  # Skip stories without ID or created_at
            response_stories.append(FreeStoryResponseDTO(
                id=story.id,
                title=story.title,
                content=story.content,
                age_category=story.age_category,
                language=story.language,
                created_at=story.created_at.isoformat()
            ))
        
        logger.info(f"Retrieved {len(response_stories)} free stories (age_category={age_category}, language={language}, limit={limit})")
        
        return response_stories
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving free stories: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving free stories: {str(e)}"
        )


# ============================================================================
# DAILY FREE STORIES ENDPOINTS
# ============================================================================

@router.get("/daily-stories", response_model=List[DailyFreeStoryResponseDTO])
async def get_daily_stories(
    age_category: Optional[str] = None,
    language: Optional[str] = None,
    limit: Optional[int] = None,
    user: Optional[AuthUser] = Depends(get_optional_user)
):
    """Get active daily free stories, optionally filtered by age category and language.
    
    This endpoint is publicly accessible but can optionally use authentication
    to show user's reactions. Stories are sorted by story_date DESC (newest first).
    
    Args:
        age_category: Optional age category filter ('2-3', '3-5', '5-7')
        language: Optional language filter ('en', 'ru')
        limit: Optional limit on number of results
        user: Optional authenticated user (for showing user's reactions)
        
    Returns:
        List of active daily free stories with reaction counts
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Validate and normalize age_category if provided
        if age_category:
            try:
                from src.utils.age_category_utils import normalize_age_category
                age_category = normalize_age_category(age_category)
            except ValueError as e:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid age_category: {str(e)}"
                )
        
        # Validate language if provided
        if language and language not in ['en', 'ru']:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language: {language}. Must be one of: 'en', 'ru'"
            )
        
        # Validate limit if provided
        if limit is not None and (limit < 1 or limit > 1000):
            raise HTTPException(
                status_code=400,
                detail="Limit must be between 1 and 1000"
            )
        
        # Get user_id if authenticated
        user_id = user.user_id if user else None
        
        # Import use case
        from src.application.use_cases.manage_daily_stories import GetDailyStoriesUseCase
        
        # Create use case and execute
        use_case = GetDailyStoriesUseCase(supabase_client)
        daily_stories = await use_case.execute(
            age_category=age_category,
            language=language,
            limit=limit,
            user_id=user_id
        )
        
        logger.info(f"Retrieved {len(daily_stories)} daily free stories (age_category={age_category}, language={language}, limit={limit})")
        
        return daily_stories
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving daily free stories: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving daily free stories: {str(e)}"
        )


@router.get("/daily-stories/date/{story_date}", response_model=DailyFreeStoryResponseDTO)
async def get_daily_story_by_date(
    story_date: str,
    user: Optional[AuthUser] = Depends(get_optional_user)
):
    """Get a daily free story by date.
    
    This endpoint is publicly accessible but can optionally use authentication
    to show user's reactions.
    
    Args:
        story_date: Date in YYYY-MM-DD format
        user: Optional authenticated user (for showing user's reactions)
        
    Returns:
        Daily free story with reaction counts
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Validate date format
        try:
            datetime.strptime(story_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid date format: {story_date}. Expected YYYY-MM-DD"
            )
        
        # Get user_id if authenticated
        user_id = user.user_id if user else None
        
        # Import use case
        from src.application.use_cases.manage_daily_stories import GetDailyStoryByDateUseCase
        from src.core.exceptions import NotFoundError
        
        # Create use case and execute
        use_case = GetDailyStoryByDateUseCase(supabase_client)
        try:
            daily_story = await use_case.execute(story_date=story_date, user_id=user_id)
            logger.info(f"Retrieved daily free story for date: {story_date}")
            return daily_story
        except NotFoundError as e:
            raise HTTPException(status_code=404, detail=str(e))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving daily free story by date: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving daily free story by date: {str(e)}"
        )


@router.get("/daily-stories/{story_id}", response_model=DailyFreeStoryResponseDTO)
async def get_daily_story_by_id(
    story_id: str,
    user: Optional[AuthUser] = Depends(get_optional_user)
):
    """Get a daily free story by ID.
    
    This endpoint is publicly accessible but can optionally use authentication
    to show user's reactions.
    
    Args:
        story_id: Story ID
        user: Optional authenticated user (for showing user's reactions)
        
    Returns:
        Daily free story with reaction counts
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Get user_id if authenticated
        user_id = user.user_id if user else None
        
        # Import use case
        from src.application.use_cases.manage_daily_stories import GetDailyStoryByIdUseCase
        from src.core.exceptions import NotFoundError
        
        # Create use case and execute
        use_case = GetDailyStoryByIdUseCase(supabase_client)
        try:
            daily_story = await use_case.execute(story_id=story_id, user_id=user_id)
            logger.info(f"Retrieved daily free story with ID: {story_id}")
            return daily_story
        except NotFoundError as e:
            raise HTTPException(status_code=404, detail=str(e))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving daily free story by ID: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving daily free story by ID: {str(e)}"
        )


@router.post("/daily-stories/{story_id}/react", response_model=DailyStoryReactionResponseDTO)
async def react_to_daily_story(
    story_id: str,
    request: DailyStoryReactionRequestDTO,
    user: Optional[AuthUser] = Depends(get_optional_user)
):
    """React to a daily free story (like/dislike).
    
    This endpoint allows both authenticated and anonymous users to react.
    Anonymous users will have NULL user_id in the database.
    
    Args:
        story_id: Story ID
        request: Reaction request (like or dislike)
        user: Optional authenticated user (None for anonymous)
        
    Returns:
        Reaction response with updated counts
    """
    try:
        if supabase_client is None:
            raise HTTPException(status_code=500, detail="Supabase not configured")
        
        # Get user_id if authenticated
        user_id = user.user_id if user else None
        
        # Import use case
        from src.application.use_cases.manage_daily_stories import ReactToDailyStoryUseCase
        from src.core.exceptions import NotFoundError
        
        # Create use case and execute
        use_case = ReactToDailyStoryUseCase(supabase_client)
        try:
            reaction = await use_case.execute(
                story_id=story_id,
                request=request,
                user_id=user_id
            )
            logger.info(f"User {user_id or 'anonymous'} reacted to story {story_id} with {request.reaction_type}")
            return reaction
        except NotFoundError as e:
            raise HTTPException(status_code=404, detail=str(e))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error reacting to daily story: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Error reacting to daily story: {str(e)}"
        )