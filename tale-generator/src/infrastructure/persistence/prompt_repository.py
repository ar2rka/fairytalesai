"""Repository for loading prompts from Supabase."""

from typing import List, Optional
from src.infrastructure.persistence.models import PromptDB
from src.domain.value_objects import Language
from src.core.logging import get_logger

logger = get_logger("infrastructure.prompt_repository")


class PromptRepository:
    """Repository for loading prompt templates from Supabase."""
    
    def __init__(self, supabase_client):
        """Initialize prompt repository.
        
        Args:
            supabase_client: Supabase client instance (sync or async)
        """
        self._client = supabase_client
        self._cache: Optional[dict] = None  # Simple in-memory cache
        logger.info("PromptRepository initialized")
    
    def get_prompts(
        self, 
        language: Language, 
        story_type: Optional[str] = None
    ) -> List[PromptDB]:
        """Get all active prompts for given language and story_type.
        
        Prompts are loaded from Supabase, filtered by:
        - language matches
        - story_type matches OR story_type is NULL (universal prompts)
        - is_active = true
        
        Results are sorted by priority (ascending).
        
        Args:
            language: Target language
            story_type: Story type ('child', 'hero', 'combined') or None for all types
            
        Returns:
            List of PromptDB objects sorted by priority
        """
        # Build cache key
        cache_key = f"{language.value}_{story_type or 'all'}"
        
        # Check cache first
        if self._cache and cache_key in self._cache:
            logger.debug(f"Using cached prompts for {cache_key}")
            return self._cache[cache_key]
        
        try:
            # Query Supabase
            # Handle both SupabaseClient (has .client) and direct client
            logger.debug(f"PromptRepository client type: {type(self._client)}")
            if hasattr(self._client, 'client'):
                client = self._client.client
                logger.debug("Using client.client (SupabaseClient)")
            elif hasattr(self._client, 'supabase'):
                client = self._client.supabase
                logger.debug("Using client.supabase")
            else:
                client = self._client
                logger.debug("Using client directly")
            
            logger.debug(f"Final client type: {type(client)}")
            
            query = client.table("prompts").select("*")
            
            # Filter by language
            query = query.eq("language", language.value)
            
            # Filter by story_type: either exact match or NULL (universal)
            if story_type:
                query = query.or_(f"story_type.eq.{story_type},story_type.is.null")
            else:
                query = query.is_("story_type", "null")
            
            # Only active prompts
            query = query.eq("is_active", True)
            
            # Order by priority
            query = query.order("priority", desc=False)
            
            # Execute query
            response = query.execute()
            
            # Convert to PromptDB objects
            prompts = []
            for row in response.data:
                prompt = PromptDB(
                    id=row.get("id"),
                    priority=row.get("priority"),
                    language=row.get("language"),
                    story_type=row.get("story_type"),
                    prompt_text=row.get("prompt_text"),
                    is_active=row.get("is_active", True),
                    description=row.get("description"),
                    created_at=row.get("created_at"),
                    updated_at=row.get("updated_at")
                )
                prompts.append(prompt)
            
            logger.info(
                f"Loaded {len(prompts)} prompts for language={language.value}, "
                f"story_type={story_type}"
            )
            
            # Cache results
            if self._cache is None:
                self._cache = {}
            self._cache[cache_key] = prompts
            
            return prompts
            
        except Exception as e:
            logger.error(
                f"Error loading prompts for language={language.value}, "
                f"story_type={story_type}: {str(e)}",
                exc_info=True
            )
            return []
    
    def clear_cache(self):
        """Clear the in-memory cache."""
        self._cache = None
        logger.debug("Prompt cache cleared")

