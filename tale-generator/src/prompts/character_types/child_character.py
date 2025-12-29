"""Child character type for story generation."""

from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from src.prompts.character_types.base import BaseCharacter
from src.core.exceptions import ValidationError
from src.utils.age_category_utils import normalize_age_category


@dataclass
class ChildCharacter(BaseCharacter):
    """Represents a child protagonist in a story."""
    
    name: str
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
    gender: str
    interests: List[str]
    age: Optional[int] = None  # Kept for backward compatibility
    description: Optional[str] = None
    
    def __post_init__(self):
        """Validate child character data on initialization."""
        self.validate()
    
    def validate(self) -> None:
        """Validate child character data.
        
        Raises:
            ValidationError: If any required field is invalid
        """
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
        
        if not self.gender or not self.gender.strip():
            raise ValidationError("Child gender cannot be empty", field="gender")
        
        if not self.interests:
            raise ValidationError(
                "Child must have at least one interest",
                field="interests"
            )
    
    def get_description_data(self) -> Dict[str, Any]:
        """Get child data for prompt rendering.
        
        Returns:
            Dictionary containing child attributes for prompt building
        """
        return {
            "name": self.name,
            "age_category": self.age_category,
            "age": self.age,  # For backward compatibility
            "gender": self.gender,
            "interests": self.interests,
            "description": self.description,
            "character_type": "child"
        }
