"""Daily free story management use cases."""

from typing import List, Optional
from datetime import datetime

from src.application.dto import (
    DailyFreeStoryResponseDTO,
    DailyStoryReactionRequestDTO,
    DailyStoryReactionResponseDTO
)
from src.models import DailyFreeStoryDB
from src.supabase_client_async import AsyncSupabaseClient
from src.core.logging import get_logger
from src.core.exceptions import NotFoundError

logger = get_logger("application.manage_daily_stories")


class GetDailyStoriesUseCase:
    """Use case for retrieving daily free stories."""
    
    def __init__(self, supabase_client: AsyncSupabaseClient):
        """Initialize use case.
        
        Args:
            supabase_client: Async Supabase client
        """
        self.supabase_client = supabase_client
    
    async def execute(
        self,
        age_category: Optional[str] = None,
        language: Optional[str] = None,
        limit: Optional[int] = None,
        user_id: Optional[str] = None
    ) -> List[DailyFreeStoryResponseDTO]:
        """Get daily free stories.
        
        Args:
            age_category: Optional age category filter
            language: Optional language filter
            limit: Optional limit on number of results
            user_id: Optional user ID to get user's reaction
            
        Returns:
            List of daily free story responses
        """
        logger.info(f"Retrieving daily free stories (age_category={age_category}, language={language}, limit={limit})")
        
        # Get stories from database
        stories = await self.supabase_client.get_daily_stories(
            age_category=age_category,
            language=language,
            limit=limit,
            user_id=user_id
        )
        
        # Convert to response DTOs with reaction counts
        response_stories = []
        for story in stories:
            if not story.id:
                continue
            
            # Get reaction counts
            reaction_counts = await self.supabase_client.get_reaction_counts(story.id)
            
            # Get user's reaction if user_id provided
            user_reaction = None
            if user_id:
                user_reaction = await self.supabase_client.get_user_reaction(story.id, user_id)
            
            response_stories.append(DailyFreeStoryResponseDTO(
                id=story.id,
                story_date=story.story_date,
                title=story.title,
                name=story.name,
                content=story.content,
                moral=story.moral,
                age_category=story.age_category,
                language=story.language,
                likes_count=reaction_counts.get("likes", 0),
                dislikes_count=reaction_counts.get("dislikes", 0),
                user_reaction=user_reaction,
                created_at=story.created_at.isoformat() if story.created_at else datetime.now().isoformat()
            ))
        
        logger.info(f"Retrieved {len(response_stories)} daily free stories")
        return response_stories


class GetDailyStoryByDateUseCase:
    """Use case for retrieving a daily free story by date."""
    
    def __init__(self, supabase_client: AsyncSupabaseClient):
        """Initialize use case.
        
        Args:
            supabase_client: Async Supabase client
        """
        self.supabase_client = supabase_client
    
    async def execute(
        self,
        story_date: str,
        user_id: Optional[str] = None
    ) -> DailyFreeStoryResponseDTO:
        """Get a daily free story by date.
        
        Args:
            story_date: Date in YYYY-MM-DD format
            user_id: Optional user ID to get user's reaction
            
        Returns:
            Daily free story response
            
        Raises:
            NotFoundError: If story not found
        """
        logger.info(f"Retrieving daily free story for date: {story_date}")
        
        story = await self.supabase_client.get_daily_story_by_date(story_date, user_id)
        if not story or not story.id:
            raise NotFoundError("Daily free story", story_date)
        
        # Get reaction counts
        reaction_counts = await self.supabase_client.get_reaction_counts(story.id)
        
        # Get user's reaction if user_id provided
        user_reaction = None
        if user_id:
            user_reaction = await self.supabase_client.get_user_reaction(story.id, user_id)
        
        return DailyFreeStoryResponseDTO(
            id=story.id,
            story_date=story.story_date,
            title=story.title,
            name=story.name,
            content=story.content,
            moral=story.moral,
            age_category=story.age_category,
            language=story.language,
            likes_count=reaction_counts.get("likes", 0),
            dislikes_count=reaction_counts.get("dislikes", 0),
            user_reaction=user_reaction,
            created_at=story.created_at.isoformat() if story.created_at else datetime.now().isoformat()
        )


class GetDailyStoryByIdUseCase:
    """Use case for retrieving a daily free story by ID."""
    
    def __init__(self, supabase_client: AsyncSupabaseClient):
        """Initialize use case.
        
        Args:
            supabase_client: Async Supabase client
        """
        self.supabase_client = supabase_client
    
    async def execute(
        self,
        story_id: str,
        user_id: Optional[str] = None
    ) -> DailyFreeStoryResponseDTO:
        """Get a daily free story by ID.
        
        Args:
            story_id: Story ID
            user_id: Optional user ID to get user's reaction
            
        Returns:
            Daily free story response
            
        Raises:
            NotFoundError: If story not found
        """
        logger.info(f"Retrieving daily free story with ID: {story_id}")
        
        story = await self.supabase_client.get_daily_story_by_id(story_id, user_id)
        if not story or not story.id:
            raise NotFoundError("Daily free story", story_id)
        
        # Get reaction counts
        reaction_counts = await self.supabase_client.get_reaction_counts(story.id)
        
        # Get user's reaction if user_id provided
        user_reaction = None
        if user_id:
            user_reaction = await self.supabase_client.get_user_reaction(story.id, user_id)
        
        return DailyFreeStoryResponseDTO(
            id=story.id,
            story_date=story.story_date,
            title=story.title,
            name=story.name,
            content=story.content,
            moral=story.moral,
            age_category=story.age_category,
            language=story.language,
            likes_count=reaction_counts.get("likes", 0),
            dislikes_count=reaction_counts.get("dislikes", 0),
            user_reaction=user_reaction,
            created_at=story.created_at.isoformat() if story.created_at else datetime.now().isoformat()
        )


class ReactToDailyStoryUseCase:
    """Use case for reacting to a daily free story (like/dislike)."""
    
    def __init__(self, supabase_client: AsyncSupabaseClient):
        """Initialize use case.
        
        Args:
            supabase_client: Async Supabase client
        """
        self.supabase_client = supabase_client
    
    async def execute(
        self,
        story_id: str,
        request: DailyStoryReactionRequestDTO,
        user_id: Optional[str] = None
    ) -> DailyStoryReactionResponseDTO:
        """React to a daily free story.
        
        Args:
            story_id: Story ID
            request: Reaction request
            user_id: Optional user ID (None for anonymous)
            
        Returns:
            Reaction response with updated counts
            
        Raises:
            NotFoundError: If story not found
        """
        logger.info(f"Reacting to daily story {story_id} with {request.reaction_type} (user_id={user_id})")
        
        # Verify story exists
        story = await self.supabase_client.get_daily_story_by_id(story_id)
        if not story:
            raise NotFoundError("Daily free story", story_id)
        
        # Create or update reaction
        reaction = await self.supabase_client.create_or_update_reaction(
            story_id=story_id,
            reaction_type=request.reaction_type,
            user_id=user_id
        )
        
        if not reaction:
            raise Exception("Failed to create/update reaction")
        
        # Get updated reaction counts
        reaction_counts = await self.supabase_client.get_reaction_counts(story_id)
        
        logger.info(f"Reaction saved: {request.reaction_type} for story {story_id}")
        
        return DailyStoryReactionResponseDTO(
            story_id=story_id,
            reaction_type=reaction.reaction_type,
            likes_count=reaction_counts.get("likes", 0),
            dislikes_count=reaction_counts.get("dislikes", 0)
        )

