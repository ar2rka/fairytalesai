"""Combined character type for story generation."""

from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from src.prompts.character_types.base import BaseCharacter
from src.prompts.character_types.child_character import ChildCharacter
from src.prompts.character_types.hero_character import HeroCharacter
from src.core.exceptions import ValidationError


@dataclass
class CombinedCharacter(BaseCharacter):
    """Represents both a child and hero in the same story."""
    
    child: ChildCharacter
    hero: HeroCharacter
    relationship: Optional[str] = None
    
    def __post_init__(self):
        """Validate combined character data on initialization."""
        self.validate()
    
    @property
    def name(self) -> str:
        """Get primary character name (child's name)."""
        return self.child.name
    
    @property
    def age(self) -> int:
        """Get primary character age (child's age) - for backward compatibility."""
        return self.child.age if self.child.age else 4
    
    @property
    def age_category(self) -> str:
        """Get primary character age category (child's age category)."""
        return self.child.age_category
    
    @property
    def gender(self) -> str:
        """Get primary character gender (child's gender)."""
        return self.child.gender
    
    def validate(self) -> None:
        """Validate combined character data.
        
        Raises:
            ValidationError: If any component is invalid
        """
        if not isinstance(self.child, ChildCharacter):
            raise ValidationError(
                "Child must be a ChildCharacter instance",
                field="child"
            )
        
        if not isinstance(self.hero, HeroCharacter):
            raise ValidationError(
                "Hero must be a HeroCharacter instance",
                field="hero"
            )
        
        # Validate both characters
        self.child.validate()
        self.hero.validate()
    
    def get_merged_interests(self) -> List[str]:
        """Combine interests from both child and hero.
        
        Returns:
            List of unique interests from both characters
        """
        # Combine and deduplicate interests
        combined = list(set(self.child.interests + self.hero.interests))
        return combined
    
    def get_description_data(self) -> Dict[str, Any]:
        """Get combined character data for prompt rendering.
        
        Returns:
            Dictionary containing both child and hero attributes
        """
        return {
            "child": self.child.get_description_data(),
            "hero": self.hero.get_description_data(),
            "relationship": self.relationship,
            "merged_interests": self.get_merged_interests(),
            "character_type": "combined"
        }
