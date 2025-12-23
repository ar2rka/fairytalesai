"""Unit tests for CacheService."""

import pytest
from unittest.mock import Mock, patch, MagicMock
from src.infrastructure.cache.cache_service import CacheService
from src.infrastructure.config.settings import CacheSettings


@pytest.fixture
def cache_settings():
    """Create cache settings for testing."""
    return CacheSettings(
        url="redis://localhost:6379/0",
        password=None,
        db=0,
        max_connections=10,
        socket_timeout=5,
        enabled=True,
        default_ttl=3600,
        hero_ttl=3600,
        child_ttl=1800,
        story_ttl=600
    )


@pytest.fixture
def mock_redis():
    """Create mock Redis client."""
    with patch('src.infrastructure.cache.cache_service.redis') as mock:
        mock_client = MagicMock()
        mock_pool = MagicMock()
        mock.ConnectionPool.from_url.return_value = mock_pool
        mock.Redis.return_value = mock_client
        mock_client.ping.return_value = True
        yield mock_client


class TestCacheServiceInitialization:
    """Test CacheService initialization."""
    
    def test_initialization_with_redis_available(self, cache_settings, mock_redis):
        """Test successful initialization when Redis is available."""
        cache_service = CacheService(cache_settings)
        
        assert cache_service._enabled is True
        assert cache_service._client is not None
        mock_redis.ping.assert_called_once()
    
    def test_initialization_with_redis_unavailable(self, cache_settings):
        """Test initialization when Redis library is not available."""
        with patch('src.infrastructure.cache.cache_service.REDIS_AVAILABLE', False):
            cache_service = CacheService(cache_settings)
            
            assert cache_service._enabled is False
            assert cache_service._client is None
    
    def test_initialization_with_cache_disabled(self, mock_redis):
        """Test initialization when caching is disabled in settings."""
        settings = CacheSettings(enabled=False)
        cache_service = CacheService(settings)
        
        assert cache_service._enabled is False
    
    def test_initialization_connection_failure(self, cache_settings, mock_redis):
        """Test initialization handles connection failures gracefully."""
        mock_redis.ping.return_value = False
        
        with pytest.raises(ConnectionError):
            CacheService(cache_settings)


class TestCacheServiceOperations:
    """Test CacheService core operations."""
    
    def test_health_check_success(self, cache_settings, mock_redis):
        """Test health check when Redis is healthy."""
        mock_redis.ping.return_value = True
        cache_service = CacheService(cache_settings)
        
        assert cache_service.health_check() is True
    
    def test_health_check_failure(self, cache_settings, mock_redis):
        """Test health check when Redis ping fails."""
        cache_service = CacheService(cache_settings)
        mock_redis.ping.side_effect = Exception("Connection error")
        
        assert cache_service.health_check() is False
    
    def test_get_cache_hit(self, cache_settings, mock_redis):
        """Test get operation with cache hit."""
        mock_redis.get.return_value = '{"data": "cached_value"}'
        cache_service = CacheService(cache_settings)
        
        result = cache_service.get("test_key")
        
        assert result == '{"data": "cached_value"}'
        mock_redis.get.assert_called_once_with("test_key")
    
    def test_get_cache_miss(self, cache_settings, mock_redis):
        """Test get operation with cache miss."""
        mock_redis.get.return_value = None
        cache_service = CacheService(cache_settings)
        
        result = cache_service.get("test_key")
        
        assert result is None
    
    def test_get_with_error(self, cache_settings, mock_redis):
        """Test get operation handles errors gracefully."""
        cache_service = CacheService(cache_settings)
        mock_redis.get.side_effect = Exception("Redis error")
        
        result = cache_service.get("test_key")
        
        assert result is None
    
    def test_set_success(self, cache_settings, mock_redis):
        """Test set operation success."""
        mock_redis.setex.return_value = True
        cache_service = CacheService(cache_settings)
        
        result = cache_service.set("test_key", "test_value", ttl=1800)
        
        assert result is True
        mock_redis.setex.assert_called_once_with("test_key", 1800, "test_value")
    
    def test_set_with_default_ttl(self, cache_settings, mock_redis):
        """Test set operation uses default TTL when not specified."""
        mock_redis.setex.return_value = True
        cache_service = CacheService(cache_settings)
        
        cache_service.set("test_key", "test_value")
        
        mock_redis.setex.assert_called_once_with("test_key", 3600, "test_value")
    
    def test_set_with_error(self, cache_settings, mock_redis):
        """Test set operation handles errors gracefully."""
        cache_service = CacheService(cache_settings)
        mock_redis.setex.side_effect = Exception("Redis error")
        
        result = cache_service.set("test_key", "test_value")
        
        assert result is False
    
    def test_delete_success(self, cache_settings, mock_redis):
        """Test delete operation success."""
        mock_redis.delete.return_value = 1
        cache_service = CacheService(cache_settings)
        
        result = cache_service.delete("test_key")
        
        assert result is True
        mock_redis.delete.assert_called_once_with("test_key")
    
    def test_delete_key_not_found(self, cache_settings, mock_redis):
        """Test delete when key doesn't exist."""
        mock_redis.delete.return_value = 0
        cache_service = CacheService(cache_settings)
        
        result = cache_service.delete("test_key")
        
        assert result is False
    
    def test_delete_pattern_success(self, cache_settings, mock_redis):
        """Test pattern-based deletion."""
        mock_redis.keys.return_value = ["hero:1", "hero:2", "hero:3"]
        mock_redis.delete.return_value = 3
        cache_service = CacheService(cache_settings)
        
        result = cache_service.delete_pattern("hero:*")
        
        assert result == 3
        mock_redis.keys.assert_called_once_with("hero:*")
        mock_redis.delete.assert_called_once_with("hero:1", "hero:2", "hero:3")
    
    def test_delete_pattern_no_matches(self, cache_settings, mock_redis):
        """Test pattern deletion when no keys match."""
        mock_redis.keys.return_value = []
        cache_service = CacheService(cache_settings)
        
        result = cache_service.delete_pattern("hero:*")
        
        assert result == 0
    
    def test_exists_true(self, cache_settings, mock_redis):
        """Test exists returns True when key exists."""
        mock_redis.exists.return_value = 1
        cache_service = CacheService(cache_settings)
        
        result = cache_service.exists("test_key")
        
        assert result is True
    
    def test_exists_false(self, cache_settings, mock_redis):
        """Test exists returns False when key doesn't exist."""
        mock_redis.exists.return_value = 0
        cache_service = CacheService(cache_settings)
        
        result = cache_service.exists("test_key")
        
        assert result is False
    
    def test_get_ttl_success(self, cache_settings, mock_redis):
        """Test getting TTL for existing key."""
        mock_redis.ttl.return_value = 1800
        cache_service = CacheService(cache_settings)
        
        result = cache_service.get_ttl("test_key")
        
        assert result == 1800
    
    def test_get_ttl_no_expiry(self, cache_settings, mock_redis):
        """Test TTL when key has no expiration."""
        mock_redis.ttl.return_value = -1
        cache_service = CacheService(cache_settings)
        
        result = cache_service.get_ttl("test_key")
        
        assert result == -1
    
    def test_flush_all_success(self, cache_settings, mock_redis):
        """Test flushing all cache data."""
        mock_redis.flushdb.return_value = True
        cache_service = CacheService(cache_settings)
        
        result = cache_service.flush_all()
        
        assert result is True
        mock_redis.flushdb.assert_called_once()


class TestCacheServiceDisabled:
    """Test CacheService behavior when disabled."""
    
    def test_get_when_disabled(self, mock_redis):
        """Test get returns None when cache is disabled."""
        settings = CacheSettings(enabled=False)
        cache_service = CacheService(settings)
        
        result = cache_service.get("test_key")
        
        assert result is None
    
    def test_set_when_disabled(self, mock_redis):
        """Test set returns False when cache is disabled."""
        settings = CacheSettings(enabled=False)
        cache_service = CacheService(settings)
        
        result = cache_service.set("test_key", "test_value")
        
        assert result is False
    
    def test_delete_when_disabled(self, mock_redis):
        """Test delete returns False when cache is disabled."""
        settings = CacheSettings(enabled=False)
        cache_service = CacheService(settings)
        
        result = cache_service.delete("test_key")
        
        assert result is False


class TestCacheServiceContextManager:
    """Test CacheService as context manager."""
    
    def test_context_manager_closes_connection(self, cache_settings, mock_redis):
        """Test context manager properly closes Redis connection."""
        with CacheService(cache_settings) as cache_service:
            assert cache_service._client is not None
        
        mock_redis.close.assert_called_once()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
