"""Language component for prompt building."""

from src.prompts.components.base_component import BaseComponent, PromptContext
from src.domain.value_objects import Language


class LanguageComponent(BaseComponent):
    """Renders language specification for prompts."""
    
    def render(self, context: PromptContext) -> str:
        """Render language instruction.
        
        Args:
            context: Prompt context with language
            
        Returns:
            Formatted language instruction
        """
        if context.language == Language.RUSSIAN:
            return "Напиши сказку на русском языке."
        else:
            return "Write the story in English."
