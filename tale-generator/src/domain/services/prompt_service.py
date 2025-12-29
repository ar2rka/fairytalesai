"""Prompt generation service."""

from typing import List, Optional
from src.domain.entities import Child, Hero
from src.domain.value_objects import Language, StoryLength
from src.core.logging import get_logger
from src.utils.age_category_utils import get_age_category_for_prompt
from src.infrastructure.persistence.models import StoryDB
from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.infrastructure.persistence.prompt_repository import PromptRepository
from src.domain.services.prompt_template_service import PromptTemplateService

logger = get_logger("domain.prompt_service")


class PromptService:
    """Service for generating language-specific story prompts."""
    
    def __init__(self, supabase_client=None):
        """Initialize prompt service.
        
        Args:
            supabase_client: Optional Supabase client for loading prompts from database.
                           If None, will use legacy prompt generation methods.
        """
        self._supabase_client = supabase_client
        self._template_service: Optional[PromptTemplateService] = None
        
        if supabase_client:
            try:
                repository = PromptRepository(supabase_client)
                self._template_service = PromptTemplateService(repository)
                logger.info("PromptTemplateService initialized with Supabase")
            except Exception as e:
                logger.warning(f"Failed to initialize PromptTemplateService: {e}. Using legacy methods.")
                self._template_service = None
        else:
            logger.info("No Supabase client provided. Using legacy prompt generation methods.")
    
    def generate_child_prompt(
        self,
        child: Child,
        moral: str,
        language: Language,
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate a story prompt based on child profile.
        
        Args:
            child: Child entity
            moral: Moral value for the story
            language: Language for the story
            story_length: Desired story length
            parent_story: Optional parent story for continuation narratives
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating prompt for child {child.name} in {language.value}")
        
        # Use template service if available
        if self._template_service:
            try:
                # Convert Child entity to ChildCharacter
                child_character = ChildCharacter(
                    name=child.name,
                    age_category=child.age_category,
                    gender=child.gender.value if hasattr(child.gender, 'value') else str(child.gender),
                    interests=child.interests,
                    description=None
                )
                
                return self._template_service.render_prompt(
                    character=child_character,
                    moral=moral,
                    language=language,
                    story_length=story_length.minutes,
                    story_type="child",
                    parent_story=parent_story
                )
            except Exception as e:
                logger.warning(f"Template service failed, falling back to legacy: {e}")
        
        # Fallback to legacy methods
        if language == Language.RUSSIAN:
            return self._generate_russian_child_prompt(child, moral, story_length, parent_story)
        else:
            return self._generate_english_child_prompt(child, moral, story_length, parent_story)
    
    def generate_hero_prompt(
        self,
        hero: Hero,
        moral: str,
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate a story prompt based on hero profile.
        
        Args:
            hero: Hero entity
            moral: Moral value for the story
            story_length: Desired story length
            parent_story: Optional parent story for continuation narratives
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating prompt for hero {hero.name} in {hero.language.value}")
        
        # Use template service if available
        if self._template_service:
            try:
                # Convert Hero entity to HeroCharacter
                hero_character = HeroCharacter(
                    name=hero.name,
                    age=hero.age,
                    gender=hero.gender.value if hasattr(hero.gender, 'value') else str(hero.gender),
                    appearance=hero.appearance,
                    personality_traits=hero.personality_traits,
                    strengths=hero.strengths,
                    interests=hero.interests,
                    language=hero.language,
                    description=None
                )
                
                return self._template_service.render_prompt(
                    character=hero_character,
                    moral=moral,
                    language=hero.language,
                    story_length=story_length.minutes,
                    story_type="hero",
                    parent_story=parent_story
                )
            except Exception as e:
                logger.warning(f"Template service failed, falling back to legacy: {e}")
        
        # Fallback to legacy methods
        if hero.language == Language.RUSSIAN:
            return self._generate_russian_hero_prompt(hero, moral, story_length, parent_story)
        else:
            return self._generate_english_hero_prompt(hero, moral, story_length, parent_story)
    
    def generate_combined_prompt(
        self,
        child: Child,
        hero: Hero,
        moral: str,
        language: Language,
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate a story prompt for combined child + hero story.
        
        Args:
            child: Child entity
            hero: Hero entity
            moral: Moral value for the story
            language: Language for the story
            story_length: Desired story length
            parent_story: Optional parent story for continuation narratives
            
        Returns:
            Generated prompt string
        """
        logger.debug(f"Generating combined prompt for {child.name} and {hero.name} in {language.value}")
        
        # Use template service if available
        if self._template_service:
            try:
                # Convert Child and Hero entities to Character objects
                child_character = ChildCharacter(
                    name=child.name,
                    age_category=child.age_category,
                    gender=child.gender.value if hasattr(child.gender, 'value') else str(child.gender),
                    interests=child.interests,
                    description=None
                )
                
                hero_character = HeroCharacter(
                    name=hero.name,
                    age=hero.age,
                    gender=hero.gender.value if hasattr(hero.gender, 'value') else str(hero.gender),
                    appearance=hero.appearance,
                    personality_traits=hero.personality_traits,
                    strengths=hero.strengths,
                    interests=hero.interests,
                    language=hero.language,
                    description=None
                )
                
                # Create relationship description
                if language == Language.RUSSIAN:
                    relationship = f"{child.name} встречает легендарного героя {hero.name}"
                else:
                    relationship = f"{child.name} meets the legendary {hero.name}"
                
                combined_character = CombinedCharacter(
                    child=child_character,
                    hero=hero_character,
                    relationship=relationship
                )
                
                return self._template_service.render_prompt(
                    character=combined_character,
                    moral=moral,
                    language=language,
                    story_length=story_length.minutes,
                    story_type="combined",
                    parent_story=parent_story
                )
            except Exception as e:
                logger.warning(f"Template service failed, falling back to legacy: {e}")
        
        # Fallback to legacy methods
        if language == Language.RUSSIAN:
            return self._generate_russian_combined_prompt(child, hero, moral, story_length, parent_story)
        else:
            return self._generate_english_combined_prompt(child, hero, moral, story_length, parent_story)
    
    def _generate_english_child_prompt(
        self,
        child: Child,
        moral: str,
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate English child-based prompt."""
        interests = ', '.join(child.interests)
        gender = child.gender.translate(Language.ENGLISH)
        age_category_display = get_age_category_for_prompt(child.age_category, Language.ENGLISH)
        
        parent_section = self._format_parent_story_section(parent_story, Language.ENGLISH)
        
        return f"""
        Create a bedtime story for a child with the following characteristics:
        - Name: {child.name}
        - Age: {age_category_display}
        - Gender: {gender}
        - Interests: {interests}
        
        {parent_section}
        
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
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate Russian child-based prompt."""
        interests = ', '.join(self._translate_interests(child.interests, Language.RUSSIAN))
        gender = child.gender.translate(Language.RUSSIAN)
        moral_ru = self._translate_moral(moral, Language.RUSSIAN)
        age_category_display = get_age_category_for_prompt(child.age_category, Language.RUSSIAN)
        
        parent_section = self._format_parent_story_section(parent_story, Language.RUSSIAN)
        
        return f"""
        Создай детскую сказку на ночь со следующими характеристиками:
        - Имя: {child.name}
        - Возраст: {age_category_display}
        - Пол: {gender}
        - Интересы: {interests}
        
        {parent_section}
        
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
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate English hero-based prompt."""
        personality_traits = ', '.join(hero.personality_traits)
        strengths = ', '.join(hero.strengths)
        interests = ', '.join(hero.interests)
        gender = hero.gender.translate(Language.ENGLISH)
        
        parent_section = self._format_parent_story_section(parent_story, Language.ENGLISH)
        
        return f"""
        Create a bedtime story featuring a heroic character with the following characteristics:
        - Name: {hero.name}
        - Age: {hero.age}
        - Gender: {gender}
        - Appearance: {hero.appearance}
        - Personality Traits: {personality_traits}
        - Strengths: {strengths}
        - Interests: {interests}
        
        {parent_section}
        
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
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate Russian hero-based prompt."""
        personality_traits = ', '.join(hero.personality_traits)
        strengths = ', '.join(hero.strengths)
        interests = ', '.join(hero.interests)
        gender = hero.gender.translate(Language.RUSSIAN)
        moral_ru = self._translate_moral(moral, Language.RUSSIAN)
        
        parent_section = self._format_parent_story_section(parent_story, Language.RUSSIAN)
        
        return f"""
        Создай детскую сказку на ночь о герое со следующими характеристиками:
        - Имя: {hero.name}
        - Возраст: {hero.age}
        - Пол: {gender}
        - Внешность: {hero.appearance}
        - Черты характера: {personality_traits}
        - Сильные стороны: {strengths}
        - Интересы: {interests}
        
        {parent_section}
        
        Сказка должна содержать нравственный урок о "{moral_ru}" и быть подходящей для детей.
        Сделай сказку увлекательной, воображаемой и приблизительно {story_length.word_count} слов длинной.
        Включи имя героя как главного персонажа сказки.
        Закончи сказку четким сообщением о нравственном уроке.
        Напиши сказку на русском языке.
        """
    
    def _get_parent_story_text(self, parent_story: Optional[StoryDB], language: Language) -> Optional[str]:
        """Get parent story text for inclusion in prompt.
        
        Uses summary if available, otherwise creates a brief summary from content.
        
        Args:
            parent_story: Parent story entity
            language: Target language
            
        Returns:
            Parent story text or None
        """
        if not parent_story:
            return None
        
        # Use summary if available and not empty
        if parent_story.summary and parent_story.summary.strip():
            return parent_story.summary.strip()
        
        # Otherwise, create a brief summary from content (first 300 words)
        content = parent_story.content or ""
        if not content.strip():
            return None
        
        words = content.split()
        if len(words) > 300:
            summary = " ".join(words[:300]) + "..."
        else:
            summary = content
        
        return summary.strip() if summary else None
    
    def _format_parent_story_section(self, parent_story: Optional[StoryDB], language: Language) -> str:
        """Format parent story section for prompt.
        
        Args:
            parent_story: Parent story entity
            language: Target language
            
        Returns:
            Formatted parent story section
        """
        if not parent_story:
            return ""
        
        parent_text = self._get_parent_story_text(parent_story, language)
        if not parent_text:
            return ""
        
        title = parent_story.title or "Untitled Story"
        
        if language == Language.RUSSIAN:
            return f"""
Предыдущая история:
Заголовок: {title}
Содержание: {parent_text}

Эта история является продолжением предыдущей. Создай естественное продолжение, которое развивает сюжет и персонажей из предыдущей истории. Начни новую историю там, где закончилась предыдущая, и продолжай приключения.
"""
        else:
            return f"""
Previous Story:
Title: {title}
Content: {parent_text}

This story is a continuation of the previous one. Create a natural continuation that develops the plot and characters from the previous story. Start the new story where the previous one ended and continue the adventures.
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
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
    ) -> str:
        """Generate English combined prompt."""
        child_interests = ', '.join(child.interests)
        child_gender = child.gender.translate(Language.ENGLISH)
        hero_personality_traits = ', '.join(hero.personality_traits)
        hero_strengths = ', '.join(hero.strengths)
        hero_gender = hero.gender.translate(Language.ENGLISH)
        
        relationship = f"{child.name} meets the legendary {hero.name}"
        
        age_category_display = get_age_category_for_prompt(child.age_category, Language.ENGLISH)
        
        parent_section = self._format_parent_story_section(parent_story, Language.ENGLISH)
        
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
        
        {parent_section}
        
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
        story_length: StoryLength,
        parent_story: Optional[StoryDB] = None
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
        
        parent_section = self._format_parent_story_section(parent_story, Language.RUSSIAN)
        
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
        
        {parent_section}
        
        Сказка должна содержать нравственный урок о "{moral_ru}" и быть подходящей для детей в возрасте {age_category_display}.
        Сделай сказку увлекательной, воображаемой и приблизительно {story_length.word_count} слов длинной.
        Включи имена обоих персонажей в сказке и покажи, как они работают вместе.
        Закончи сказку четким сообщением о нравственном уроке.
        Напиши сказку на русском языке.
        """
