"""Unit tests for cache strategies."""

import pytest
import json
from datetime import datetime
from src.infrastructure.cache.strategies import (
    HeroCacheStrategy,
    ChildCacheStrategy,
    StoryCacheStrategy,
)
from src.infrastructure.config.settings import CacheSettings
from src.domain.entities import Hero, Child, Story
from src.domain.value_objects import Language, Gender


@pytest.fixture
def cache_settings():
    """Create cache settings for testing."""
    return CacheSettings(
        hero_ttl=3600,
        child_ttl=1800,
        story_ttl=600,
        default_ttl=3600
    )


@pytest.fixture
def sample_hero():
    """Create a sample Hero entity for testing."""
    return Hero(
        id="hero-123",
        name="Captain Wonder",
        age=12,
        gender=Gender.MALE,
        appearance="Wears a blue cape",
        personality_traits=["brave", "kind"],
        interests=["flying", "helping"],
        strengths=["super strength", "speed"],
        language=Language.ENGLISH,
        created_at=datetime(2024, 1, 15, 10, 30, 0),
        updated_at=datetime(2024, 1, 15, 10, 30, 0),
    )


@pytest.fixture
def sample_child():
    """Create a sample Child entity for testing."""
    return Child(
        id="child-456",
        name="Emma",
        age=6,
        gender=Gender.FEMALE,
        interests=["unicorns", "fairies"],
        created_at=datetime(2024, 1, 20, 14, 0, 0),
        updated_at=datetime(2024, 1, 20, 14, 0, 0),
    )


@pytest.fixture
def sample_story():
    """Create a sample Story entity for testing."""
    from src.domain.value_objects import StoryLength, Rating
    from src.domain.entities import AudioFile
    
    story = Story(
        id="story-789",
        title="The Magic Garden",
        content="Once upon a time...",
        moral="kindness",
        language=Language.ENGLISH,
        child_id="child-456",
        child_name="Emma",
        child_age=6,
        child_gender="female",
        child_interests=["unicorns", "fairies"],
        story_length=StoryLength(minutes=5),
        rating=Rating(value=9),
        model_used="gpt-4",
        created_at=datetime(2024, 1, 21, 15, 0, 0),
        updated_at=datetime(2024, 1, 21, 15, 0, 0),
    )
    
    story.attach_audio(
        url="https://example.com/audio/story-789.mp3",
        provider="ElevenLabs",
        metadata={"voice": "female", "style": "narrative"}
    )
    
    return story


class TestHeroCacheStrategy:
    """Test HeroCacheStrategy."""
    
    def test_entity_type(self, cache_settings):
        """Test entity type identifier."""
        strategy = HeroCacheStrategy(cache_settings)
        assert strategy.entity_type == "hero"
    
    def test_default_ttl(self, cache_settings):
        """Test default TTL from settings."""
        strategy = HeroCacheStrategy(cache_settings)
        assert strategy.default_ttl == 3600
    
    def test_build_key_by_id(self, cache_settings):
        """Test building cache key for by_id operation."""
        strategy = HeroCacheStrategy(cache_settings)
        key = strategy.build_key("by_id", id="hero-123")
        assert key == "hero:hero-123"
    
    def test_build_key_by_language(self, cache_settings):
        """Test building cache key for by_language operation."""
        strategy = HeroCacheStrategy(cache_settings)
        key = strategy.build_key("by_language", language=Language.ENGLISH)
        assert key == "hero:lang:en"
    
    def test_build_key_by_language_string(self, cache_settings):
        """Test building cache key with language as string."""
        strategy = HeroCacheStrategy(cache_settings)
        key = strategy.build_key("by_language", language="ru")
        assert key == "hero:lang:ru"
    
    def test_build_key_by_name(self, cache_settings):
        """Test building cache key for by_name operation."""
        strategy = HeroCacheStrategy(cache_settings)
        key = strategy.build_key("by_name", name="Captain Wonder")
        assert key == "hero:name:Captain Wonder"
    
    def test_build_key_all(self, cache_settings):
        """Test building cache key for all operation."""
        strategy = HeroCacheStrategy(cache_settings)
        key = strategy.build_key("all")
        assert key == "hero:all"
    
    def test_serialize_hero(self, cache_settings, sample_hero):
        """Test serializing Hero entity."""
        strategy = HeroCacheStrategy(cache_settings)
        serialized = strategy.serialize(sample_hero)
        
        # Parse JSON to verify structure
        data = json.loads(serialized)
        
        assert "entity" in data
        assert "cached_at" in data
        assert "ttl" in data
        
        entity = data["entity"]
        assert entity["id"] == "hero-123"
        assert entity["name"] == "Captain Wonder"
        assert entity["age"] == 12
        assert entity["gender"] == "male"
        assert entity["language"] == "en"
        assert entity["personality_traits"] == ["brave", "kind"]
    
    def test_deserialize_hero(self, cache_settings, sample_hero):
        """Test deserializing Hero entity."""
        strategy = HeroCacheStrategy(cache_settings)
        
        # Serialize then deserialize
        serialized = strategy.serialize(sample_hero)
        deserialized = strategy.deserialize(serialized)
        
        assert deserialized.id == sample_hero.id
        assert deserialized.name == sample_hero.name
        assert deserialized.age == sample_hero.age
        assert deserialized.gender == sample_hero.gender
        assert deserialized.language == sample_hero.language
        assert deserialized.personality_traits == sample_hero.personality_traits
    
    def test_serialize_deserialize_roundtrip(self, cache_settings, sample_hero):
        """Test full roundtrip serialization."""
        strategy = HeroCacheStrategy(cache_settings)
        
        serialized = strategy.serialize(sample_hero)
        deserialized = strategy.deserialize(serialized)
        
        # Re-serialize to compare
        serialized_again = strategy.serialize(deserialized)
        
        # Both should produce equivalent JSON (excluding cached_at timestamp)
        data1 = json.loads(serialized)["entity"]
        data2 = json.loads(serialized_again)["entity"]
        
        assert data1 == data2


class TestChildCacheStrategy:
    """Test ChildCacheStrategy."""
    
    def test_entity_type(self, cache_settings):
        """Test entity type identifier."""
        strategy = ChildCacheStrategy(cache_settings)
        assert strategy.entity_type == "child"
    
    def test_default_ttl(self, cache_settings):
        """Test default TTL from settings."""
        strategy = ChildCacheStrategy(cache_settings)
        assert strategy.default_ttl == 1800
    
    def test_build_key_by_id(self, cache_settings):
        """Test building cache key for by_id operation."""
        strategy = ChildCacheStrategy(cache_settings)
        key = strategy.build_key("by_id", id="child-456")
        assert key == "child:child-456"
    
    def test_build_key_by_name(self, cache_settings):
        """Test building cache key for by_name operation."""
        strategy = ChildCacheStrategy(cache_settings)
        key = strategy.build_key("by_name", name="Emma")
        assert key == "child:name:Emma"
    
    def test_build_key_exact_match(self, cache_settings):
        """Test building cache key for exact_match operation."""
        strategy = ChildCacheStrategy(cache_settings)
        key = strategy.build_key("exact_match", name="Emma", age=6, gender=Gender.FEMALE)
        assert key == "child:exact:Emma:6:female"
    
    def test_serialize_child(self, cache_settings, sample_child):
        """Test serializing Child entity."""
        strategy = ChildCacheStrategy(cache_settings)
        serialized = strategy.serialize(sample_child)
        
        data = json.loads(serialized)
        entity = data["entity"]
        
        assert entity["id"] == "child-456"
        assert entity["name"] == "Emma"
        assert entity["age"] == 6
        assert entity["gender"] == "female"
        assert entity["interests"] == ["unicorns", "fairies"]
    
    def test_deserialize_child(self, cache_settings, sample_child):
        """Test deserializing Child entity."""
        strategy = ChildCacheStrategy(cache_settings)
        
        serialized = strategy.serialize(sample_child)
        deserialized = strategy.deserialize(serialized)
        
        assert deserialized.id == sample_child.id
        assert deserialized.name == sample_child.name
        assert deserialized.age == sample_child.age
        assert deserialized.gender == sample_child.gender
        assert deserialized.interests == sample_child.interests


class TestStoryCacheStrategy:
    """Test StoryCacheStrategy."""
    
    def test_entity_type(self, cache_settings):
        """Test entity type identifier."""
        strategy = StoryCacheStrategy(cache_settings)
        assert strategy.entity_type == "story"
    
    def test_default_ttl(self, cache_settings):
        """Test default TTL from settings."""
        strategy = StoryCacheStrategy(cache_settings)
        assert strategy.default_ttl == 600
    
    def test_build_key_by_id(self, cache_settings):
        """Test building cache key for by_id operation."""
        strategy = StoryCacheStrategy(cache_settings)
        key = strategy.build_key("by_id", id="story-789")
        assert key == "story:story-789"
    
    def test_build_key_by_child_id(self, cache_settings):
        """Test building cache key for by_child_id operation."""
        strategy = StoryCacheStrategy(cache_settings)
        key = strategy.build_key("by_child_id", child_id="child-456")
        assert key == "story:child:child-456"
    
    def test_build_key_by_child_name(self, cache_settings):
        """Test building cache key for by_child_name operation."""
        strategy = StoryCacheStrategy(cache_settings)
        key = strategy.build_key("by_child_name", child_name="Emma")
        assert key == "story:child_name:Emma"
    
    def test_build_key_by_language(self, cache_settings):
        """Test building cache key for by_language operation."""
        strategy = StoryCacheStrategy(cache_settings)
        key = strategy.build_key("by_language", language=Language.ENGLISH)
        assert key == "story:lang:en"
    
    def test_serialize_story(self, cache_settings, sample_story):
        """Test serializing Story entity."""
        strategy = StoryCacheStrategy(cache_settings)
        serialized = strategy.serialize(sample_story)
        
        data = json.loads(serialized)
        entity = data["entity"]
        
        assert entity["id"] == "story-789"
        assert entity["title"] == "The Magic Garden"
        assert entity["content"] == "Once upon a time..."
        assert entity["moral"] == "kindness"
        assert entity["language"] == "en"
        assert entity["child_id"] == "child-456"
        assert entity["story_length"] == 5
        assert entity["rating"] == 9
        assert entity["audio_file"]["url"] == "https://example.com/audio/story-789.mp3"
    
    def test_deserialize_story(self, cache_settings, sample_story):
        """Test deserializing Story entity."""
        strategy = StoryCacheStrategy(cache_settings)
        
        serialized = strategy.serialize(sample_story)
        deserialized = strategy.deserialize(serialized)
        
        assert deserialized.id == sample_story.id
        assert deserialized.title == sample_story.title
        assert deserialized.content == sample_story.content
        assert deserialized.language == sample_story.language
        assert deserialized.story_length.minutes == sample_story.story_length.minutes
        assert deserialized.rating.value == sample_story.rating.value
        assert deserialized.audio_file.url == sample_story.audio_file.url
    
    def test_serialize_story_without_audio(self, cache_settings):
        """Test serializing Story without audio file."""
        story = Story(
            id="story-simple",
            title="Simple Story",
            content="Content",
            moral="friendship",
            language=Language.ENGLISH,
        )
        
        strategy = StoryCacheStrategy(cache_settings)
        serialized = strategy.serialize(story)
        
        data = json.loads(serialized)
        entity = data["entity"]
        
        assert entity["audio_file"] is None
        assert entity["rating"] is None


class TestCacheStrategyBehavior:
    """Test general cache strategy behaviors."""
    
    def test_cache_on_read_default(self, cache_settings):
        """Test cache_on_read is True by default."""
        strategy = HeroCacheStrategy(cache_settings)
        assert strategy.cache_on_read is True
    
    def test_cache_on_write_default(self, cache_settings):
        """Test cache_on_write is True by default."""
        strategy = HeroCacheStrategy(cache_settings)
        assert strategy.cache_on_write is True
    
    def test_prepare_cache_entry(self, cache_settings, sample_hero):
        """Test _prepare_cache_entry adds metadata."""
        strategy = HeroCacheStrategy(cache_settings)
        entry = strategy._prepare_cache_entry(sample_hero)
        
        assert "entity" in entry
        assert "cached_at" in entry
        assert "ttl" in entry
        assert entry["ttl"] == 3600
    
    def test_extract_entity(self, cache_settings):
        """Test _extract_entity retrieves entity from cache entry."""
        strategy = HeroCacheStrategy(cache_settings)
        cache_entry = {
            "entity": {"name": "Test Hero"},
            "cached_at": "2024-01-20T10:00:00",
            "ttl": 3600
        }
        
        entity = strategy._extract_entity(cache_entry)
        assert entity == {"name": "Test Hero"}


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
