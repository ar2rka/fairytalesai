"""Moral component for prompt building."""

from typing import Dict
from src.prompts.components.base_component import BaseComponent, PromptContext
from src.domain.value_objects import Language


class MoralComponent(BaseComponent):
    """Renders moral instructions for prompts."""
    
    # Moral translations
    MORAL_TRANSLATIONS: Dict[Language, Dict[str, str]] = {
        Language.ENGLISH: {
            "kindness": "kindness",
            "honesty": "honesty",
            "bravery": "bravery",
            "friendship": "friendship",
            "perseverance": "perseverance",
            "empathy": "empathy",
            "respect": "respect",
            "responsibility": "responsibility"
        },
        Language.RUSSIAN: {
            "kindness": "доброта",
            "honesty": "честность",
            "bravery": "храбрость",
            "friendship": "дружба",
            "perseverance": "настойчивость",
            "empathy": "сочувствие",
            "respect": "уважение",
            "responsibility": "ответственность"
        }
    }
    
    def render(self, context: PromptContext) -> str:
        """Render moral instruction.
        
        Args:
            context: Prompt context with moral value
            
        Returns:
            Formatted moral instruction
        """
        # Translate moral if needed
        moral = self._translate_moral(context.moral, context.language)
        
        if context.language == Language.RUSSIAN:
            return f'Сказка должна содержать нравственный урок о "{moral}" и быть подходящей для детей.'
        else:
            return f'The story should focus on the moral value of "{moral}" and be appropriate for children.'
    
    def _translate_moral(self, moral: str, language: Language) -> str:
        """Translate moral value to target language.
        
        Args:
            moral: Moral value in English
            language: Target language
            
        Returns:
            Translated moral value
        """
        moral_lower = moral.lower()
        translations = self.MORAL_TRANSLATIONS.get(language, {})
        return translations.get(moral_lower, moral)
