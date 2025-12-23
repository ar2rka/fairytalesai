# Quick Start: Redis Caching

Get Redis caching running in **5 minutes**!

## Step 1: Start Redis (30 seconds)

```bash
# Start Redis using Docker
docker run -d -p 6379:6379 --name tale-redis redis:latest

# Verify it's running
docker ps | grep tale-redis
```

## Step 2: Install Redis Python Library (30 seconds)

```bash
# Using UV (recommended)
uv add redis

# Or using pip
pip install redis>=5.0.0
```

## Step 3: Configure Environment (1 minute)

Add to your `.env` file:

```env
REDIS_URL=redis://localhost:6379/0
REDIS_ENABLED=true
CACHE_HERO_TTL=3600
```

Or copy the full example:
```bash
cat .env.example.redis >> .env
```

## Step 4: Test the Setup (1 minute)

```bash
# Test Redis connection
redis-cli ping
# Should output: PONG

# Run the comprehensive example
uv run python example_redis_cache.py
```

## Step 5: Use in Your Code (2 minutes)

```python
from src.infrastructure.config.settings import get_settings
from src.infrastructure.cache import (
    CacheService,
    CachedRepository,
    HeroCacheStrategy
)

# One-time setup
settings = get_settings()
cache_service = CacheService(settings.cache)
hero_strategy = HeroCacheStrategy(settings.cache)

# Wrap your repository
cached_hero_repo = CachedRepository(
    base_repository=your_existing_hero_repository,
    cache_service=cache_service,
    cache_strategy=hero_strategy
)

# Use it! (no code changes needed)
hero = cached_hero_repo.find_by_id("hero-123")  # First call: DB query + cache
hero = cached_hero_repo.find_by_id("hero-123")  # Second call: cache only!
```

## That's It! 🎉

Your caching system is now active. You should see:
- ✅ Faster query responses (90%+ improvement)
- ✅ Reduced database load
- ✅ Automatic cache invalidation on updates

## Verify It's Working

Check your application logs for:
```
INFO - Redis cache initialized successfully
DEBUG - Cache miss for key: hero:hero-123
DEBUG - Cached hero:hero-123
DEBUG - Cache hit for key: hero:hero-123
```

## Common Issues

### "Connection refused"
**Solution**: Make sure Redis is running
```bash
docker start tale-redis
```

### "No module named 'redis'"
**Solution**: Install the redis library
```bash
uv add redis
```

### "Cache not working"
**Solution**: Check `.env` has `REDIS_ENABLED=true`

## Next Steps

- 📖 Read full documentation: `REDIS_CACHE_README.md`
- 🧪 Run tests: `uv run pytest test_cache*.py -v`
- 📊 Monitor cache stats in your application
- 🚀 Enable caching for Child and Story entities

## Stop Redis

When you're done:
```bash
docker stop tale-redis
```

To remove completely:
```bash
docker stop tale-redis && docker rm tale-redis
```

## Production Deployment

For production, add:
```env
REDIS_URL=rediss://your-redis-host:6380/0
REDIS_PASSWORD=your-secure-password
REDIS_MAX_CONNECTIONS=50
```

See `REDIS_CACHE_README.md` for complete production setup guide.
