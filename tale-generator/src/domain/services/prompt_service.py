"""Prompt generation service."""

from typing import List
from src.domain.entities import Child, Hero
from src.domain.value_objects import Language, StoryLength
from src.core.logging import get_logger
from src.utils.age_category_utils import get_age_category_for_prompt

logger = get_logger("domain.prompt_service")


class PromptService:
    """Service for generating language-specific story prompts."""
    
    def generate_child_prompt(
        self,
        child: Child,
        moral: str,
        language: Language,
        story_length: StoryLength
    ) -> str:
        """Generate a story prompt based on child profile.
        
        Args:
            child: Child entity
            moral: Moral value for the story
            language: Language for the story
            story_length: Desired story length
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating prompt for child {child.name} in {language.value}")
        
        if language == Language.RUSSIAN:
            return self._generate_russian_child_prompt(child, moral, story_length)
        else:
            return self._generate_english_child_prompt(child, moral, story_length)
    
    def generate_hero_prompt(
        self,
        hero: Hero,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate a story prompt based on hero profile.
        
        Args:
            hero: Hero entity
            moral: Moral value for the story
            story_length: Desired story length
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating prompt for hero {hero.name} in {hero.language.value}")
        
        if hero.language == Language.RUSSIAN:
            return self._generate_russian_hero_prompt(hero, moral, story_length)
        else:
            return self._generate_english_hero_prompt(hero, moral, story_length)
    
    def generate_combined_prompt(
        self,
        child: Child,
        hero: Hero,
        moral: str,
        language: Language,
        story_length: StoryLength
    ) -> str:
        """Generate a story prompt for combined child + hero story.
        
        Args:
            child: Child entity
            hero: Hero entity
            moral: Moral value for the story
            language: Language for the story
            story_length: Desired story length
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating combined prompt for {child.name} and {hero.name} in {language.value}")
        
        if language == Language.RUSSIAN:
            return self._generate_russian_combined_prompt(child, hero, moral, story_length)
        else:
            return self._generate_english_combined_prompt(child, hero, moral, story_length)
    
    def _generate_english_child_prompt(
        self,
        child: Child,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate English child-based prompt."""
        interests = ', '.join(child.interests)
        gender = child.gender.translate(Language.ENGLISH)
        age_category_display = get_age_category_for_prompt(child.age_category, Language.ENGLISH)
        
        return f"""
        Create a bedtime story for a child with the following characteristics:
        - Name: {child.name}
        - Age: {age_category_display}
        - Gender: {gender}
        - Interests: {interests}
        
        The story should focus on the moral value of "{moral}" and be appropriate for children aged {age_category_display}.
        Make the story engaging, imaginative, and approximately {story_length.word_count} words long.
        Include the child's name as the main character in the story.
        End the story with a clear message about the moral value.
        Write the story in English.
        """
    
    def _generate_russian_child_prompt(
        self,
        child: Child,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate Russian child-based prompt."""
        interests = ', '.join(self._translate_interests(child.interests, Language.RUSSIAN))
        gender = child.gender.translate(Language.RUSSIAN)
        moral_ru = self._translate_moral(moral, Language.RUSSIAN)
        age_category_display = get_age_category_for_prompt(child.age_category, Language.RUSSIAN)
        
        return f"""
        Создай детскую сказку на ночь со следующими характеристиками:
        - Имя: {child.name}
        - Возраст: {age_category_display}
        - Пол: {gender}
        - Интересы: {interests}
        
        Сказка должна содержать нравственный урок о "{moral_ru}" и быть подходящей для детей в возрасте {age_category_display}.
        Сделай сказку увлекательной, воображаемой и приблизительно {story_length.word_count} слов длинной.
        Включи имя ребенка как главного героя сказки.
        Закончи сказку четким сообщением о нравственном уроке.
        Напиши сказку на русском языке.
        """
    
    def _generate_english_hero_prompt(
        self,
        hero: Hero,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate English hero-based prompt."""
        personality_traits = ', '.join(hero.personality_traits)
        strengths = ', '.join(hero.strengths)
        interests = ', '.join(hero.interests)
        gender = hero.gender.translate(Language.ENGLISH)
        
        return f"""
        Create a bedtime story featuring a heroic character with the following characteristics:
        - Name: {hero.name}
        - Age: {hero.age}
        - Gender: {gender}
        - Appearance: {hero.appearance}
        - Personality Traits: {personality_traits}
        - Strengths: {strengths}
        - Interests: {interests}
        
        The story should focus on the moral value of "{moral}" and be appropriate for children.
        Make the story engaging, imaginative, and approximately {story_length.word_count} words long.
        Include the hero's name as the main character in the story.
        End the story with a clear message about the moral value.
        Write the story in English.
        """
    
    def _generate_russian_hero_prompt(
        self,
        hero: Hero,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate Russian hero-based prompt."""
        personality_traits = ', '.join(hero.personality_traits)
        strengths = ', '.join(hero.strengths)
        interests = ', '.join(hero.interests)
        gender = hero.gender.translate(Language.RUSSIAN)
        moral_ru = self._translate_moral(moral, Language.RUSSIAN)
        
        return f"""
        Создай детскую сказку на ночь о герое со следующими характеристиками:
        - Имя: {hero.name}
        - Возраст: {hero.age}
        - Пол: {gender}
        - Внешность: {hero.appearance}
        - Черты характера: {personality_traits}
        - Сильные стороны: {strengths}
        - Интересы: {interests}
        
        Сказка должна содержать нравственный урок о "{moral_ru}" и быть подходящей для детей.
        Сделай сказку увлекательной, воображаемой и приблизительно {story_length.word_count} слов длинной.
        Включи имя героя как главного персонажа сказки.
        Закончи сказку четким сообщением о нравственном уроке.
        Напиши сказку на русском языке.
        """
    
    def _translate_moral(self, moral: str, language: Language) -> str:
        """Translate moral value to target language."""
        translations = {
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
        return translations.get(language, {}).get(moral.lower(), moral)
    
    def _translate_interests(self, interests: List[str], language: Language) -> List[str]:
        """Translate interests to target language."""
        translations = {
            Language.RUSSIAN: {
                "dinosaurs": "динозавры",
                "space": "космос",
                "robots": "роботы",
                "unicorns": "единороги",
                "fairies": "феи",
                "princesses": "принцессы",
                "cats": "кошки",
                "flowers": "цветы",
                "dancing": "танцы",
                "aliens": "пришельцы",
                "planets": "планеты",
                "trucks": "грузовики"
            }
        }
        
        interest_map = translations.get(language, {})
        return [interest_map.get(interest.lower(), interest) for interest in interests]
    
    def _generate_english_combined_prompt(
        self,
        child: Child,
        hero: Hero,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate English combined prompt."""
        child_interests = ', '.join(child.interests)
        child_gender = child.gender.translate(Language.ENGLISH)
        hero_personality_traits = ', '.join(hero.personality_traits)
        hero_strengths = ', '.join(hero.strengths)
        hero_gender = hero.gender.translate(Language.ENGLISH)
        
        relationship = f"{child.name} meets the legendary {hero.name}"
        
        age_category_display = get_age_category_for_prompt(child.age_category, Language.ENGLISH)
        
        return f"""
        Create a bedtime story featuring both a child and a hero together:
        
        Child Character:
        - Name: {child.name}
        - Age: {age_category_display}
        - Gender: {child_gender}
        - Interests: {child_interests}
        
        Hero Character:
        - Name: {hero.name}
        - Age: {hero.age}
        - Gender: {hero_gender}
        - Appearance: {hero.appearance}
        - Personality Traits: {hero_personality_traits}
        - Strengths: {hero_strengths}
        
        Relationship: {relationship}
        
        The story should focus on the moral value of "{moral}" and be appropriate for children aged {age_category_display}.
        Make the story engaging, imaginative, and approximately {story_length.word_count} words long.
        Include both characters' names throughout the story and show how they work together.
        End the story with a clear message about the moral value.
        Write the story in English.
        """
    
    def _generate_russian_combined_prompt(
        self,
        child: Child,
        hero: Hero,
        moral: str,
        story_length: StoryLength
    ) -> str:
        """Generate Russian combined prompt."""
        child_interests = ', '.join(self._translate_interests(child.interests, Language.RUSSIAN))
        child_gender = child.gender.translate(Language.RUSSIAN)
        hero_personality_traits = ', '.join(hero.personality_traits)
        hero_strengths = ', '.join(hero.strengths)
        hero_gender = hero.gender.translate(Language.RUSSIAN)
        moral_ru = self._translate_moral(moral, Language.RUSSIAN)
        
        relationship = f"{child.name} встречает легендарного героя {hero.name}"
        age_category_display = get_age_category_for_prompt(child.age_category, Language.RUSSIAN)
        
        return f"""
        Создай детскую сказку на ночь с двумя главными героями:
        
        Ребенок:
        - Имя: {child.name}
        - Возраст: {age_category_display}
        - Пол: {child_gender}
        - Интересы: {child_interests}
        
        Герой:
        - Имя: {hero.name}
        - Возраст: {hero.age}
        - Пол: {hero_gender}
        - Внешность: {hero.appearance}
        - Черты характера: {hero_personality_traits}
        - Сильные стороны: {hero_strengths}
        
        Отношения: {relationship}
        
        Сказка должна содержать нравственный урок о "{moral_ru}" и быть подходящей для детей в возрасте {age_category_display}.
        Сделай сказку увлекательной, воображаемой и приблизительно {story_length.word_count} слов длинной.
        Включи имена обоих персонажей в сказке и покажи, как они работают вместе.
        Закончи сказку четким сообщением о нравственном уроке.
        Напиши сказку на русском языке.
        """
