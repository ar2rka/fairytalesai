"""English prompt builder with pre-configured defaults."""

from src.prompts.builders.prompt_builder import PromptBuilder
from src.domain.value_objects import Language


class EnglishPromptBuilder(PromptBuilder):
    """Prompt builder pre-configured for English stories."""
    
    def __init__(self):
        """Initialize English prompt builder."""
        super().__init__()
        self._language = Language.ENGLISH
