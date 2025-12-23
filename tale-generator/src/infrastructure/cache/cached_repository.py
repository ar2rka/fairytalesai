"""Cached repository decorator for transparent caching."""

import logging
from typing import TypeVar, Generic, Optional, List

from src.domain.repositories.base import Repository
from src.infrastructure.cache.cache_service import CacheService
from src.infrastructure.cache.strategies import CacheStrategy

logger = logging.getLogger(__name__)

T = TypeVar('T')


class CachedRepository(Repository[T], Generic[T]):
    """Repository decorator that adds transparent caching capabilities.
    
    Implements the cache-aside pattern, where the repository checks cache first,
    falls back to the database on cache miss, and populates the cache.
    """
    
    def __init__(
        self,
        base_repository: Repository[T],
        cache_service: CacheService,
        cache_strategy: CacheStrategy[T]
    ):
        """Initialize cached repository.
        
        Args:
            base_repository: Underlying repository implementation
            cache_service: Cache service for Redis operations
            cache_strategy: Strategy for entity-specific caching behavior
        """
        self.base_repository = base_repository
        self.cache_service = cache_service
        self.cache_strategy = cache_strategy
    
    def save(self, entity: T) -> T:
        """Save entity and invalidate related cache entries.
        
        Args:
            entity: Entity to save
            
        Returns:
            Saved entity with ID
        """
        # Save to database
        saved_entity = self.base_repository.save(entity)
        
        # Invalidate collection caches since a new entity was added
        try:
            all_key = self.cache_strategy.build_key("all")
            self.cache_service.delete(all_key)
            logger.info(f"Invalidated cache for new {self.cache_strategy.entity_type}: {all_key}")
            
            # If entity has language-specific caching, invalidate that too
            if hasattr(saved_entity, 'language'):
                lang_key = self.cache_strategy.build_key("by_language", language=saved_entity.language)
                self.cache_service.delete(lang_key)
                logger.info(f"Invalidated language cache: {lang_key}")
        except Exception as e:
            logger.error(f"Error invalidating cache on save: {str(e)}")
        
        # Optionally cache the saved entity
        if self.cache_strategy.cache_on_write and hasattr(saved_entity, 'id') and saved_entity.id:
            try:
                cache_key = self.cache_strategy.build_key("by_id", id=saved_entity.id)
                serialized = self.cache_strategy.serialize(saved_entity)
                self.cache_service.set(cache_key, serialized, self.cache_strategy.default_ttl)
                logger.debug(f"Cached new {self.cache_strategy.entity_type}: {cache_key}")
            except Exception as e:
                logger.error(f"Error caching entity on save: {str(e)}")
        
        return saved_entity
    
    def find_by_id(self, entity_id: str) -> Optional[T]:
        """Find entity by ID with caching.
        
        Args:
            entity_id: Entity ID
            
        Returns:
            Entity if found, None otherwise
        """
        # Build cache key
        cache_key = self.cache_strategy.build_key("by_id", id=entity_id)
        
        # Try cache first
        try:
            cached_data = self.cache_service.get(cache_key)
            if cached_data:
                entity = self.cache_strategy.deserialize(cached_data)
                logger.debug(f"Cache hit for {self.cache_strategy.entity_type}:{entity_id}")
                return entity
        except Exception as e:
            logger.error(f"Error reading from cache: {str(e)}")
        
        # Cache miss - query database
        logger.debug(f"Cache miss for {self.cache_strategy.entity_type}:{entity_id}")
        entity = self.base_repository.find_by_id(entity_id)
        
        # Cache the result if found and caching on read is enabled
        if entity and self.cache_strategy.cache_on_read:
            try:
                serialized = self.cache_strategy.serialize(entity)
                self.cache_service.set(cache_key, serialized, self.cache_strategy.default_ttl)
                logger.debug(f"Cached {self.cache_strategy.entity_type}:{entity_id}")
            except Exception as e:
                logger.error(f"Error caching entity: {str(e)}")
        
        return entity
    
    def list_all(self) -> List[T]:
        """List all entities with caching.
        
        Returns:
            List of all entities
        """
        # Build cache key for all entities
        cache_key = self.cache_strategy.build_key("all")
        
        # Try cache first
        try:
            cached_data = self.cache_service.get(cache_key)
            if cached_data:
                # For list caching, we store a JSON array of serialized entities
                import json
                entities_data = json.loads(cached_data)
                entities = [self.cache_strategy.deserialize(json.dumps(item)) for item in entities_data]
                logger.debug(f"Cache hit for all {self.cache_strategy.entity_type}s")
                return entities
        except Exception as e:
            logger.error(f"Error reading list from cache: {str(e)}")
        
        # Cache miss - query database
        logger.debug(f"Cache miss for all {self.cache_strategy.entity_type}s")
        entities = self.base_repository.list_all()
        
        # Cache the result if caching on read is enabled
        if entities and self.cache_strategy.cache_on_read:
            try:
                # Serialize each entity and store as array
                import json
                serialized_entities = []
                for entity in entities:
                    entity_json = self.cache_strategy.serialize(entity)
                    serialized_entities.append(json.loads(entity_json))
                
                # Store the array
                cached_value = json.dumps(serialized_entities)
                self.cache_service.set(cache_key, cached_value, self.cache_strategy.default_ttl)
                logger.debug(f"Cached all {self.cache_strategy.entity_type}s ({len(entities)} items)")
            except Exception as e:
                logger.error(f"Error caching entity list: {str(e)}")
        
        return entities
    
    def delete(self, entity_id: str) -> bool:
        """Delete entity and invalidate cache.
        
        Args:
            entity_id: Entity ID
            
        Returns:
            True if deleted, False otherwise
        """
        # First, try to get the entity to extract language info for cache invalidation
        entity = None
        try:
            entity = self.base_repository.find_by_id(entity_id)
        except Exception as e:
            logger.warning(f"Could not fetch entity before deletion: {str(e)}")
        
        # Delete from database
        deleted = self.base_repository.delete(entity_id)
        
        if deleted:
            # Invalidate specific entity cache
            try:
                entity_key = self.cache_strategy.build_key("by_id", id=entity_id)
                self.cache_service.delete(entity_key)
                
                # Invalidate collection caches
                all_key = self.cache_strategy.build_key("all")
                self.cache_service.delete(all_key)
                
                # Invalidate language-specific cache if applicable
                if entity and hasattr(entity, 'language'):
                    lang_key = self.cache_strategy.build_key("by_language", language=entity.language)
                    self.cache_service.delete(lang_key)
                
                logger.info(f"Invalidated cache after deleting {self.cache_strategy.entity_type}:{entity_id}")
            except Exception as e:
                logger.error(f"Error invalidating cache on delete: {str(e)}")
        
        return deleted
    
    def update(self, entity: T) -> T:
        """Update entity and refresh cache.
        
        Args:
            entity: Entity to update
            
        Returns:
            Updated entity
        """
        # Update in database
        updated_entity = self.base_repository.update(entity) if hasattr(self.base_repository, 'update') else entity
        
        # Invalidate and refresh cache
        if hasattr(updated_entity, 'id') and updated_entity.id:
            try:
                # Delete old cache entry
                entity_key = self.cache_strategy.build_key("by_id", id=updated_entity.id)
                self.cache_service.delete(entity_key)
                
                # Invalidate collection caches
                all_key = self.cache_strategy.build_key("all")
                self.cache_service.delete(all_key)
                
                # Invalidate language-specific cache if applicable
                if hasattr(updated_entity, 'language'):
                    lang_key = self.cache_strategy.build_key("by_language", language=updated_entity.language)
                    self.cache_service.delete(lang_key)
                
                # Cache the updated entity
                if self.cache_strategy.cache_on_write:
                    serialized = self.cache_strategy.serialize(updated_entity)
                    self.cache_service.set(entity_key, serialized, self.cache_strategy.default_ttl)
                
                logger.info(f"Updated cache for {self.cache_strategy.entity_type}:{updated_entity.id}")
            except Exception as e:
                logger.error(f"Error updating cache: {str(e)}")
        
        return updated_entity
    
    def invalidate_cache(self, operation: str = "all", **params) -> int:
        """Manually invalidate cache for specific operation or all.
        
        Args:
            operation: Operation type to invalidate ("all", "by_id", etc.)
            **params: Parameters for building cache key
            
        Returns:
            Number of keys invalidated
        """
        try:
            if operation == "all":
                # Invalidate all caches for this entity type
                pattern = f"{self.cache_strategy.entity_type}:*"
                count = self.cache_service.delete_pattern(pattern)
                logger.info(f"Invalidated all {self.cache_strategy.entity_type} caches: {count} keys")
                return count
            else:
                # Invalidate specific cache key
                cache_key = self.cache_strategy.build_key(operation, **params)
                deleted = self.cache_service.delete(cache_key)
                logger.info(f"Invalidated cache: {cache_key}")
                return 1 if deleted else 0
        except Exception as e:
            logger.error(f"Error invalidating cache: {str(e)}")
            return 0
    
    def get_cache_stats(self) -> dict:
        """Get cache statistics for this repository.
        
        Returns:
            Dictionary with cache statistics
        """
        try:
            all_key = self.cache_strategy.build_key("all")
            all_exists = self.cache_service.exists(all_key)
            all_ttl = self.cache_service.get_ttl(all_key) if all_exists else -2
            
            return {
                "entity_type": self.cache_strategy.entity_type,
                "default_ttl": self.cache_strategy.default_ttl,
                "all_cached": all_exists,
                "all_ttl_remaining": all_ttl,
                "cache_on_read": self.cache_strategy.cache_on_read,
                "cache_on_write": self.cache_strategy.cache_on_write,
            }
        except Exception as e:
            logger.error(f"Error getting cache stats: {str(e)}")
            return {"error": str(e)}
