"""Length component for prompt building."""

from src.prompts.components.base_component import BaseComponent, PromptContext
from src.domain.value_objects import Language


class LengthComponent(BaseComponent):
    """Renders story length instructions for prompts."""
    
    def render(self, context: PromptContext) -> str:
        """Render length instruction.
        
        Args:
            context: Prompt context with word count
            
        Returns:
            Formatted length instruction
        """
        if context.language == Language.RUSSIAN:
            return f"Сделай сказку увлекательной, воображаемой и приблизительно {context.word_count} слов длинной."
        else:
            return f"Make the story engaging, imaginative, and approximately {context.word_count} words long."
