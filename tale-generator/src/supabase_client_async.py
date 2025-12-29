"""Async wrapper for Supabase client for story storage."""

import asyncio
import logging
from typing import List, Optional, Dict, Any
from src.supabase_client import SupabaseClient
from src.models import StoryDB, ChildDB, HeroDB
from src.infrastructure.persistence.models import GenerationDB, FreeStoryDB
from src.domain.services.subscription_service import UserSubscription

# Set up logger
logger = logging.getLogger("tale_generator.supabase_async")


class AsyncSupabaseClient:
    """Async wrapper for SupabaseClient using asyncio.to_thread for I/O operations."""

    def __init__(self):
        """Initialize the async Supabase client wrapper."""
        self._sync_client = SupabaseClient()
        logger.info("Async Supabase client wrapper initialized")
    
    # Audio file operations
    async def upload_audio_file(self, file_data: bytes, filename: str, story_id: str) -> Optional[str]:
        """Upload an audio file to Supabase storage asynchronously."""
        return await asyncio.to_thread(
            self._sync_client.upload_audio_file,
            file_data,
            filename,
            story_id
        )
    
    async def get_audio_file_url(self, story_id: str, filename: str) -> Optional[str]:
        """Get the public URL for an audio file asynchronously."""
        return await asyncio.to_thread(
            self._sync_client.get_audio_file_url,
            story_id,
            filename
        )
    
    # Child operations
    async def save_child(self, child: ChildDB) -> ChildDB:
        """Save a child to the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.save_child, child)
    
    async def get_child(self, child_id: str, user_id: Optional[str] = None) -> Optional[ChildDB]:
        """Retrieve a child by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_child, child_id, user_id)
    
    async def get_all_children(self, user_id: Optional[str] = None) -> List[ChildDB]:
        """Retrieve all children asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_all_children, user_id)
    
    async def delete_child(self, child_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a child by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.delete_child, child_id, user_id)
    
    # Hero operations
    async def save_hero(self, hero: HeroDB) -> HeroDB:
        """Save a hero to the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.save_hero, hero)
    
    async def get_hero(self, hero_id: str) -> Optional[HeroDB]:
        """Retrieve a hero by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_hero, hero_id)
    
    async def get_all_heroes(self, user_id: Optional[str] = None) -> List[HeroDB]:
        """Retrieve all heroes asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_all_heroes, user_id)
    
    async def update_hero(self, hero: HeroDB, user_id: Optional[str] = None) -> HeroDB:
        """Update a hero in the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_hero, hero, user_id)
    
    async def delete_hero(self, hero_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a hero by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.delete_hero, hero_id, user_id)
    
    # Story operations
    async def save_story(self, story: StoryDB) -> StoryDB:
        """Save a story to the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.save_story, story)
    
    async def get_story(self, story_id: str, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Retrieve a story by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_story, story_id, user_id)
    
    async def get_stories_by_child(self, child_name: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific child asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_stories_by_child, child_name, user_id)
    
    async def get_stories_by_child_id(self, child_id: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific child by child ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_stories_by_child_id, child_id, user_id)
    
    async def get_all_stories(self, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_all_stories, user_id)
    
    async def get_stories_by_language(self, language: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific language asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_stories_by_language, language, user_id)
    
    async def update_story_rating(self, story_id: str, rating: int, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Update the rating of a story asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_story_rating, story_id, rating, user_id)
    
    async def update_story_status(self, story_id: str, status: str, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Update the status of a story asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_story_status, story_id, status, user_id)
    
    async def update_story_audio(
        self,
        story_id: str,
        audio_file_url: str,
        audio_provider: Optional[str] = None,
        audio_metadata: Optional[dict] = None,
        user_id: Optional[str] = None
    ) -> Optional[StoryDB]:
        """Update the audio information of a story asynchronously."""
        return await asyncio.to_thread(
            self._sync_client.update_story_audio,
            story_id,
            audio_file_url,
            audio_provider,
            audio_metadata,
            user_id
        )
    
    async def delete_story(self, story_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a story by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.delete_story, story_id, user_id)
    
    # Generation operations
    async def create_generation(self, generation: GenerationDB) -> GenerationDB:
        """Create a new generation record asynchronously."""
        return await asyncio.to_thread(self._sync_client.create_generation, generation)
    
    async def update_generation(self, generation: GenerationDB) -> GenerationDB:
        """Update an existing generation record asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_generation, generation)
    
    async def get_generation(self, generation_id: str, attempt_number: int) -> Optional[GenerationDB]:
        """Get a specific generation attempt asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_generation, generation_id, attempt_number)
    
    async def get_latest_attempt(self, generation_id: str) -> Optional[GenerationDB]:
        """Get the latest attempt for a generation asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_latest_attempt, generation_id)
    
    async def get_all_attempts(self, generation_id: str) -> List[GenerationDB]:
        """Get all attempts for a generation asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_all_attempts, generation_id)
    
    async def get_user_generations(self, user_id: str, limit: int = 50) -> List[GenerationDB]:
        """Get all generations for a user asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_user_generations, user_id, limit)
    
    async def get_generations_by_status(self, status: str, limit: int = 50) -> List[GenerationDB]:
        """Get generations by status asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_generations_by_status, status, limit)
    
    async def get_all_generations(
        self, 
        limit: int = 100, 
        status: Optional[str] = None,
        model_used: Optional[str] = None,
        story_type: Optional[str] = None
    ) -> List[GenerationDB]:
        """Get all generations with optional filters asynchronously."""
        return await asyncio.to_thread(
            self._sync_client.get_all_generations, 
            limit, 
            status, 
            model_used, 
            story_type
        )
    
    # Subscription and Usage Tracking Methods
    
    async def increment_story_count(self, user_id: str) -> None:
        """Increment monthly story count for a user asynchronously."""
        return await asyncio.to_thread(self._sync_client.increment_story_count, user_id)
    
    async def track_usage(self, user_id: str, action_type: str, resource_id: Optional[str] = None, metadata: Optional[dict] = None) -> None:
        """Track user action in usage_tracking table asynchronously."""
        return await asyncio.to_thread(self._sync_client.track_usage, user_id, action_type, resource_id, metadata)
    
    async def get_user_subscription(self, user_id: str) -> Optional[UserSubscription]:
        """Get user subscription information asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_user_subscription, user_id)
    
    async def reset_monthly_story_count(self, user_id: str) -> None:
        """Reset monthly story count for a user asynchronously."""
        return await asyncio.to_thread(self._sync_client.reset_monthly_story_count, user_id)
    
    async def count_user_children(self, user_id: str) -> int:
        """Count the number of child profiles for a user asynchronously."""
        return await asyncio.to_thread(self._sync_client.count_user_children, user_id)
    
    # Purchase transaction methods
    
    async def create_purchase_transaction(self, transaction_data: dict) -> dict:
        """Create a new purchase transaction record asynchronously."""
        return await asyncio.to_thread(self._sync_client.create_purchase_transaction, transaction_data)
    
    async def get_purchase_transaction(self, transaction_id: str, user_id: str) -> Optional[dict]:
        """Get a purchase transaction by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_purchase_transaction, transaction_id, user_id)
    
    async def get_user_purchase_history(
        self,
        user_id: str,
        status: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> dict:
        """Get purchase transaction history for a user asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_user_purchase_history, user_id, status, limit, offset)
    
    async def update_subscription_plan(
        self,
        user_id: str,
        plan: str,
        start_date,
        end_date = None
    ) -> dict:
        """Update user subscription plan asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_subscription_plan, user_id, plan, start_date, end_date)
    
    # Free stories operations
    async def get_free_stories(
        self,
        age_category: Optional[str] = None,
        language: Optional[str] = None,
        limit: Optional[int] = None
    ) -> List[FreeStoryDB]:
        """Get active free stories asynchronously."""
        return await asyncio.to_thread(
            self._sync_client.get_free_stories,
            age_category,
            language,
            limit
        )
    
    async def get_free_story(self, story_id: str) -> Optional[FreeStoryDB]:
        """Get a free story by ID asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_free_story, story_id)
    
    # Prompt operations
    async def get_prompts(self, language: str, story_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get prompts from the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.get_prompts, language, story_type)
    
    async def create_prompt(self, prompt_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new prompt in the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.create_prompt, prompt_data)
    
    async def update_prompt(self, prompt_id: str, prompt_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update an existing prompt in the database asynchronously."""
        return await asyncio.to_thread(self._sync_client.update_prompt, prompt_id, prompt_data)