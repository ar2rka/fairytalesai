"""Data Transfer Objects for API layer."""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, field_validator
from src.domain.value_objects import Language, Gender, StoryMoral
from src.utils.age_category_utils import normalize_age_category


# Request DTOs

class ChildProfileDTO(BaseModel):
    """Child profile data transfer object."""
    name: str = Field(..., description="Child's name")
    age_category: str = Field(..., description="Child's age category as string interval (e.g., '2-3 года', '4-5', '6-7 лет')")
    gender: Gender = Field(..., description="Child's gender")
    interests: List[str] = Field(..., min_length=1, description="Child's interests")
    
    @field_validator('age_category')
    @classmethod
    def validate_age_category(cls, v: str) -> str:
        """Normalize age category to standard format."""
        return normalize_age_category(v)


class StoryRequestDTO(BaseModel):
    """Story generation request DTO."""
    child: ChildProfileDTO = Field(..., description="Child profile")
    moral: Optional[StoryMoral] = Field(None, description="Predefined moral value")
    custom_moral: Optional[str] = Field(None, description="Custom moral value")
    language: Language = Field(default=Language.ENGLISH, description="Story language")
    story_length: Optional[int] = Field(default=5, ge=1, le=30, description="Story length in minutes")
    generate_audio: Optional[bool] = Field(default=False, description="Generate audio narration")
    voice_provider: Optional[str] = Field(None, description="Voice provider name")
    voice_options: Optional[Dict[str, Any]] = Field(None, description="Voice provider options")
    
    model_config = {
        "json_schema_extra": {
            "examples": [{
                "child": {
                    "name": "Emma",
                    "age": 7,
                    "gender": "female",
                    "interests": ["unicorns", "fairies", "princesses"]
                },
                "moral": "kindness",
                "language": "en",
                "story_length": 5,
                "generate_audio": False
            }]
        }
    }


class StoryRatingRequestDTO(BaseModel):
    """Story rating request DTO."""
    rating: int = Field(..., ge=1, le=10, description="Rating value (1-10)")


class ChildRequestDTO(BaseModel):
    """Child creation/update request DTO."""
    name: str = Field(..., description="Child's name")
    age_category: str = Field(..., description="Child's age category as string interval (e.g., '2-3 года', '4-5', '6-7 лет')")
    gender: str = Field(..., description="Child's gender")
    interests: List[str] = Field(..., min_length=1, description="Child's interests")
    
    @field_validator('age_category')
    @classmethod
    def validate_age_category(cls, v: str) -> str:
        """Normalize age category to standard format."""
        return normalize_age_category(v)


# Response DTOs

class StoryResponseDTO(BaseModel):
    """Story generation response DTO."""
    title: str = Field(..., description="Story title")
    content: str = Field(..., description="Story content")
    moral: str = Field(..., description="Moral value")
    language: Language = Field(..., description="Story language")
    story_length: Optional[int] = Field(None, description="Story length in minutes")
    audio_file_url: Optional[str] = Field(None, description="Audio file URL")
    
    model_config = {
        "json_schema_extra": {
            "examples": [{
                "title": "Emma and the Magic Garden",
                "content": "Once upon a time...",
                "moral": "kindness",
                "language": "en",
                "story_length": 5,
                "audio_file_url": None
            }]
        }
    }


class ChildResponseDTO(BaseModel):
    """Child profile response DTO."""
    id: str = Field(..., description="Child ID")
    name: str = Field(..., description="Child's name")
    age_category: str = Field(..., description="Child's age category as string interval (e.g., '2-3', '4-5', '6-7')")
    age: Optional[int] = Field(None, description="Child's age (calculated from category, for backward compatibility)")
    gender: str = Field(..., description="Child's gender")
    interests: List[str] = Field(..., description="Child's interests")
    created_at: Optional[str] = Field(None, description="Creation timestamp")
    updated_at: Optional[str] = Field(None, description="Last update timestamp")


class StoryDBResponseDTO(BaseModel):
    """Stored story response DTO."""
    id: str = Field(..., description="Story ID")
    title: str = Field(..., description="Story title")
    content: str = Field(..., description="Story content")
    moral: str = Field(..., description="Moral value")
    language: str = Field(..., description="Story language")
    child_id: Optional[str] = Field(None, description="Child ID")
    child_name: Optional[str] = Field(None, description="Child name")
    child_age: Optional[int] = Field(None, description="Child age")
    child_gender: Optional[str] = Field(None, description="Child gender")
    child_interests: Optional[List[str]] = Field(None, description="Child interests")
    story_length: Optional[int] = Field(None, description="Story length in minutes")
    rating: Optional[int] = Field(None, description="Story rating (1-10)")
    audio_file_url: Optional[str] = Field(None, description="Audio file URL")
    audio_provider: Optional[str] = Field(None, description="Audio provider")
    audio_generation_metadata: Optional[Dict[str, Any]] = Field(None, description="Audio metadata")
    model_used: Optional[str] = Field(None, description="AI model used")
    created_at: Optional[str] = Field(None, description="Creation timestamp")
    updated_at: Optional[str] = Field(None, description="Last update timestamp")


class ErrorResponseDTO(BaseModel):
    """Error response DTO."""
    error: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")


# New DTOs for story generation endpoint

class GenerateStoryRequestDTO(BaseModel):
    """Story generation request DTO for new endpoint."""
    language: str = Field(..., description="Story language (en or ru)")
    child_id: str = Field(..., description="Child ID (UUID)")
    story_type: str = Field(default="child", description="Story type: child, hero, or combined")
    hero_id: Optional[str] = Field(None, description="Hero ID (required for hero/combined stories)")
    story_length: Optional[int] = Field(default=5, ge=1, le=30, description="Story length in minutes")
    moral: Optional[str] = Field(None, description="Predefined moral value")
    custom_moral: Optional[str] = Field(None, description="Custom moral value")
    theme: Optional[str] = Field(None, description="Story theme / type (e.g. adventure, space, fantasy)")
    parent_id: Optional[str] = Field(None, description="Parent story ID for continuation narratives")
    generate_audio: Optional[bool] = Field(default=False, description="Generate audio narration")
    voice_provider: Optional[str] = Field(None, description="Voice provider name")
    voice_options: Optional[Dict[str, Any]] = Field(None, description="Voice provider options")
    
    model_config = {
        "json_schema_extra": {
            "examples": [{
                "language": "en",
                "child_id": "123e4567-e89b-12d3-a456-426614174000",
                "story_type": "combined",
                "hero_id": "987fcdeb-51a2-43f7-b123-9876543210ab",
                "moral": "kindness",
                "story_length": 5,
                "generate_audio": False
            }]
        }
    }


class ChildInfoDTO(BaseModel):
    """Child information DTO."""
    id: str = Field(..., description="Child ID")
    name: str = Field(..., description="Child name")
    age_category: str = Field(..., description="Child's age category as string interval (e.g., '2-3', '4-5', '6-7')")
    gender: str = Field(..., description="Child gender")
    interests: List[str] = Field(..., description="Child interests")


class HeroInfoDTO(BaseModel):
    """Hero information DTO."""
    id: str = Field(..., description="Hero ID")
    name: str = Field(..., description="Hero name")
    gender: str = Field(..., description="Hero gender")
    appearance: str = Field(..., description="Hero appearance")


class GenerateStoryResponseDTO(BaseModel):
    """Story generation response DTO for new endpoint."""
    id: str = Field(..., description="Generated story UUID")
    title: str = Field(..., description="Story title")
    content: str = Field(..., description="Story narrative content")
    moral: str = Field(..., description="Applied moral value")
    language: str = Field(..., description="Story language code")
    story_type: str = Field(..., description="Type of story (child, hero, combined)")
    story_length: int = Field(..., description="Story length in minutes")
    child: ChildInfoDTO = Field(..., description="Child information")
    hero: Optional[HeroInfoDTO] = Field(None, description="Hero information (if applicable)")
    relationship_description: Optional[str] = Field(None, description="Child-hero relationship (combined stories)")
    audio_file_url: Optional[str] = Field(None, description="Audio file URL")
    created_at: str = Field(..., description="Timestamp of creation")


class FreeStoryResponseDTO(BaseModel):
    """Free story response DTO for publicly accessible stories."""
    id: str = Field(..., description="Story ID")
    title: str = Field(..., description="Story title")
    content: str = Field(..., description="Story content")
    age_category: str = Field(..., description="Age category as string interval (e.g., '2-3', '4-5', '6-7')")
    language: str = Field(..., description="Language code: 'en' or 'ru'")
    created_at: str = Field(..., description="Creation timestamp")


class DailyFreeStoryResponseDTO(BaseModel):
    """Daily free story response DTO."""
    id: str = Field(..., description="Story ID")
    story_date: str = Field(..., description="Story date in YYYY-MM-DD format")
    title: str = Field(..., description="Заголовок истории")
    name: str = Field(..., description="Название истории")
    content: str = Field(..., description="Story content")
    moral: str = Field(..., description="Мораль истории")
    age_category: str = Field(..., description="Age category as string interval (e.g., '2-3', '4-5', '6-7')")
    language: str = Field(..., description="Language code: 'en' or 'ru'")
    likes_count: int = Field(default=0, description="Number of likes")
    dislikes_count: int = Field(default=0, description="Number of dislikes")
    user_reaction: Optional[str] = Field(None, description="User's reaction: 'like', 'dislike', or None")
    created_at: str = Field(..., description="Creation timestamp")


class DailyStoryReactionRequestDTO(BaseModel):
    """Request DTO for reacting to a daily story."""
    reaction_type: str = Field(..., description="Reaction type: 'like' or 'dislike'")
    
    @field_validator('reaction_type')
    @classmethod
    def validate_reaction_type(cls, v: str) -> str:
        """Validate reaction type."""
        if v not in ['like', 'dislike']:
            raise ValueError("reaction_type must be 'like' or 'dislike'")
        return v


class DailyStoryReactionResponseDTO(BaseModel):
    """Response DTO for story reaction."""
    story_id: str = Field(..., description="Story ID")
    reaction_type: Optional[str] = Field(None, description="User's reaction: 'like', 'dislike', or None")
    likes_count: int = Field(..., description="Total number of likes")
    dislikes_count: int = Field(..., description="Total number of dislikes")
