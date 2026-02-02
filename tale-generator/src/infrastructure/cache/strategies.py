"""Cache strategies for different entity types."""

import json
import logging
from abc import ABC, abstractmethod
from typing import Generic, TypeVar, Optional, Dict, Any, List
from datetime import datetime

from src.domain.entities import Hero, Child, Story
from src.domain.value_objects import Language, Gender
from src.infrastructure.config.settings import CacheSettings

logger = logging.getLogger(__name__)

T = TypeVar('T')


class CacheStrategy(ABC, Generic[T]):
    """Base cache strategy interface defining caching behavior for entities.
    
    This abstract class defines the contract for entity-specific caching strategies,
    including serialization, deserialization, and cache key generation.
    """
    
    def __init__(self, settings: CacheSettings):
        """Initialize cache strategy.
        
        Args:
            settings: Cache configuration settings
        """
        self.settings = settings
    
    @property
    @abstractmethod
    def entity_type(self) -> str:
        """Entity type identifier for cache keys.
        
        Returns:
            Entity type string (e.g., 'hero', 'child', 'story')
        """
        pass
    
    @property
    @abstractmethod
    def default_ttl(self) -> int:
        """Default time-to-live for cached entities in seconds.
        
        Returns:
            TTL in seconds
        """
        pass
    
    @property
    def cache_on_read(self) -> bool:
        """Whether to cache entities on read operations.
        
        Returns:
            True to enable read caching
        """
        return True
    
    @property
    def cache_on_write(self) -> bool:
        """Whether to cache entities on write operations.
        
        Returns:
            True to enable write caching
        """
        return True
    
    def build_key(self, operation: str, **params) -> str:
        """Generate cache key for the given operation and parameters.
        
        Args:
            operation: Operation type (e.g., 'by_id', 'by_language', 'all')
            **params: Operation-specific parameters
            
        Returns:
            Cache key string
        """
        if operation == "by_id":
            entity_id = params.get("id")
            return f"{self.entity_type}:{entity_id}"
        elif operation == "all":
            return f"{self.entity_type}:all"
        else:
            # Generic key pattern for custom operations
            param_str = ":".join(str(v) for v in params.values())
            return f"{self.entity_type}:{operation}:{param_str}"
    
    @abstractmethod
    def serialize(self, entity: T) -> str:
        """Convert entity to JSON string for caching.
        
        Args:
            entity: Entity to serialize
            
        Returns:
            JSON string representation
        """
        pass
    
    @abstractmethod
    def deserialize(self, data: str) -> T:
        """Convert JSON string to entity.
        
        Args:
            data: JSON string from cache
            
        Returns:
            Deserialized entity
        """
        pass
    
    def _prepare_cache_entry(self, entity: T) -> Dict[str, Any]:
        """Prepare cache entry with metadata.
        
        Args:
            entity: Entity to cache
            
        Returns:
            Dictionary with entity and metadata
        """
        return {
            "entity": entity,
            "cached_at": datetime.utcnow().isoformat(),
            "ttl": self.default_ttl
        }
    
    def _extract_entity(self, cache_entry: Dict[str, Any]) -> Any:
        """Extract entity from cache entry.
        
        Args:
            cache_entry: Cache entry dictionary
            
        Returns:
            Entity data
        """
        return cache_entry.get("entity")


class HeroCacheStrategy(CacheStrategy[Hero]):
    """Cache strategy for Hero entities."""
    
    @property
    def entity_type(self) -> str:
        """Entity type identifier."""
        return "hero"
    
    @property
    def default_ttl(self) -> int:
        """Default TTL for hero entities (1 hour)."""
        return self.settings.hero_ttl
    
    def build_key(self, operation: str, **params) -> str:
        """Generate cache key for hero operations.
        
        Args:
            operation: Operation type
            **params: Operation parameters
            
        Returns:
            Cache key string
        """
        if operation == "by_language":
            language = params.get("language")
            if hasattr(language, 'value'):
                language = language.value
            return f"{self.entity_type}:lang:{language}"
        elif operation == "by_name":
            name = params.get("name")
            return f"{self.entity_type}:name:{name}"
        else:
            return super().build_key(operation, **params)
    
    def serialize(self, entity: Hero) -> str:
        """Serialize Hero entity to JSON.
        
        Args:
            entity: Hero entity
            
        Returns:
            JSON string
        """
        try:
            # Convert Hero to dictionary
            hero_dict = {
                "id": entity.id,
                "name": entity.name,
                "age": entity.age,
                "gender": entity.gender.value if hasattr(entity.gender, 'value') else entity.gender,
                "appearance": entity.appearance,
                "personality_traits": entity.personality_traits,
                "interests": entity.interests,
                "strengths": entity.strengths,
                "language": entity.language.value if hasattr(entity.language, 'value') else entity.language,
                "created_at": entity.created_at.isoformat() if entity.created_at else None,
                "updated_at": entity.updated_at.isoformat() if entity.updated_at else None,
            }
            
            # Wrap in cache entry with metadata
            cache_entry = self._prepare_cache_entry(hero_dict)
            
            return json.dumps(cache_entry)
        except Exception as e:
            logger.error(f"Error serializing Hero entity: {str(e)}")
            raise
    
    def deserialize(self, data: str) -> Hero:
        """Deserialize JSON to Hero entity.
        
        Args:
            data: JSON string
            
        Returns:
            Hero entity
        """
        try:
            cache_entry = json.loads(data)
            hero_dict = self._extract_entity(cache_entry)
            
            # Convert dictionary back to Hero
            return Hero(
                id=hero_dict.get("id"),
                name=hero_dict["name"],
                age=hero_dict["age"],
                gender=Gender(hero_dict["gender"]) if isinstance(hero_dict["gender"], str) else hero_dict["gender"],
                appearance=hero_dict["appearance"],
                personality_traits=hero_dict["personality_traits"],
                interests=hero_dict["interests"],
                strengths=hero_dict["strengths"],
                language=Language(hero_dict["language"]) if isinstance(hero_dict["language"], str) else hero_dict["language"],
                created_at=datetime.fromisoformat(hero_dict["created_at"]) if hero_dict.get("created_at") else None,
                updated_at=datetime.fromisoformat(hero_dict["updated_at"]) if hero_dict.get("updated_at") else None,
            )
        except Exception as e:
            logger.error(f"Error deserializing Hero entity: {str(e)}")
            raise


class ChildCacheStrategy(CacheStrategy[Child]):
    """Cache strategy for Child entities."""
    
    @property
    def entity_type(self) -> str:
        """Entity type identifier."""
        return "child"
    
    @property
    def default_ttl(self) -> int:
        """Default TTL for child entities (30 minutes)."""
        return self.settings.child_ttl
    
    def build_key(self, operation: str, **params) -> str:
        """Generate cache key for child operations.
        
        Args:
            operation: Operation type
            **params: Operation parameters
            
        Returns:
            Cache key string
        """
        if operation == "by_name":
            name = params.get("name")
            return f"{self.entity_type}:name:{name}"
        elif operation == "exact_match":
            name = params.get("name")
            age = params.get("age")
            gender = params.get("gender")
            if hasattr(gender, 'value'):
                gender = gender.value
            return f"{self.entity_type}:exact:{name}:{age}:{gender}"
        else:
            return super().build_key(operation, **params)
    
    def serialize(self, entity: Child) -> str:
        """Serialize Child entity to JSON.
        
        Args:
            entity: Child entity
            
        Returns:
            JSON string
        """
        try:
            child_dict = {
                "id": entity.id,
                "name": entity.name,
                "age_category": entity.age_category,
                "age": entity.age,
                "gender": entity.gender.value if hasattr(entity.gender, 'value') else entity.gender,
                "interests": entity.interests,
                "created_at": entity.created_at.isoformat() if entity.created_at else None,
                "updated_at": entity.updated_at.isoformat() if entity.updated_at else None,
            }
            
            cache_entry = self._prepare_cache_entry(child_dict)
            return json.dumps(cache_entry)
        except Exception as e:
            logger.error(f"Error serializing Child entity: {str(e)}")
            raise
    
    def deserialize(self, data: str) -> Child:
        """Deserialize JSON to Child entity.
        
        Args:
            data: JSON string
            
        Returns:
            Child entity
        """
        try:
            cache_entry = json.loads(data)
            child_dict = self._extract_entity(cache_entry)
            
            return Child(
                id=child_dict.get("id"),
                name=child_dict["name"],
                age_category=child_dict.get("age_category", "3-5"),  # Default for backward compatibility
                age=child_dict.get("age"),
                gender=Gender(child_dict["gender"]) if isinstance(child_dict["gender"], str) else child_dict["gender"],
                interests=child_dict["interests"],
                created_at=datetime.fromisoformat(child_dict["created_at"]) if child_dict.get("created_at") else None,
                updated_at=datetime.fromisoformat(child_dict["updated_at"]) if child_dict.get("updated_at") else None,
            )
        except Exception as e:
            logger.error(f"Error deserializing Child entity: {str(e)}")
            raise


class StoryCacheStrategy(CacheStrategy[Story]):
    """Cache strategy for Story entities."""
    
    @property
    def entity_type(self) -> str:
        """Entity type identifier."""
        return "story"
    
    @property
    def default_ttl(self) -> int:
        """Default TTL for story entities (10 minutes)."""
        return self.settings.story_ttl
    
    def build_key(self, operation: str, **params) -> str:
        """Generate cache key for story operations.
        
        Args:
            operation: Operation type
            **params: Operation parameters
            
        Returns:
            Cache key string
        """
        if operation == "by_child_id":
            child_id = params.get("child_id")
            return f"{self.entity_type}:child:{child_id}"
        elif operation == "by_child_name":
            child_name = params.get("child_name")
            return f"{self.entity_type}:child_name:{child_name}"
        elif operation == "by_language":
            language = params.get("language")
            if hasattr(language, 'value'):
                language = language.value
            return f"{self.entity_type}:lang:{language}"
        else:
            return super().build_key(operation, **params)
    
    def serialize(self, entity: Story) -> str:
        """Serialize Story entity to JSON.
        
        Args:
            entity: Story entity
            
        Returns:
            JSON string
        """
        try:
            story_dict = {
                "id": entity.id,
                "title": entity.title,
                "content": entity.content,
                "moral": entity.moral,
                "language": entity.language.value if hasattr(entity.language, 'value') else entity.language,
                "child_id": entity.child_id,
                "child_name": entity.child_name,
                "age_category": entity.age_category,
                "child_gender": entity.child_gender,
                "child_interests": entity.child_interests,
                "story_length": entity.story_length.minutes if entity.story_length else None,
                "rating": entity.rating.value if entity.rating else None,
                "audio_file": {
                    "url": entity.audio_file.url,
                    "provider": entity.audio_file.provider,
                    "metadata": entity.audio_file.metadata
                } if entity.audio_file else None,
                "model_used": entity.model_used,
                "full_response": entity.full_response,
                "generation_info": entity.generation_info,
                "created_at": entity.created_at.isoformat() if entity.created_at else None,
                "updated_at": entity.updated_at.isoformat() if entity.updated_at else None,
            }
            
            cache_entry = self._prepare_cache_entry(story_dict)
            return json.dumps(cache_entry)
        except Exception as e:
            logger.error(f"Error serializing Story entity: {str(e)}")
            raise
    
    def deserialize(self, data: str) -> Story:
        """Deserialize JSON to Story entity.
        
        Args:
            data: JSON string
            
        Returns:
            Story entity
        """
        try:
            cache_entry = json.loads(data)
            story_dict = self._extract_entity(cache_entry)
            
            # Import here to avoid circular dependencies
            from src.domain.value_objects import StoryLength, Rating
            from src.domain.entities import AudioFile
            
            # Create Story entity
            story = Story(
                id=story_dict.get("id"),
                title=story_dict["title"],
                content=story_dict["content"],
                moral=story_dict["moral"],
                language=Language(story_dict["language"]) if isinstance(story_dict["language"], str) else story_dict["language"],
                child_id=story_dict.get("child_id"),
                child_name=story_dict.get("child_name"),
                age_category=story_dict.get("age_category"),
                child_gender=story_dict.get("child_gender"),
                child_interests=story_dict.get("child_interests"),
                story_length=StoryLength(minutes=story_dict["story_length"]) if story_dict.get("story_length") else None,
                rating=Rating(value=story_dict["rating"]) if story_dict.get("rating") else None,
                audio_file=AudioFile(**story_dict["audio_file"]) if story_dict.get("audio_file") else None,
                model_used=story_dict.get("model_used"),
                full_response=story_dict.get("full_response"),
                generation_info=story_dict.get("generation_info"),
                created_at=datetime.fromisoformat(story_dict["created_at"]) if story_dict.get("created_at") else None,
                updated_at=datetime.fromisoformat(story_dict["updated_at"]) if story_dict.get("updated_at") else None,
            )
            
            return story
        except Exception as e:
            logger.error(f"Error deserializing Story entity: {str(e)}")
            raise
