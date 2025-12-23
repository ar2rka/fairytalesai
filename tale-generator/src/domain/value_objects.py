"""Domain value objects."""

from enum import StrEnum
from typing import Dict
from dataclasses import dataclass
from src.core.exceptions import ValidationError
from src.core.constants import MIN_RATING, MAX_RATING, READING_SPEED_WPM


class Language(StrEnum):
    """Supported languages for story generation."""
    ENGLISH = "en"
    RUSSIAN = "ru"
    
    @property
    def display_name(self) -> str:
        """Get display name for the language."""
        return {
            "en": "English",
            "ru": "Russian"
        }.get(self.value, self.value)
    
    @classmethod
    def from_code(cls, code: str) -> "Language":
        """Create Language from code string.
        
        Args:
            code: Language code (en, ru)
            
        Returns:
            Language instance
            
        Raises:
            ValidationError: If language code is invalid
        """
        try:
            return cls(code.lower())
        except ValueError:
            raise ValidationError(
                f"Invalid language code: {code}",
                field="language",
                details={"supported": [lang.value for lang in cls]}
            )


class Gender(StrEnum):
    """Gender options for profiles."""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"
    
    def translate(self, language: Language) -> str:
        """Translate gender to specified language.
        
        Args:
            language: Target language
            
        Returns:
            Translated gender string
        """
        translations: Dict[Language, Dict[str, str]] = {
            Language.RUSSIAN: {
                "male": "мальчик",
                "female": "девочка",
                "other": "ребенок"
            },
            Language.ENGLISH: {
                "male": "male",
                "female": "female",
                "other": "other"
            }
        }
        return translations.get(language, {}).get(self.value, self.value)


class StoryMoral(StrEnum):
    """Predefined moral values for stories."""
    KINDNESS = "kindness"
    HONESTY = "honesty"
    BRAVERY = "bravery"
    FRIENDSHIP = "friendship"
    PERSEVERANCE = "perseverance"
    EMPATHY = "empathy"
    RESPECT = "respect"
    RESPONSIBILITY = "responsibility"
    
    @property
    def description(self) -> str:
        """Get description of the moral value."""
        descriptions = {
            "kindness": "Teaching kindness and compassion",
            "honesty": "Emphasizing truthfulness and integrity",
            "bravery": "Encouraging courage and facing fears",
            "friendship": "Celebrating friendship and loyalty",
            "perseverance": "Promoting determination and persistence",
            "empathy": "Developing understanding and compassion",
            "respect": "Fostering respect for others",
            "responsibility": "Teaching accountability and duty"
        }
        return descriptions.get(self.value, self.value)
    
    def translate(self, language: Language) -> str:
        """Translate moral to specified language.
        
        Args:
            language: Target language
            
        Returns:
            Translated moral string
        """
        translations: Dict[Language, Dict[str, str]] = {
            Language.RUSSIAN: {
                "kindness": "доброта",
                "honesty": "честность",
                "bravery": "храбрость",
                "friendship": "дружба",
                "perseverance": "настойчивость",
                "empathy": "сочувствие",
                "respect": "уважение",
                "responsibility": "ответственность"
            },
            Language.ENGLISH: {
                "kindness": "kindness",
                "honesty": "honesty",
                "bravery": "bravery",
                "friendship": "friendship",
                "perseverance": "perseverance",
                "empathy": "empathy",
                "respect": "respect",
                "responsibility": "responsibility"
            }
        }
        return translations.get(language, {}).get(self.value, self.value)


@dataclass(frozen=True)
class Rating:
    """Story rating value object (1-10)."""
    value: int
    
    def __post_init__(self):
        """Validate rating value."""
        if not MIN_RATING <= self.value <= MAX_RATING:
            raise ValidationError(
                f"Rating must be between {MIN_RATING} and {MAX_RATING}",
                field="rating",
                details={"value": self.value, "min": MIN_RATING, "max": MAX_RATING}
            )
    
    def __int__(self) -> int:
        """Convert to int."""
        return self.value
    
    def __str__(self) -> str:
        """String representation."""
        return f"{self.value}/10"


@dataclass(frozen=True)
class StoryLength:
    """Story length value object with word count calculation."""
    minutes: int
    
    def __post_init__(self):
        """Validate story length."""
        if self.minutes <= 0:
            raise ValidationError(
                "Story length must be positive",
                field="story_length",
                details={"value": self.minutes}
            )
    
    @property
    def word_count(self) -> int:
        """Calculate approximate word count based on reading speed.
        
        Returns:
            Approximate word count
        """
        return self.minutes * READING_SPEED_WPM
    
    def __int__(self) -> int:
        """Convert to int (minutes)."""
        return self.minutes
    
    def __str__(self) -> str:
        """String representation."""
        return f"{self.minutes} minutes (~{self.word_count} words)"
