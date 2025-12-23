"""Example: Using Redis caching with Hero repository.

This example demonstrates how to integrate Redis caching with the Hero repository
for improved performance. The caching system is transparent and doesn't require
changes to existing code - it's implemented using the decorator pattern.

Prerequisites:
    - Redis server running (default: localhost:6379)
    - Environment variables configured (see .env.example)

Environment Variables:
    REDIS_URL=redis://localhost:6379/0
    REDIS_PASSWORD=  # Optional
    REDIS_ENABLED=true
    REDIS_MAX_CONNECTIONS=10
"""

import logging
from typing import List

from src.infrastructure.config.settings import get_settings
from src.infrastructure.cache import (
    CacheService,
    CachedRepository,
    HeroCacheStrategy,
)
from src.domain.entities import Hero
from src.domain.value_objects import Language
from src.supabase_client import SupabaseClient

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SimpleHeroRepository:
    """Simple Hero repository implementation using Supabase.
    
    This is a simplified version for demonstration purposes.
    In production, use the actual repository implementation.
    """
    
    def __init__(self, supabase_client: SupabaseClient):
        self.client = supabase_client
    
    def find_by_id(self, entity_id: str):
        """Find hero by ID."""
        logger.info(f"DATABASE QUERY: Finding hero by ID: {entity_id}")
        hero_db = self.client.get_hero(entity_id)
        if not hero_db:
            return None
        
        # Convert to domain Hero entity
        from src.domain.value_objects import Gender
        return Hero(
            id=hero_db.id,
            name=hero_db.name,
            age=12,  # Default age
            gender=Gender(hero_db.gender),
            appearance=hero_db.appearance,
            personality_traits=hero_db.personality_traits,
            interests=hero_db.interests,
            strengths=hero_db.strengths,
            language=Language(hero_db.language),
            created_at=hero_db.created_at,
            updated_at=hero_db.updated_at,
        )
    
    def list_all(self) -> List[Hero]:
        """List all heroes."""
        logger.info("DATABASE QUERY: Fetching all heroes")
        heroes_db = self.client.get_all_heroes()
        
        from src.domain.value_objects import Gender
        heroes = []
        for hero_db in heroes_db:
            heroes.append(Hero(
                id=hero_db.id,
                name=hero_db.name,
                age=12,
                gender=Gender(hero_db.gender),
                appearance=hero_db.appearance,
                personality_traits=hero_db.personality_traits,
                interests=hero_db.interests,
                strengths=hero_db.strengths,
                language=Language(hero_db.language),
                created_at=hero_db.created_at,
                updated_at=hero_db.updated_at,
            ))
        return heroes
    
    def save(self, entity):
        """Save hero."""
        logger.info(f"DATABASE WRITE: Saving hero: {entity.name}")
        return entity
    
    def delete(self, entity_id: str) -> bool:
        """Delete hero."""
        logger.info(f"DATABASE DELETE: Deleting hero: {entity_id}")
        return True
    
    def update(self, entity):
        """Update hero."""
        logger.info(f"DATABASE UPDATE: Updating hero: {entity.name}")
        return entity


def demonstrate_caching_without_redis():
    """Demonstrate repository without caching."""
    print("\n" + "="*80)
    print("SCENARIO 1: Without Caching")
    print("="*80 + "\n")
    
    # Initialize Supabase client
    settings = get_settings()
    supabase_client = SupabaseClient()
    
    # Create basic repository (no caching)
    hero_repo = SimpleHeroRepository(supabase_client)
    
    # Fetch all heroes twice - both hit database
    print("First fetch:")
    heroes1 = hero_repo.list_all()
    print(f"Retrieved {len(heroes1)} heroes\n")
    
    print("Second fetch (same data):")
    heroes2 = hero_repo.list_all()
    print(f"Retrieved {len(heroes2)} heroes")
    
    print("\n⚠️  Both queries hit the database!\n")


def demonstrate_caching_with_redis():
    """Demonstrate repository with Redis caching."""
    print("\n" + "="*80)
    print("SCENARIO 2: With Redis Caching")
    print("="*80 + "\n")
    
    # Initialize settings and cache service
    settings = get_settings()
    print(settings)
    cache_service = CacheService(settings.cache)
    
    # Check Redis health
    if not cache_service.health_check():
        print("❌ Redis is not available. Please start Redis server.")
        print("   Run: docker run -d -p 6379:6379 redis:latest")
        return
    
    print("✅ Redis connection healthy\n")
    
    # Initialize Supabase client
    supabase_client = SupabaseClient()
    
    # Create base repository
    base_hero_repo = SimpleHeroRepository(supabase_client)
    
    # Wrap with caching
    hero_strategy = HeroCacheStrategy(settings.cache)
    cached_hero_repo = CachedRepository(
        base_repository=base_hero_repo,
        cache_service=cache_service,
        cache_strategy=hero_strategy
    )
    
    # Clear cache to start fresh
    print("Clearing cache...")
    cached_hero_repo.invalidate_cache("all")
    print()
    
    # First fetch - cache miss, hits database
    print("First fetch (cache miss):")
    heroes1 = cached_hero_repo.list_all()
    print(f"Retrieved {len(heroes1)} heroes")
    print("→ Result cached in Redis\n")
    
    # Second fetch - cache hit, no database query
    print("Second fetch (cache hit):")
    heroes2 = cached_hero_repo.list_all()
    print(f"Retrieved {len(heroes2)} heroes")
    print("→ Returned from cache!\n")
    
    # Get cache statistics
    stats = cached_hero_repo.get_cache_stats()
    print("Cache Statistics:")
    print(f"  Entity Type: {stats['entity_type']}")
    print(f"  Default TTL: {stats['default_ttl']}s")
    print(f"  All Heroes Cached: {stats['all_cached']}")
    print(f"  TTL Remaining: {stats['all_ttl_remaining']}s")
    
    print("\n✅ Second query served from cache - no database hit!")


def demonstrate_cache_invalidation():
    """Demonstrate cache invalidation on updates."""
    print("\n" + "="*80)
    print("SCENARIO 3: Cache Invalidation")
    print("="*80 + "\n")
    
    settings = get_settings()
    print(settings)
    cache_service = CacheService(settings.cache)
    
    if not cache_service.health_check():
        print("❌ Redis is not available.")
        return
    
    supabase_client = SupabaseClient()
    
    base_hero_repo = SimpleHeroRepository(supabase_client)
    hero_strategy = HeroCacheStrategy(settings.cache)
    cached_hero_repo = CachedRepository(
        base_repository=base_hero_repo,
        cache_service=cache_service,
        cache_strategy=hero_strategy
    )
    
    # Fetch and cache heroes
    print("1. Initial fetch (populates cache):")
    heroes = cached_hero_repo.list_all()
    print(f"   Cached {len(heroes)} heroes\n")
    
    # Simulate hero update
    print("2. Updating a hero:")
    if heroes:
        hero = heroes[0]
        print(f"   Updating hero: {hero.name}")
        cached_hero_repo.update(hero)
        print("   → Cache invalidated automatically\n")
    
    # Next fetch will hit database again
    print("3. Fetch after update (cache miss):")
    heroes_after = cached_hero_repo.list_all()
    print(f"   Retrieved {len(heroes_after)} heroes from database")
    print("   → Cache refreshed with latest data\n")
    
    print("✅ Cache invalidation ensures data consistency!")


def demonstrate_graceful_degradation():
    """Demonstrate graceful degradation when Redis is unavailable."""
    print("\n" + "="*80)
    print("SCENARIO 4: Graceful Degradation (Redis Down)")
    print("="*80 + "\n")
    
    settings = get_settings()
    
    # Create cache service with invalid URL to simulate Redis being down
    from src.infrastructure.config.settings import CacheSettings
    offline_settings = CacheSettings(
        url="redis://invalid-host:6379/0",
        enabled=True
    )
    cache_service = CacheService(offline_settings)
    
    print("⚠️  Simulating Redis unavailability...\n")
    
    supabase_client = SupabaseClient()
    
    base_hero_repo = SimpleHeroRepository(supabase_client)
    hero_strategy = HeroCacheStrategy(offline_settings)
    cached_hero_repo = CachedRepository(
        base_repository=base_hero_repo,
        cache_service=cache_service,
        cache_strategy=hero_strategy
    )
    
    # Fetch works despite Redis being down
    print("Fetching heroes (Redis unavailable):")
    heroes = cached_hero_repo.list_all()
    print(f"Retrieved {len(heroes)} heroes")
    print("→ Falls back to database automatically\n")
    
    print("✅ Application continues to work - no errors!")
    print("   (with degraded performance)")


def main():
    """Run all demonstration scenarios."""
    print("\n" + "🚀 " + "="*76)
    print("Redis Caching System Demonstration")
    print("="*78 + " 🚀\n")
    
    try:
        # Scenario 1: No caching
        demonstrate_caching_without_redis()
        
        # Scenario 2: With caching
        demonstrate_caching_with_redis()
        
        # Scenario 3: Cache invalidation
        demonstrate_cache_invalidation()
        
        # Scenario 4: Graceful degradation
        demonstrate_graceful_degradation()
        
        print("\n" + "="*80)
        print("✅ All scenarios completed successfully!")
        print("="*80 + "\n")
        
        print("Key Takeaways:")
        print("  1. Caching reduces database load significantly")
        print("  2. Cache invalidation maintains data consistency")
        print("  3. System degrades gracefully when Redis is down")
        print("  4. Implementation is transparent to existing code")
        
    except Exception as e:
        logger.error(f"Error during demonstration: {str(e)}", exc_info=True)


if __name__ == "__main__":
    main()
