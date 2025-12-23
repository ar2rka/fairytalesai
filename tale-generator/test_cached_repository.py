"""Unit tests for CachedRepository."""

import pytest
import json
from unittest.mock import Mock, MagicMock
from datetime import datetime

from src.infrastructure.cache.cached_repository import CachedRepository
from src.infrastructure.cache.cache_service import CacheService
from src.infrastructure.cache.strategies import HeroCacheStrategy
from src.infrastructure.config.settings import CacheSettings
from src.domain.entities import Hero
from src.domain.value_objects import Language, Gender


@pytest.fixture
def cache_settings():
    """Create cache settings for testing."""
    return CacheSettings(hero_ttl=3600, default_ttl=3600)


@pytest.fixture
def mock_cache_service():
    """Create mock CacheService."""
    service = Mock(spec=CacheService)
    service.get.return_value = None
    service.set.return_value = True
    service.delete.return_value = True
    service.delete_pattern.return_value = 5
    service.exists.return_value = False
    service.get_ttl.return_value = -2
    return service


@pytest.fixture
def mock_base_repository():
    """Create mock base repository."""
    repo = Mock()
    repo.find_by_id.return_value = None
    repo.list_all.return_value = []
    repo.save.return_value = None
    repo.delete.return_value = False
    repo.update.return_value = None
    return repo


@pytest.fixture
def hero_strategy(cache_settings):
    """Create HeroCacheStrategy."""
    return HeroCacheStrategy(cache_settings)


@pytest.fixture
def sample_hero():
    """Create a sample Hero entity."""
    return Hero(
        id="hero-123",
        name="Captain Wonder",
        age=12,
        gender=Gender.MALE,
        appearance="Wears a blue cape",
        personality_traits=["brave", "kind"],
        interests=["flying", "helping"],
        strengths=["super strength"],
        language=Language.ENGLISH,
        created_at=datetime(2024, 1, 15, 10, 30, 0),
        updated_at=datetime(2024, 1, 15, 10, 30, 0),
    )


class TestCachedRepositoryInitialization:
    """Test CachedRepository initialization."""
    
    def test_initialization(self, mock_base_repository, mock_cache_service, hero_strategy):
        """Test successful initialization."""
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        assert cached_repo.base_repository == mock_base_repository
        assert cached_repo.cache_service == mock_cache_service
        assert cached_repo.cache_strategy == hero_strategy


class TestCachedRepositoryFindById:
    """Test find_by_id with caching."""
    
    def test_find_by_id_cache_hit(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test find_by_id returns cached data on cache hit."""
        # Setup: cache returns serialized hero
        cached_data = hero_strategy.serialize(sample_hero)
        mock_cache_service.get.return_value = cached_data
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.find_by_id("hero-123")
        
        # Verify
        assert result is not None
        assert result.id == "hero-123"
        assert result.name == "Captain Wonder"
        
        # Cache was checked, database was NOT queried
        mock_cache_service.get.assert_called_once_with("hero:hero-123")
        mock_base_repository.find_by_id.assert_not_called()
    
    def test_find_by_id_cache_miss(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test find_by_id queries database on cache miss."""
        # Setup: cache miss, database returns hero
        mock_cache_service.get.return_value = None
        mock_base_repository.find_by_id.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.find_by_id("hero-123")
        
        # Verify
        assert result == sample_hero
        
        # Both cache and database were queried
        mock_cache_service.get.assert_called_once_with("hero:hero-123")
        mock_base_repository.find_by_id.assert_called_once_with("hero-123")
        
        # Result was cached
        mock_cache_service.set.assert_called_once()
    
    def test_find_by_id_not_found(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy
    ):
        """Test find_by_id returns None when entity not found."""
        mock_cache_service.get.return_value = None
        mock_base_repository.find_by_id.return_value = None
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        result = cached_repo.find_by_id("nonexistent")
        
        assert result is None
        # Should not cache None results
        mock_cache_service.set.assert_not_called()
    
    def test_find_by_id_cache_error_fallback(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test find_by_id falls back to database on cache error."""
        # Setup: cache throws error, database returns hero
        mock_cache_service.get.side_effect = Exception("Cache error")
        mock_base_repository.find_by_id.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Should not raise exception, should fall back to database
        result = cached_repo.find_by_id("hero-123")
        
        assert result == sample_hero
        mock_base_repository.find_by_id.assert_called_once()


class TestCachedRepositoryListAll:
    """Test list_all with caching."""
    
    def test_list_all_cache_hit(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test list_all returns cached data on cache hit."""
        # Setup: prepare cached list
        heroes = [sample_hero]
        serialized_heroes = [json.loads(hero_strategy.serialize(h)) for h in heroes]
        cached_data = json.dumps(serialized_heroes)
        mock_cache_service.get.return_value = cached_data
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.list_all()
        
        # Verify
        assert len(result) == 1
        assert result[0].id == "hero-123"
        
        # Cache was checked, database was NOT queried
        mock_cache_service.get.assert_called_once_with("hero:all")
        mock_base_repository.list_all.assert_not_called()
    
    def test_list_all_cache_miss(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test list_all queries database on cache miss."""
        # Setup
        heroes = [sample_hero]
        mock_cache_service.get.return_value = None
        mock_base_repository.list_all.return_value = heroes
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.list_all()
        
        # Verify
        assert result == heroes
        
        # Database was queried and result was cached
        mock_base_repository.list_all.assert_called_once()
        mock_cache_service.set.assert_called_once()


class TestCachedRepositorySave:
    """Test save with cache invalidation."""
    
    def test_save_invalidates_collection_cache(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test save invalidates collection caches."""
        mock_base_repository.save.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.save(sample_hero)
        
        # Verify
        assert result == sample_hero
        mock_base_repository.save.assert_called_once_with(sample_hero)
        
        # Collection cache was invalidated
        delete_calls = [call[0][0] for call in mock_cache_service.delete.call_args_list]
        assert "hero:all" in delete_calls
        assert "hero:lang:en" in delete_calls
    
    def test_save_caches_new_entity(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test save caches the new entity."""
        mock_base_repository.save.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        cached_repo.save(sample_hero)
        
        # Entity was cached
        mock_cache_service.set.assert_called_once()
        call_args = mock_cache_service.set.call_args[0]
        assert call_args[0] == "hero:hero-123"  # Key
        assert call_args[2] == 3600  # TTL


class TestCachedRepositoryUpdate:
    """Test update with cache invalidation."""
    
    def test_update_invalidates_caches(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test update invalidates related caches."""
        mock_base_repository.update.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.update(sample_hero)
        
        # Verify
        assert result == sample_hero
        
        # Multiple caches were invalidated
        delete_calls = [call[0][0] for call in mock_cache_service.delete.call_args_list]
        assert "hero:hero-123" in delete_calls
        assert "hero:all" in delete_calls
        assert "hero:lang:en" in delete_calls
    
    def test_update_refreshes_entity_cache(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy,
        sample_hero
    ):
        """Test update refreshes entity cache with new data."""
        mock_base_repository.update.return_value = sample_hero
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        cached_repo.update(sample_hero)
        
        # Entity was re-cached with updated data
        mock_cache_service.set.assert_called_once()


class TestCachedRepositoryDelete:
    """Test delete with cache invalidation."""
    
    def test_delete_invalidates_caches(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy
    ):
        """Test delete invalidates related caches."""
        mock_base_repository.delete.return_value = True
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        # Execute
        result = cached_repo.delete("hero-123")
        
        # Verify
        assert result is True
        mock_base_repository.delete.assert_called_once_with("hero-123")
        
        # Caches were invalidated
        delete_calls = [call[0][0] for call in mock_cache_service.delete.call_args_list]
        assert "hero:hero-123" in delete_calls
        assert "hero:all" in delete_calls


class TestCachedRepositoryManualInvalidation:
    """Test manual cache invalidation."""
    
    def test_invalidate_all(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy
    ):
        """Test invalidating all caches for entity type."""
        mock_cache_service.delete_pattern.return_value = 10
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        count = cached_repo.invalidate_cache("all")
        
        assert count == 10
        mock_cache_service.delete_pattern.assert_called_once_with("hero:*")
    
    def test_invalidate_specific_key(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy
    ):
        """Test invalidating specific cache key."""
        mock_cache_service.delete.return_value = True
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        count = cached_repo.invalidate_cache("by_id", id="hero-123")
        
        assert count == 1
        mock_cache_service.delete.assert_called_once_with("hero:hero-123")


class TestCachedRepositoryCacheStats:
    """Test cache statistics."""
    
    def test_get_cache_stats(
        self,
        mock_base_repository,
        mock_cache_service,
        hero_strategy
    ):
        """Test retrieving cache statistics."""
        mock_cache_service.exists.return_value = True
        mock_cache_service.get_ttl.return_value = 1800
        
        cached_repo = CachedRepository(
            base_repository=mock_base_repository,
            cache_service=mock_cache_service,
            cache_strategy=hero_strategy
        )
        
        stats = cached_repo.get_cache_stats()
        
        assert stats["entity_type"] == "hero"
        assert stats["default_ttl"] == 3600
        assert stats["all_cached"] is True
        assert stats["all_ttl_remaining"] == 1800
        assert stats["cache_on_read"] is True
        assert stats["cache_on_write"] is True


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
