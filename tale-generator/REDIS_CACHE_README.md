# Redis Caching Implementation

This document describes the Redis-based caching system implemented for the Tale Generator project.

## Overview

The caching system provides transparent, high-performance data caching using Redis, starting with Hero entities and designed to be easily extended to other entity types (Child, Story).

## Architecture

The implementation follows the **Cache-Aside Pattern** with a **Repository Decorator** approach:

```
Application Layer
       ↓
Cached Repository (Decorator)
       ↓
  Cache Hit? ─→ Yes ─→ Return from Redis
       ↓
      No
       ↓
Base Repository (Database)
       ↓
  Cache Result
       ↓
  Return Data
```

### Key Components

1. **CacheService** (`src/infrastructure/cache/cache_service.py`)
   - Low-level Redis operations
   - Connection management
   - Graceful degradation when Redis is unavailable

2. **CacheStrategy** (`src/infrastructure/cache/strategies.py`)
   - Entity-specific serialization/deserialization
   - Cache key generation
   - TTL configuration per entity type

3. **CachedRepository** (`src/infrastructure/cache/cached_repository.py`)
   - Repository decorator implementing cache-aside pattern
   - Automatic cache invalidation on writes
   - Transparent caching for reads

## Setup

### 1. Install Dependencies

```bash
# Using UV (recommended)
uv add redis

# Or using pip
pip install redis>=5.0.0
```

### 2. Configure Redis

Add Redis configuration to your `.env` file:

```env
# Redis Configuration
REDIS_URL=redis://localhost:6379/0
REDIS_PASSWORD=                    # Optional, leave empty if no password
REDIS_ENABLED=true
REDIS_MAX_CONNECTIONS=10
REDIS_SOCKET_TIMEOUT=5

# Cache TTL Settings (in seconds)
CACHE_DEFAULT_TTL=3600             # 1 hour
CACHE_HERO_TTL=3600                # 1 hour
CACHE_CHILD_TTL=1800               # 30 minutes
CACHE_STORY_TTL=600                # 10 minutes
```

### 3. Start Redis

Using Docker:
```bash
docker run -d -p 6379:6379 redis:latest
```

Or with password protection:
```bash
docker run -d -p 6379:6379 redis:latest redis-server --requirepass yourpassword
```

## Usage

### Basic Usage with Hero Repository

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

# Create cache strategy for heroes
hero_strategy = HeroCacheStrategy(settings.cache)

# Wrap your existing repository with caching
cached_hero_repo = CachedRepository(
    base_repository=your_hero_repository,
    cache_service=cache_service,
    cache_strategy=hero_strategy
)

# Use it exactly like your regular repository
hero = cached_hero_repo.find_by_id("hero-id")  # First call: cache miss, queries DB
hero = cached_hero_repo.find_by_id("hero-id")  # Second call: cache hit, no DB query!
```

### Check Cache Health

```python
if cache_service.health_check():
    print("✅ Redis is healthy")
else:
    print("⚠️ Redis is unavailable")
```

### Manual Cache Invalidation

```python
# Invalidate all hero caches
cached_hero_repo.invalidate_cache("all")

# Invalidate specific hero
cached_hero_repo.invalidate_cache("by_id", id="hero-123")
```

### Get Cache Statistics

```python
stats = cached_hero_repo.get_cache_stats()
print(f"Entity Type: {stats['entity_type']}")
print(f"All Heroes Cached: {stats['all_cached']}")
print(f"TTL Remaining: {stats['all_ttl_remaining']}s")
```

## Extending to Other Entities

To add caching for a new entity type (e.g., Child):

### 1. Use the Existing Strategy

The `ChildCacheStrategy` is already implemented:

```python
from src.infrastructure.cache import ChildCacheStrategy

child_strategy = ChildCacheStrategy(settings.cache)

cached_child_repo = CachedRepository(
    base_repository=your_child_repository,
    cache_service=cache_service,
    cache_strategy=child_strategy
)
```

### 2. Custom Cache Keys

Each strategy defines its own cache key patterns:

**Hero Keys:**
- By ID: `hero:{id}`
- By Language: `hero:lang:{language}`
- By Name: `hero:name:{name}`
- All: `hero:all`

**Child Keys:**
- By ID: `child:{id}`
- By Name: `child:name:{name}`
- Exact Match: `child:exact:{name}:{age}:{gender}`
- All: `child:all`

**Story Keys:**
- By ID: `story:{id}`
- By Child ID: `story:child:{child_id}`
- By Child Name: `story:child_name:{child_name}`
- By Language: `story:lang:{language}`
- All: `story:all`

## Cache Invalidation

Cache invalidation happens automatically on write operations:

### Save (Create)
- Invalidates: `{entity}:all`, `{entity}:lang:{language}`
- Caches: New entity by ID

### Update
- Invalidates: `{entity}:{id}`, `{entity}:all`, `{entity}:lang:{language}`
- Re-caches: Updated entity by ID

### Delete
- Invalidates: `{entity}:{id}`, `{entity}:all`, `{entity}:lang:{language}`

## Performance Expectations

Based on the design:

| Operation | Without Cache | With Cache | Improvement |
|-----------|---------------|------------|-------------|
| `find_by_id` | 50-100ms | <5ms | 90-95% |
| `find_by_language` | 80-150ms | <10ms | 85-93% |
| `list_all` | 100-200ms | <15ms | 85-92% |

## Error Handling

The system is designed for **graceful degradation**:

- ✅ If Redis is unavailable, queries fall back to the database
- ✅ Cache errors never propagate to the application
- ✅ Application continues to function with degraded performance
- ✅ All errors are logged for monitoring

## Running the Example

Test the caching system with the provided example:

```bash
# Make sure Redis is running
docker run -d -p 6379:6379 redis:latest

# Run the example
uv run python example_redis_cache.py
```

The example demonstrates:
1. Repository without caching (baseline)
2. Repository with caching (performance improvement)
3. Cache invalidation on updates
4. Graceful degradation when Redis is down

## Testing

Run the comprehensive test suite:

```bash
# Install pytest if needed
uv add --dev pytest

# Run cache service tests
uv run pytest test_cache_service.py -v

# Run cache strategy tests
uv run pytest test_cache_strategies.py -v

# Run cached repository tests
uv run pytest test_cached_repository.py -v

# Run all cache tests
uv run pytest test_cache*.py -v
```

## Monitoring

### Key Metrics to Track

1. **Cache Hit Rate**: Should be >80% for heroes
2. **Cache Miss Rate**: Should be <20%
3. **Redis Memory Usage**: Monitor for growth
4. **Connection Pool Usage**: Should be <80% of max

### Logging

Cache operations are logged at different levels:

- `INFO`: Cache initialization, invalidation
- `DEBUG`: Cache hits, misses, writes
- `ERROR`: Connection errors, serialization failures

Configure logging level in your `.env`:
```env
LOG_LEVEL=DEBUG  # To see cache hit/miss details
```

## Troubleshooting

### Redis Connection Failed

**Symptom**: Logs show "Redis health check failed"

**Solutions**:
1. Ensure Redis is running: `docker ps | grep redis`
2. Check Redis URL in `.env`
3. Verify network connectivity: `redis-cli ping`

### Cache Always Missing

**Symptom**: Every query hits the database

**Solutions**:
1. Check `REDIS_ENABLED=true` in `.env`
2. Verify TTL is not too short
3. Check for cache invalidation being called too frequently

### High Memory Usage

**Symptom**: Redis memory grows continuously

**Solutions**:
1. Reduce TTL values for frequently changing data
2. Implement memory limit in Redis: `maxmemory 500mb`
3. Configure eviction policy: `maxmemory-policy allkeys-lru`

## Security Considerations

### Production Deployment

For production environments:

1. **Use Password Authentication**:
   ```env
   REDIS_PASSWORD=your-secure-password
   ```

2. **Use TLS Encryption**:
   ```env
   REDIS_URL=rediss://your-redis-host:6380/0
   ```

3. **Network Isolation**: Deploy Redis in a private network
4. **Firewall Rules**: Restrict access to application servers only

## Future Enhancements

Potential improvements outlined in the design:

- **Cache Warming**: Pre-populate cache on startup
- **Multi-Level Caching**: Add in-memory LRU cache
- **Cache Analytics**: Track usage patterns
- **Distributed Invalidation**: Pub/sub for multi-instance deployments
- **Smart Prefetching**: Predictive cache population

## Resources

- [Redis Documentation](https://redis.io/docs/)
- [redis-py Library](https://redis-py.readthedocs.io/)
- [Cache-Aside Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cache-aside)

## Support

For issues or questions:
1. Check the example file: `example_redis_cache.py`
2. Review test files for usage patterns
3. Check logs for error details
4. Verify Redis connection with `redis-cli`
