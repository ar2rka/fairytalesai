"""Database models for persistence layer."""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from datetime import datetime


class ChildDB(BaseModel):
    """Database model for child profiles."""
    id: Optional[str] = None
    name: str
    age: int  # Kept for backward compatibility, but age_category is primary
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
    gender: str
    interests: List[str]
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
    language: str
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class GenerationDB(BaseModel):
    """Database model for story generation tracking."""
    generation_id: str
    attempt_number: int
    model_used: str
    full_response: Optional[Dict[str, Any]] = None
    status: str  # 'pending', 'success', 'failed', 'timeout'
    prompt: str
    user_id: str
    story_type: str  # 'child', 'hero', 'combined'
    story_length: Optional[int] = None
    hero_appearance: Optional[str] = None
    relationship_description: Optional[str] = None
    moral: str
    error_message: Optional[str] = None
    created_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None


class StoryDB(BaseModel):
    """Database model for saved stories."""
    id: Optional[str] = None
    title: str
    content: str
    child_id: Optional[str] = None
    child_name: Optional[str] = None
    child_age: Optional[int] = None
    child_gender: Optional[str] = None
    child_interests: Optional[List[str]] = None
    hero_id: Optional[str] = None
    hero_name: Optional[str] = None
    hero_gender: Optional[str] = None
    language: str
    rating: Optional[int] = None
    audio_file_url: Optional[str] = None
    audio_provider: Optional[str] = None
    audio_generation_metadata: Optional[Dict[str, Any]] = None
    # User ID for authentication and authorization
    user_id: Optional[str] = None
    # Reference to generation record
    generation_id: str
    # Reference to parent story for continuation narratives
    parent_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class FreeStoryDB(BaseModel):
    """Database model for free publicly accessible stories."""
    id: Optional[str] = None
    title: str
    content: str
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
    language: str  # Language code: 'en' or 'ru'
    is_active: bool = True  # Whether the story is active and should be displayed
    created_at: Optional[datetime] = None
