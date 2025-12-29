"""Domain entities for the tale generator."""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime
from src.domain.value_objects import Language, Gender, StoryMoral, Rating, StoryLength
from src.core.exceptions import ValidationError
from src.utils.age_category_utils import normalize_age_category, calculate_age_from_category


@dataclass
class Child:
    """Child entity representing a child profile."""
    
    name: str
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
    gender: Gender
    interests: List[str]
    age: Optional[int] = None  # Kept for backward compatibility, calculated from age_category
    id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate child entity."""
        if not self.name or not self.name.strip():
            raise ValidationError("Child name cannot be empty", field="name")
        
        # Normalize age category
        try:
            self.age_category = normalize_age_category(self.age_category)
        except ValueError as e:
            raise ValidationError(
                f"Invalid age_category: {str(e)}",
                field="age_category",
                details={"value": self.age_category}
            )
        
        # Calculate age from category if not provided
        if self.age is None:
            self.age = calculate_age_from_category(self.age_category)
        
        if not self.interests:
            raise ValidationError("Child must have at least one interest", field="interests")
    
    def add_interest(self, interest: str) -> None:
        """Add an interest to the child.
        
        Args:
            interest: Interest to add
        """
        if interest and interest not in self.interests:
            self.interests.append(interest)
            if self.updated_at is not None:
                self.updated_at = datetime.now()
    
    def remove_interest(self, interest: str) -> None:
        """Remove an interest from the child.
        
        Args:
            interest: Interest to remove
        """
        if interest in self.interests:
            self.interests.remove(interest)
            if self.updated_at is not None:
                self.updated_at = datetime.now()


@dataclass
class Hero:
    """Hero entity representing a story hero."""
    
    name: str
    age: int
    gender: Gender
    appearance: str
    personality_traits: List[str]
    interests: List[str]
    strengths: List[str]
    language: Language
    id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate hero entity."""
        if not self.name or not self.name.strip():
            raise ValidationError("Hero name cannot be empty", field="name")
        
        if self.age < 1:
            raise ValidationError("Hero age must be positive", field="age")
        
        if not self.appearance or not self.appearance.strip():
            raise ValidationError("Hero appearance cannot be empty", field="appearance")
        
        if not self.personality_traits:
            raise ValidationError(
                "Hero must have at least one personality trait",
                field="personality_traits"
            )
        
        if not self.strengths:
            raise ValidationError("Hero must have at least one strength", field="strengths")


@dataclass
class AudioFile:
    """Audio file entity for story narration."""
    
    url: str
    provider: str
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __post_init__(self):
        """Validate audio file."""
        if not self.url or not self.url.strip():
            raise ValidationError("Audio file URL cannot be empty", field="audio_file_url")
        
        if not self.provider or not self.provider.strip():
            raise ValidationError("Audio provider cannot be empty", field="audio_provider")


@dataclass
class Story:
    """Story entity representing a generated story."""
    
    title: str
    content: str
    moral: str
    language: Language
    story_type: str = "child"  # child, hero, or combined
    child_id: Optional[str] = None
    child_name: Optional[str] = None
    child_age: Optional[int] = None
    child_gender: Optional[str] = None
    child_interests: Optional[List[str]] = None
    hero_id: Optional[str] = None
    hero_name: Optional[str] = None
    hero_gender: Optional[str] = None
    hero_appearance: Optional[str] = None
    relationship_description: Optional[str] = None
    story_length: Optional[StoryLength] = None
    rating: Optional[Rating] = None
    audio_file: Optional[AudioFile] = None
    model_used: Optional[str] = None
    full_response: Optional[Dict[str, Any]] = None
    generation_info: Optional[Dict[str, Any]] = None
    id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
    def __post_init__(self):
        """Validate story entity."""
        if not self.title or not self.title.strip():
            raise ValidationError("Story title cannot be empty", field="title")
        
        if not self.content or not self.content.strip():
            raise ValidationError("Story content cannot be empty", field="content")
        
        if not self.moral or not self.moral.strip():
            raise ValidationError("Story moral cannot be empty", field="moral")
    
    def rate(self, rating_value: int) -> None:
        """Rate the story.
        
        Args:
            rating_value: Rating value (1-10)
        """
        self.rating = Rating(value=rating_value)
        if self.updated_at is not None:
            self.updated_at = datetime.now()
    
    def attach_audio(self, url: str, provider: str, metadata: Optional[Dict[str, Any]] = None) -> None:
        """Attach audio file to the story.
        
        Args:
            url: Audio file URL
            provider: Audio provider name
            metadata: Additional metadata
        """
        self.audio_file = AudioFile(
            url=url,
            provider=provider,
            metadata=metadata or {}
        )
        if self.updated_at is not None:
            self.updated_at = datetime.now()
    
    def has_audio(self) -> bool:
        """Check if story has audio attached.
        
        Returns:
            True if audio is attached
        """
        return self.audio_file is not None
    
    def is_rated(self) -> bool:
        """Check if story has been rated.
        
        Returns:
            True if story is rated
        """
        return self.rating is not None
    
    @property
    def word_count(self) -> int:
        """Calculate approximate word count.
        
        Returns:
            Number of words in story content
        """
        return len(self.content.split())
    
    def extract_title_from_content(self) -> str:
        """Extract title from story content.
        
        Returns:
            Extracted title or first line
        """
        lines = self.content.strip().split('\n')
        if lines:
            title = lines[0].replace('#', '').strip()
            return title if title else "Untitled Story"
        return "Untitled Story"
