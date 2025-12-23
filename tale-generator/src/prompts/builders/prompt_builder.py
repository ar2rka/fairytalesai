"""Prompt builder for assembling story prompts from components."""

from typing import Optional, List
from src.prompts.character_types.base import BaseCharacter
from src.prompts.components.base_component import BaseComponent, PromptContext
from src.prompts.components import (
    CharacterDescriptionComponent,
    MoralComponent,
    LengthComponent,
    EndingComponent,
    LanguageComponent
)
from src.domain.value_objects import Language
from src.core.exceptions import ValidationError
from src.core.constants import READING_SPEED_WPM


class PromptBuilder:
    """Base builder for assembling story prompts from components."""
    
    def __init__(self):
        """Initialize the prompt builder."""
        self._character: Optional[BaseCharacter] = None
        self._moral: Optional[str] = None
        self._language: Language = Language.ENGLISH
        self._story_length: int = 5  # default 5 minutes
        self._components: List[BaseComponent] = []
        self._custom_components: List[BaseComponent] = []
    
    def set_character(self, character: BaseCharacter) -> "PromptBuilder":
        """Set the character for the story.
        
        Args:
            character: Character instance (ChildCharacter, HeroCharacter, or CombinedCharacter)
            
        Returns:
            Self for method chaining
        """
        self._character = character
        return self
    
    def set_moral(self, moral: str) -> "PromptBuilder":
        """Set the moral value for the story.
        
        Args:
            moral: Moral value (e.g., "kindness", "honesty")
            
        Returns:
            Self for method chaining
        """
        self._moral = moral
        return self
    
    def set_language(self, language: Language) -> "PromptBuilder":
        """Set the target language for the story.
        
        Args:
            language: Target language
            
        Returns:
            Self for method chaining
        """
        self._language = language
        return self
    
    def set_story_length(self, minutes: int) -> "PromptBuilder":
        """Set the desired story length in minutes.
        
        Args:
            minutes: Story length in minutes
            
        Returns:
            Self for method chaining
        """
        if minutes <= 0:
            raise ValidationError(
                "Story length must be positive",
                field="story_length",
                details={"value": minutes}
            )
        self._story_length = minutes
        return self
    
    def add_component(self, component: BaseComponent) -> "PromptBuilder":
        """Add a custom component to the builder.
        
        Args:
            component: Component instance
            
        Returns:
            Self for method chaining
        """
        self._custom_components.append(component)
        return self
    
    def _initialize_default_components(self) -> None:
        """Initialize default components for prompt building."""
        self._components = [
            CharacterDescriptionComponent(),
            MoralComponent(),
            LengthComponent(),
            EndingComponent(),
            LanguageComponent()
        ]
    
    def _validate_state(self) -> None:
        """Validate that all required data is set.
        
        Raises:
            ValidationError: If required data is missing
        """
        if self._character is None:
            raise ValidationError("Character must be set before building prompt", field="character")
        
        if self._moral is None or not self._moral.strip():
            raise ValidationError("Moral must be set before building prompt", field="moral")
        
        # Validate character
        self._character.validate()
    
    def _create_context(self) -> PromptContext:
        """Create prompt context from builder state.
        
        Returns:
            PromptContext instance
        """
        word_count = self._story_length * READING_SPEED_WPM
        
        return PromptContext(
            character=self._character,
            moral=self._moral,
            language=self._language,
            story_length=self._story_length,
            word_count=word_count
        )
    
    def build(self) -> str:
        """Build the complete prompt from components.
        
        Returns:
            Assembled prompt string
            
        Raises:
            ValidationError: If builder state is invalid
        """
        self._validate_state()
        self._initialize_default_components()
        
        # Create context
        context = self._create_context()
        
        # Combine default and custom components
        all_components = self._components + self._custom_components
        
        # Render all components
        prompt_parts = []
        for component in all_components:
            if component.validate(context):
                rendered = component.render(context)
                if rendered:
                    prompt_parts.append(rendered)
        
        # Join parts with double newline for readability
        return "\n\n".join(prompt_parts).strip()
    
    def reset(self) -> "PromptBuilder":
        """Reset the builder to initial state.
        
        Returns:
            Self for method chaining
        """
        self._character = None
        self._moral = None
        self._language = Language.ENGLISH
        self._story_length = 5
        self._components = []
        self._custom_components = []
        return self
