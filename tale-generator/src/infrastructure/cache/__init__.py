"""Cache infrastructure module.

This module provides Redis-based caching capabilities with support for:
- Transparent cache-aside pattern implementation
- Entity-specific caching strategies
- Configurable TTL policies
- Graceful degradation when Redis is unavailable

Usage Example:
    ```python
    from src.infrastructure.config.settings import get_settings
    from src.infrastructure.cache import (
        CacheService,
        CachedRepository,
        HeroCacheStrategy
    )
    
    # Initialize cache service
    settings = get_settings()
    cache_service = CacheService(settings.cache)
    
    # Create cache strategy
    hero_strategy = HeroCacheStrategy(settings.cache)
    
    # Wrap repository with caching
    cached_hero_repo = CachedRepository(
        base_repository=original_hero_repo,
        cache_service=cache_service,
        cache_strategy=hero_strategy
    )
    
    # Use cached repository transparently
    hero = cached_hero_repo.find_by_id("some-id")  # Automatically cached
    ```
"""

from src.infrastructure.cache.cache_service import CacheService
from src.infrastructure.cache.strategies import (
    CacheStrategy,
    HeroCacheStrategy,
    ChildCacheStrategy,
    StoryCacheStrategy,
)
from src.infrastructure.cache.cached_repository import CachedRepository

__all__ = [
    "CacheService",
    "CacheStrategy",
    "HeroCacheStrategy",
    "ChildCacheStrategy",
    "StoryCacheStrategy",
    "CachedRepository",
]
