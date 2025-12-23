"""Hero character type for story generation."""

from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from src.prompts.character_types.base import BaseCharacter
from src.domain.value_objects import Language
from src.core.exceptions import ValidationError


@dataclass
class HeroCharacter(BaseCharacter):
    """Represents a hero protagonist in a story."""
    
    name: str
    age: int
    gender: str
    appearance: str
    personality_traits: List[str]
    strengths: List[str]
    interests: List[str]
    language: Language
    description: Optional[str] = None
    
    def __post_init__(self):
        """Validate hero character data on initialization."""
        self.validate()
    
    def validate(self) -> None:
        """Validate hero character data.
        
        Raises:
            ValidationError: If any required field is invalid
        """
        if not self.name or not self.name.strip():
            raise ValidationError("Hero name cannot be empty", field="name")
        
        if self.age < 1:
            raise ValidationError(
                "Hero age must be positive",
                field="age",
                details={"value": self.age}
            )
        
        if not self.gender or not self.gender.strip():
            raise ValidationError("Hero gender cannot be empty", field="gender")
        
        if not self.appearance or not self.appearance.strip():
            raise ValidationError("Hero appearance cannot be empty", field="appearance")
        
        if not self.personality_traits:
            raise ValidationError(
                "Hero must have at least one personality trait",
                field="personality_traits"
            )
        
        if not self.strengths:
            raise ValidationError(
                "Hero must have at least one strength",
                field="strengths"
            )
        
        if not self.interests:
            raise ValidationError(
                "Hero must have at least one interest",
                field="interests"
            )
    
    def get_description_data(self) -> Dict[str, Any]:
        """Get hero data for prompt rendering.
        
        Returns:
            Dictionary containing hero attributes for prompt building
        """
        return {
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "appearance": self.appearance,
            "personality_traits": self.personality_traits,
            "strengths": self.strengths,
            "interests": self.interests,
            "language": self.language,
            "description": self.description,
            "character_type": "hero"
        }
