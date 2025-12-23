"""Russian prompt builder with pre-configured defaults."""

from src.prompts.builders.prompt_builder import PromptBuilder
from src.domain.value_objects import Language


class RussianPromptBuilder(PromptBuilder):
    """Prompt builder pre-configured for Russian stories."""
    
    def __init__(self):
        """Initialize Russian prompt builder."""
        super().__init__()
        self._language = Language.RUSSIAN
