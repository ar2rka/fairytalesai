"""Data models for the tale generator API."""

from enum import StrEnum
from typing import Optional, List, Any, Dict
from pydantic import BaseModel, Field
from datetime import datetime


class Gender(StrEnum):
    """Gender options for child profiles."""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class Language(StrEnum):
    """Supported languages for story generation."""
    ENGLISH = "en"
    RUSSIAN = "ru"


class ChildProfile(BaseModel):
    """Information about the child for story generation."""
    name: str
    age_category: str
    gender: Gender
    interests: List[str]


class StoryMoral(StrEnum):
    """Predefined moral values for stories."""
    KINDNESS = "kindness"
    HONESTY = "honesty"
    BRAVE = "bravery"
    FRIENDSHIP = "friendship"
    PERSEVERANCE = "perseverance"
    EMPATHY = "empathy"
    RESPECT = "respect"
    RESPONSIBILITY = "responsibility"


class StoryRequest(BaseModel):
    """Request model for story generation."""
    child: ChildProfile
    moral: Optional[StoryMoral] = None
    custom_moral: Optional[str] = None
    language: Language = Language.ENGLISH
    story_length: Optional[int] = None
    generate_audio: Optional[bool] = False
    voice_provider: Optional[str] = None
    voice_options: Optional[Dict[str, Any]] = None


class StoryResponse(BaseModel):
    """Response model for generated stories."""
    title: str
    content: str
    moral: str
    language: Language
    story_length: Optional[int] = None
    audio_file_url: Optional[str] = None


# Database models
class ChildDB(BaseModel):
    """Database model for child profiles."""
    id: Optional[str] = None
    name: str
    age_category: str
    gender: str
    interests: List[str]
    user_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class HeroDB(BaseModel):
    """Database model for hero profiles."""
    id: Optional[str] = None
    name: str
    gender: str
    appearance: str
    personality_traits: List[str]
    interests: List[str]
    strengths: List[str]
    language: Language = Language.ENGLISH
    user_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class StoryDB(BaseModel):
    """Database model for saved stories."""
    id: Optional[str] = None
    title: str
    content: str
    summary: Optional[str] = None
    moral: Optional[str] = None
    # Story type discriminator: child, hero, or combined
    story_type: Optional[str] = "child"
    # Reference to child instead of storing child data directly
    child_id: Optional[str] = None
    child_name: Optional[str] = None
    child_age_category: Optional[str] = None
    child_gender: Optional[str] = None
    child_interests: Optional[List[str]] = None
    # Reference to hero for hero and combined stories
    hero_id: Optional[str] = None
    language: Language = Language.ENGLISH
    rating: Optional[int] = Field(None, ge=1, le=10)
    audio_file_url: Optional[str] = None
    # User ID for authentication and authorization
    user_id: Optional[str] = None
    # Status: new, read, archived
    status: str = "new"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    generation_id: str
    # Reference to parent story for continuation narratives
    parent_id: Optional[str] = None


class StoryRatingRequest(BaseModel):
    """Request model for rating a story."""
    rating: int = Field(..., ge=1, le=10)


class DailyFreeStoryDB(BaseModel):
    """Database model for daily free stories."""
    id: Optional[str] = None
    story_date: str  # Date in YYYY-MM-DD format
    title: str  # Заголовок истории
    name: str  # Название истории
    content: str
    moral: str  # Мораль истории
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7')
    language: Language = Language.ENGLISH
    is_active: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class DailyStoryReactionRequest(BaseModel):
    """Request model for reacting to a daily story (like/dislike)."""
    reaction_type: str = Field(..., description="Reaction type: 'like' or 'dislike'")