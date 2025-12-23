"""Ending component for prompt building."""

from src.prompts.components.base_component import BaseComponent, PromptContext
from src.domain.value_objects import Language


class EndingComponent(BaseComponent):
    """Renders ending instructions for prompts."""
    
    def render(self, context: PromptContext) -> str:
        """Render ending instruction.
        
        Args:
            context: Prompt context
            
        Returns:
            Formatted ending instruction
        """
        char_data = context.character.get_description_data()
        char_type = char_data.get("character_type")
        
        if context.language == Language.RUSSIAN:
            instruction = "Закончи сказку четким сообщением о нравственном уроке."
            if char_type == "child":
                name_instruction = "Включи имя ребенка как главного героя сказки."
            elif char_type == "hero":
                name_instruction = "Включи имя героя как главного персонажа сказки."
            elif char_type == "combined":
                name_instruction = "Включи имена обоих персонажей в сказке."
            else:
                name_instruction = ""
        else:
            instruction = "End the story with a clear message about the moral value."
            if char_type == "child":
                name_instruction = "Include the child's name as the main character in the story."
            elif char_type == "hero":
                name_instruction = "Include the hero's name as the main character in the story."
            elif char_type == "combined":
                name_instruction = "Include both characters' names in the story."
            else:
                name_instruction = ""
        
        if name_instruction:
            return f"{name_instruction}\n{instruction}"
        return instruction
