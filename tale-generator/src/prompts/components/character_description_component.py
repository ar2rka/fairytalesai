"""Character description component for prompt building."""

from typing import Dict
from src.prompts.components.base_component import BaseComponent, PromptContext
from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.domain.value_objects import Language, Gender
from src.utils.age_category_utils import get_age_category_for_prompt


class CharacterDescriptionComponent(BaseComponent):
    """Renders character descriptions for prompts."""
    
    # Translation mappings
    GENDER_TRANSLATIONS: Dict[Language, Dict[str, str]] = {
        Language.ENGLISH: {
            "male": "male",
            "female": "female",
            "other": "other"
        },
        Language.RUSSIAN: {
            "male": "мальчик",
            "female": "девочка",
            "other": "ребенок"
        }
    }
    
    def render(self, context: PromptContext) -> str:
        """Render character description based on character type.
        
        Args:
            context: Prompt context with character data
            
        Returns:
            Formatted character description
        """
        character_data = context.character.get_description_data()
        char_type = character_data.get("character_type")
        
        if char_type == "child":
            return self._render_child(context)
        elif char_type == "hero":
            return self._render_hero(context)
        elif char_type == "combined":
            return self._render_combined(context)
        else:
            raise ValueError(f"Unknown character type: {char_type}")
    
    def _render_child(self, context: PromptContext) -> str:
        """Render child character description."""
        char_data = context.character.get_description_data()
        
        if context.language == Language.RUSSIAN:
            return self._render_child_russian(char_data)
        else:
            return self._render_child_english(char_data)
    
    def _render_child_english(self, char_data: Dict) -> str:
        """Render child description in English."""
        age_category = char_data.get('age_category', '3-5')
        age_display = get_age_category_for_prompt(age_category, Language.ENGLISH)
        
        parts = [
            "Create a bedtime story for a child with the following characteristics:",
            f"- Name: {char_data['name']}",
            f"- Age: {age_display}",
            f"- Gender: {char_data['gender']}",
            f"- Interests: {', '.join(char_data['interests'])}"
        ]
        
        if char_data.get('description'):
            parts.append(f"- Additional Context: {char_data['description']}")
        
        return "\n".join(parts)
    
    def _render_child_russian(self, char_data: Dict) -> str:
        """Render child description in Russian."""
        gender_ru = self.GENDER_TRANSLATIONS[Language.RUSSIAN].get(
            char_data['gender'], "ребенок"
        )
        age_category = char_data.get('age_category', '3-5')
        age_display = get_age_category_for_prompt(age_category, Language.RUSSIAN)
        
        parts = [
            "Создай детскую сказку на ночь со следующими характеристиками:",
            f"- Имя: {char_data['name']}",
            f"- Возраст: {age_display}",
            f"- Пол: {gender_ru}",
            f"- Интересы: {', '.join(char_data['interests'])}"
        ]
        
        if char_data.get('description'):
            parts.append(f"- Дополнительно: {char_data['description']}")
        
        return "\n".join(parts)
    
    def _render_hero(self, context: PromptContext) -> str:
        """Render hero character description."""
        char_data = context.character.get_description_data()
        
        if context.language == Language.RUSSIAN:
            return self._render_hero_russian(char_data)
        else:
            return self._render_hero_english(char_data)
    
    def _render_hero_english(self, char_data: Dict) -> str:
        """Render hero description in English."""
        parts = [
            "Create a bedtime story featuring a heroic character with the following characteristics:",
            f"- Name: {char_data['name']}",
            f"- Age: {char_data['age']}",
            f"- Gender: {char_data['gender']}",
            f"- Appearance: {char_data['appearance']}",
            f"- Personality Traits: {', '.join(char_data['personality_traits'])}",
            f"- Strengths: {', '.join(char_data['strengths'])}",
            f"- Interests: {', '.join(char_data['interests'])}"
        ]
        
        if char_data.get('description'):
            parts.append(f"- Additional Context: {char_data['description']}")
        
        return "\n".join(parts)
    
    def _render_hero_russian(self, char_data: Dict) -> str:
        """Render hero description in Russian."""
        gender_ru = self.GENDER_TRANSLATIONS[Language.RUSSIAN].get(
            char_data['gender'], "герой"
        )
        
        parts = [
            "Создай детскую сказку на ночь о герое со следующими характеристиками:",
            f"- Имя: {char_data['name']}",
            f"- Возраст: {char_data['age']}",
            f"- Пол: {gender_ru}",
            f"- Внешность: {char_data['appearance']}",
            f"- Черты характера: {', '.join(char_data['personality_traits'])}",
            f"- Сильные стороны: {', '.join(char_data['strengths'])}",
            f"- Интересы: {', '.join(char_data['interests'])}"
        ]
        
        if char_data.get('description'):
            parts.append(f"- Дополнительно: {char_data['description']}")
        
        return "\n".join(parts)
    
    def _render_combined(self, context: PromptContext) -> str:
        """Render combined character description."""
        char_data = context.character.get_description_data()
        
        if context.language == Language.RUSSIAN:
            return self._render_combined_russian(char_data)
        else:
            return self._render_combined_english(char_data)
    
    def _render_combined_english(self, char_data: Dict) -> str:
        """Render combined description in English."""
        child_data = char_data['child']
        hero_data = char_data['hero']
        
        child_age_category = child_data.get('age_category', '3-5')
        child_age_display = get_age_category_for_prompt(child_age_category, Language.ENGLISH)
        
        parts = [
            "Create a bedtime story featuring both a child and a hero character:",
            "",
            "Child Character:",
            f"- Name: {child_data['name']}",
            f"- Age: {child_age_display}",
            f"- Gender: {child_data['gender']}",
            f"- Interests: {', '.join(child_data['interests'])}"
        ]
        
        if child_data.get('description'):
            parts.append(f"- Additional Context: {child_data['description']}")
        
        parts.extend([
            "",
            "Hero Character:",
            f"- Name: {hero_data['name']}",
            f"- Age: {hero_data['age']}",
            f"- Gender: {hero_data['gender']}",
            f"- Appearance: {hero_data['appearance']}",
            f"- Personality Traits: {', '.join(hero_data['personality_traits'])}",
            f"- Strengths: {', '.join(hero_data['strengths'])}",
            f"- Interests: {', '.join(hero_data['interests'])}"
        ])
        
        if hero_data.get('description'):
            parts.append(f"- Additional Context: {hero_data['description']}")
        
        if char_data.get('relationship'):
            parts.extend(["", f"Relationship: {char_data['relationship']}"])
        
        return "\n".join(parts)
    
    def _render_combined_russian(self, char_data: Dict) -> str:
        """Render combined description in Russian."""
        child_data = char_data['child']
        hero_data = char_data['hero']
        
        child_gender_ru = self.GENDER_TRANSLATIONS[Language.RUSSIAN].get(
            child_data['gender'], "ребенок"
        )
        hero_gender_ru = self.GENDER_TRANSLATIONS[Language.RUSSIAN].get(
            hero_data['gender'], "герой"
        )
        
        child_age_category = child_data.get('age_category', '3-5')
        child_age_display = get_age_category_for_prompt(child_age_category, Language.RUSSIAN)
        
        parts = [
            "Создай детскую сказку на ночь с двумя персонажами - ребенком и героем:",
            "",
            "Ребенок:",
            f"- Имя: {child_data['name']}",
            f"- Возраст: {child_age_display}",
            f"- Пол: {child_gender_ru}",
            f"- Интересы: {', '.join(child_data['interests'])}"
        ]
        
        if child_data.get('description'):
            parts.append(f"- Дополнительно: {child_data['description']}")
        
        parts.extend([
            "",
            "Герой:",
            f"- Имя: {hero_data['name']}",
            f"- Возраст: {hero_data['age']}",
            f"- Пол: {hero_gender_ru}",
            f"- Внешность: {hero_data['appearance']}",
            f"- Черты характера: {', '.join(hero_data['personality_traits'])}",
            f"- Сильные стороны: {', '.join(hero_data['strengths'])}",
            f"- Интересы: {', '.join(hero_data['interests'])}"
        ])
        
        if hero_data.get('description'):
            parts.append(f"- Дополнительно: {hero_data['description']}")
        
        if char_data.get('relationship'):
            parts.extend(["", f"Отношения: {char_data['relationship']}"])
        
        return "\n".join(parts)
