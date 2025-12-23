"""Redis cache service for data caching."""

import json
import logging
from typing import Optional
from datetime import datetime

try:
    import redis
    from redis import Redis, ConnectionPool
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    redis = None
    Redis = None
    ConnectionPool = None

from src.infrastructure.config.settings import CacheSettings

logger = logging.getLogger(__name__)


class CacheService:
    """Service for managing Redis cache operations.
    
    Provides abstraction over Redis operations with connection management,
    error handling, and graceful degradation when Redis is unavailable.
    """
    
    def __init__(self, settings: CacheSettings):
        """Initialize cache service.
        
        Args:
            settings: Cache configuration settings
        """
        self.settings = settings
        self._client: Optional[Redis] = None
        self._pool: Optional[ConnectionPool] = None
        self._enabled = settings.enabled and REDIS_AVAILABLE
        
        if self._enabled:
            try:
                self._initialize_connection()
            except Exception as e:
                logger.error(f"Failed to initialize Redis connection: {str(e)}")
                self._enabled = False
        else:
            if not REDIS_AVAILABLE:
                logger.warning("Redis library not installed. Caching disabled.")
            elif not settings.enabled:
                logger.info("Cache disabled in settings.")
    
    def _initialize_connection(self) -> None:
        """Initialize Redis connection pool and client."""
        if not REDIS_AVAILABLE:
            raise ImportError("redis library is not installed")
        
        # Parse connection parameters
        connection_params = {
            'max_connections': self.settings.max_connections,
            'socket_timeout': self.settings.socket_timeout,
            'decode_responses': True,
        }
        
        # Add password if configured
        if self.settings.password:
            connection_params['password'] = self.settings.password
        
        # Create connection pool
        self._pool = redis.ConnectionPool.from_url(
            self.settings.url,
            **connection_params
        )
        
        # Create Redis client
        self._client = redis.Redis(connection_pool=self._pool)
        
        # Perform health check
        if not self.health_check():
            raise ConnectionError("Redis health check failed")
        
        logger.info(
            f"Redis cache initialized successfully. "
            f"URL: {self.settings.url}, Pool size: {self.settings.max_connections}"
        )
    
    def health_check(self) -> bool:
        """Verify Redis connection is healthy.
        
        Returns:
            True if Redis is accessible, False otherwise
        """
        if not self._enabled or not self._client:
            return False
        
        try:
            return self._client.ping()
        except Exception as e:
            logger.error(f"Redis health check failed: {str(e)}")
            return False
    
    def get(self, key: str) -> Optional[str]:
        """Retrieve value by key.
        
        Args:
            key: Cache key
            
        Returns:
            Cached value if found, None otherwise
        """
        if not self._enabled or not self._client:
            return None
        
        try:
            value = self._client.get(key)
            if value:
                logger.debug(f"Cache hit for key: {key}")
                return value
            else:
                logger.debug(f"Cache miss for key: {key}")
                return None
        except Exception as e:
            logger.error(f"Error retrieving key '{key}' from cache: {str(e)}")
            return None
    
    def set(self, key: str, value: str, ttl: Optional[int] = None) -> bool:
        """Store value with optional expiration.
        
        Args:
            key: Cache key
            value: Value to store
            ttl: Time-to-live in seconds (uses default if not specified)
            
        Returns:
            True if stored successfully, False otherwise
        """
        if not self._enabled or not self._client:
            return False
        
        try:
            expiration = ttl if ttl is not None else self.settings.default_ttl
            result = self._client.setex(key, expiration, value)
            logger.debug(f"Cache write for key: {key}, TTL: {expiration}s")
            return bool(result)
        except Exception as e:
            logger.error(f"Error storing key '{key}' in cache: {str(e)}")
            return False
    
    def delete(self, key: str) -> bool:
        """Remove key from cache.
        
        Args:
            key: Cache key to delete
            
        Returns:
            True if deleted, False otherwise
        """
        if not self._enabled or not self._client:
            return False
        
        try:
            result = self._client.delete(key)
            logger.debug(f"Cache invalidation for key: {key}")
            return result > 0
        except Exception as e:
            logger.error(f"Error deleting key '{key}' from cache: {str(e)}")
            return False
    
    def delete_pattern(self, pattern: str) -> int:
        """Remove all keys matching pattern.
        
        Args:
            pattern: Key pattern with wildcards (e.g., 'hero:*')
            
        Returns:
            Number of keys deleted
        """
        if not self._enabled or not self._client:
            return 0
        
        try:
            # Find all keys matching pattern
            keys = self._client.keys(pattern)
            if not keys:
                return 0
            
            # Delete all matching keys
            result = self._client.delete(*keys)
            logger.info(f"Cache pattern invalidation: {pattern}, {result} keys deleted")
            return result
        except Exception as e:
            logger.error(f"Error deleting pattern '{pattern}' from cache: {str(e)}")
            return 0
    
    def exists(self, key: str) -> bool:
        """Check if key exists in cache.
        
        Args:
            key: Cache key
            
        Returns:
            True if key exists, False otherwise
        """
        if not self._enabled or not self._client:
            return False
        
        try:
            return bool(self._client.exists(key))
        except Exception as e:
            logger.error(f"Error checking existence of key '{key}': {str(e)}")
            return False
    
    def get_ttl(self, key: str) -> int:
        """Get remaining time-to-live for a key.
        
        Args:
            key: Cache key
            
        Returns:
            Remaining TTL in seconds, -1 if key has no expiry, -2 if key doesn't exist
        """
        if not self._enabled or not self._client:
            return -2
        
        try:
            return self._client.ttl(key)
        except Exception as e:
            logger.error(f"Error getting TTL for key '{key}': {str(e)}")
            return -2
    
    def flush_all(self) -> bool:
        """Clear all cached data.
        
        Warning: This removes ALL data from the Redis database.
        Use with caution.
        
        Returns:
            True if successful, False otherwise
        """
        if not self._enabled or not self._client:
            return False
        
        try:
            self._client.flushdb()
            logger.warning("All cache data flushed")
            return True
        except Exception as e:
            logger.error(f"Error flushing cache: {str(e)}")
            return False
    
    def close(self) -> None:
        """Close Redis connection and cleanup resources."""
        if self._client:
            try:
                self._client.close()
                logger.info("Redis connection closed")
            except Exception as e:
                logger.error(f"Error closing Redis connection: {str(e)}")
        
        if self._pool:
            try:
                self._pool.disconnect()
            except Exception as e:
                logger.error(f"Error disconnecting connection pool: {str(e)}")
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
