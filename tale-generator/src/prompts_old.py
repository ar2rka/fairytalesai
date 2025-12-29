"""Language-specific prompts for story generation."""

from typing import Protocol, Dict, List
from src.models import Language
from dataclasses import dataclass
from abc import ABC, abstractmethod


@dataclass
class Hero:
    """Base class for story heroes."""
    name: str
    age: int
    gender: str
    appearance: str
    personality_traits: List[str]
    strengths: List[str]
    interests: List[str]
    language: Language = Language.ENGLISH


@dataclass
class Child:
    """Child profile for child-based stories."""
    name: str
    age: int
    gender: str
    interests: List[str]


class StoryPrompt(Protocol):
    """Protocol for story prompt generators."""
    
    def generate_heroic_prompt(self, hero: Hero, moral: str, story_length: int = 5) -> str:
        """Generate a heroic story prompt.
        
        Args:
            hero: Hero information
            moral: The moral value for the story
            story_length: The desired length of the story in minutes (default: 5)
            
        Returns:
            A prompt string
        """
        ...
    
    def generate_child_prompt(self, child: Child, moral: str, story_length: int = 5) -> str:
        """Generate a child-based story prompt.
        
        Args:
            child: Child information
            moral: The moral value for the story
            story_length: The desired length of the story in minutes (default: 5)
            
        Returns:
            A prompt string
        """
        ...


class LanguageStoryInfo(ABC):
    """Base class for language-specific story information."""
    
    @property
    @abstractmethod
    def gender_translations(self) -> Dict[str, str]:
        """Gender translations."""
        ...
    
    @property
    @abstractmethod
    def moral_translations(self) -> Dict[str, str]:
        """Moral value translations."""
        ...
    
    @property
    def interest_translations(self) -> Dict[str, str]:
        """Interest translations (can be overridden by subclasses)."""
        return {
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
    
    def get_common_story_elements(self, moral: str, word_count: int, character_instruction: str) -> str:
        """Get common story elements to reduce duplication in templates."""
        return f'''        {self.get_moral_instruction(moral)}
        {self.get_length_instruction(word_count)}
        {character_instruction}
        {self.get_ending_instruction()}
        {self.get_language_instruction()}'''
    
    @abstractmethod
    def get_moral_instruction(self, moral: str) -> str:
        """Get the moral instruction for the story."""
        ...
    
    @abstractmethod
    def get_length_instruction(self, word_count: int) -> str:
        """Get the length instruction for the story."""
        ...
    
    @abstractmethod
    def get_ending_instruction(self) -> str:
        """Get the ending instruction for the story."""
        ...
    
    @abstractmethod
    def get_language_instruction(self) -> str:
        """Get the language instruction for the story."""
        ...
    
    @abstractmethod
    def get_heroic_story_template(self, name: str, age: int, gender: str, appearance: str, 
                                 personality_traits: str, strengths: str, interests: str, 
                                 moral: str, word_count: int) -> str:
        """Generate a heroic story template with all parameters filled in."""
        ...
    
    @abstractmethod
    def get_child_story_template(self, name: str, age: int, gender: str, interests: str,
                                moral: str, word_count: int) -> str:
        """Generate a child story template with all parameters filled in."""
        ...


class EnglishStoryInfo(LanguageStoryInfo):
    """English story information."""
    
    def get_heroic_story_template(self, name: str, age: int, gender: str, appearance: str, 
                             personality_traits: str, strengths: str, interests: str, 
                             moral: str, word_count: int) -> str:
        """Generate a heroic story template with all parameters filled in."""
        character_instruction = 'Include the hero\'s name as the main character in the story.'
        common_elements = self.get_common_story_elements(moral, word_count, character_instruction)
        return f"""
        Create a bedtime story featuring a heroic character with the following characteristics:
        - Name: {name}
        - Age: {age}
        - Gender: {gender}
        - Appearance: {appearance}
        - Personality Traits: {personality_traits}
        - Strengths: {strengths}
        - Interests: {interests}
        
{common_elements}
        """
    
    def get_child_story_template(self, name: str, age: int, gender: str, interests: str,
                              moral: str, word_count: int) -> str:
        """Generate a child story template with all parameters filled in."""
        character_instruction = 'Include the child\'s name as the main character in the story.'
        common_elements = self.get_common_story_elements(moral, word_count, character_instruction)
        return f"""
        Create a bedtime story for a child with the following characteristics:
        - Name: {name}
        - Age: {age}
        - Gender: {gender}
        - Interests: {interests}
        
{common_elements}
        """
    
    @property
    def gender_translations(self) -> Dict[str, str]:
        return {
            "male": "male",
            "female": "female",
            "other": "other"
        }
    
    @property
    def moral_translations(self) -> Dict[str, str]:
        return {
            "kindness": "kindness",
            "honesty": "honesty",
            "bravery": "bravery",
            "friendship": "friendship",
            "perseverance": "perseverance",
            "empathy": "empathy",
            "respect": "respect",
            "responsibility": "responsibility"
        }
    
    def get_moral_instruction(self, moral: str) -> str:
        return f'The story should focus on the moral value of "{moral}" and be appropriate for children.'
    
    def get_length_instruction(self, word_count: int) -> str:
        return f"Make the story engaging, imaginative, and approximately {word_count} words long."
    
    def get_ending_instruction(self) -> str:
        return "End the story with a clear message about the moral value."
    
    def get_language_instruction(self) -> str:
        return "Write the story in English."


class RussianStoryInfo(LanguageStoryInfo):
    """Russian story information."""
    
    def get_heroic_story_template(self, name: str, age: int, gender: str, appearance: str, 
                             personality_traits: str, strengths: str, interests: str, 
                             moral: str, word_count: int) -> str:
        """Generate a heroic story template with all parameters filled in."""
        character_instruction = 'Включи имя героя как главного персонажа сказки.'
        common_elements = self.get_common_story_elements(moral, word_count, character_instruction)
        return f"""
        Создай детскую сказку на ночь о герое со следующими характеристиками:
        - Имя: {name}
        - Возраст: {age}
        - Пол: {gender}
        - Внешность: {appearance}
        - Черты характера: {personality_traits}
        - Сильные стороны: {strengths}
        - Интересы: {interests}
        
{common_elements}
        """
    
    def get_child_story_template(self, name: str, age: int, gender: str, interests: str,
                              moral: str, word_count: int) -> str:
        """Generate a child story template with all parameters filled in."""
        character_instruction = 'Включи имя ребенка как главного героя сказки.'
        common_elements = self.get_common_story_elements(moral, word_count, character_instruction)
        return f"""
        Создай детскую сказку на ночь со следующими характеристиками:
        - Имя: {name}
        - Возраст: {age}
        - Пол: {gender}
        - Интересы: {interests}
        
{common_elements}
        """
    
    @property
    def gender_translations(self) -> Dict[str, str]:
        return {
            "male": "мальчик",
            "female": "девочка",
            "other": "ребенок"
        }
    
    @property
    def moral_translations(self) -> Dict[str, str]:
        return {
            "kindness": "доброта",
            "honesty": "честность",
            "bravery": "храбрость",
            "friendship": "дружба",
            "perseverance": "настойчивость",
            "empathy": "сочувствие",
            "respect": "уважение",
            "responsibility": "ответственность"
        }
    
    @property
    def interest_translations(self) -> Dict[str, str]:
        return {
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
    
    def get_moral_instruction(self, moral: str) -> str:
        return f'Сказка должна содержать нравственный урок о "{moral}" и быть подходящей для детей.'
    
    def get_length_instruction(self, word_count: int) -> str:
        return f"Сделай сказку увлекательной, воображаемой и приблизительно {word_count} слов длинной."
    
    def get_ending_instruction(self) -> str:
        return "Закончи сказку четким сообщением о нравственном уроке."
    
    def get_language_instruction(self) -> str:
        return "Напиши сказку на русском языке."


class PromptGenerator:
    """Base prompt generator with language-specific information."""
    
    _language_info: Dict[Language, LanguageStoryInfo] = {
        Language.ENGLISH: EnglishStoryInfo(),
        Language.RUSSIAN: RussianStoryInfo()
    }
    
    @classmethod
    def get_language_info(cls, language: Language) -> LanguageStoryInfo:
        """Get language-specific information.
        
        Args:
            language: The language for the story
            
        Returns:
            Language-specific information
        """
        return cls._language_info.get(language, cls._language_info[Language.ENGLISH])


class EnglishPromptGenerator:
    """English story prompt generator."""
    
    def generate_heroic_prompt(self, hero: Hero, moral: str, story_length: int = 5) -> str:
        """Generate an English heroic story prompt."""
        # Estimate word count based on reading speed (approx. 150 words per minute for children)
        word_count = story_length * 150
        
        info = PromptGenerator.get_language_info(Language.ENGLISH)
        
        prompt = info.get_heroic_story_template(
            name=hero.name,
            age=hero.age,
            gender=hero.gender,
            appearance=hero.appearance,
            personality_traits=', '.join(hero.personality_traits),
            strengths=', '.join(hero.strengths),
            interests=', '.join(hero.interests),
            moral=moral,
            word_count=word_count
        )
        
        return prompt.strip()
    
    def generate_child_prompt(self, child: Child, moral: str, story_length: int = 5) -> str:
        """Generate an English child-based story prompt."""
        # Estimate word count based on reading speed (approx. 150 words per minute for children)
        word_count = story_length * 150
        
        info = PromptGenerator.get_language_info(Language.ENGLISH)
        
        prompt = info.get_child_story_template(
            name=child.name,
            age_category=child.age_category,
            gender=child.gender,
            interests=', '.join(child.interests),
            moral=moral,
            word_count=word_count
        )
        
        return prompt.strip()


class RussianPromptGenerator:
    """Russian story prompt generator."""
    
    def generate_heroic_prompt(self, hero: Hero, moral: str, story_length: int = 5) -> str:
        """Generate a Russian heroic story prompt."""
        # Estimate word count based on reading speed (approx. 150 words per minute for children)
        word_count = story_length * 150
        
        info = PromptGenerator.get_language_info(Language.RUSSIAN)
        
        # Translate moral values to Russian
        moral_ru = info.moral_translations.get(moral.lower(), moral)
        
        prompt = info.get_heroic_story_template(
            name=hero.name,
            age=hero.age,
            gender=info.gender_translations.get(hero.gender, "герой"),
            appearance=hero.appearance,
            personality_traits=', '.join(hero.personality_traits),
            strengths=', '.join(hero.strengths),
            interests=', '.join(hero.interests),
            moral=moral_ru,
            word_count=word_count
        )
        
        return prompt.strip()
    
    def generate_child_prompt(self, child: Child, moral: str, story_length: int = 5) -> str:
        """Generate a Russian child-based story prompt."""
        # Estimate word count based on reading speed (approx. 150 words per minute for children)
        word_count = story_length * 150
        
        info = PromptGenerator.get_language_info(Language.RUSSIAN)
        
        # Translate child profile fields to Russian
        gender_ru = info.gender_translations.get(child.gender, "ребенок")
        
        # Translate moral values to Russian
        moral_ru = info.moral_translations.get(moral.lower(), moral)
        
        # Translate interests to Russian if possible
        interests_ru: List[str] = []
        for interest in child.interests:
            interests_ru.append(info.interest_translations.get(interest.lower(), interest))
        
        prompt = info.get_child_story_template(
            name=child.name,
            age_category=child.age_category,
            gender=gender_ru,
            interests=', '.join(interests_ru),
            moral=moral_ru,
            word_count=word_count
        )
        
        return prompt.strip()


class PromptFactory:
    """Factory for creating prompt generators based on language."""
    
    _generators: Dict[Language, StoryPrompt] = {
        Language.ENGLISH: EnglishPromptGenerator(),
        Language.RUSSIAN: RussianPromptGenerator()
    }
    
    @classmethod
    def get_generator(cls, language: Language) -> StoryPrompt:
        """Get the appropriate prompt generator for the given language.
        
        Args:
            language: The language for the story
            
        Returns:
            A prompt generator instance
        """
        return cls._generators.get(language, cls._generators[Language.ENGLISH])


def get_heroic_story_prompt(hero: Hero, moral: str, language: Language, story_length: int = 5) -> str:
    """Get a language-specific heroic story prompt.
    
    Args:
        hero: Hero information
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    generator = PromptFactory.get_generator(language)
    return generator.generate_heroic_prompt(hero, moral, story_length)


def get_child_story_prompt(child: Child, moral: str, language: Language, story_length: int = 5) -> str:
    """Get a language-specific child-based story prompt.
    
    Args:
        child: Child information
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    generator = PromptFactory.get_generator(language)
    return generator.generate_child_prompt(child, moral, story_length)


# Backward compatibility function
def get_story_prompt(child, moral, language: Language, story_length: int = 5) -> str:
    """Get a language-specific prompt for story generation based on the language.
    
    Args:
        child: Child profile information
        moral: The moral value for the story
        language: The language for the story
        story_length: The desired length of the story in minutes (default: 5)
        
    Returns:
        A prompt string in the specified language
    """
    # Convert to proper Child dataclass if needed
    if not isinstance(child, Child):
        child_obj = Child(
            name=child.name,
            age_category=child.age_category,
            gender=child.gender,
            interests=child.interests
        )
    else:
        child_obj = child
    
    generator = PromptFactory.get_generator(language)
    return generator.generate_child_prompt(child_obj, moral, story_length)


# Predefined heroes
class Heroes:
    """Collection of predefined heroes for story generation."""
    
    # English heroes
    ENGLISH_HEROES = [
        Hero(
            name="Captain Wonder",
            age=12,
            gender="male",
            appearance="Wears a blue cape with a golden star, has bright eyes and a confident smile",
            personality_traits=["brave", "kind", "curious", "determined"],
            strengths=["flying", "super strength", "problem-solving"],
            interests=["exploring space", "helping others", "solving mysteries"],
            language=Language.ENGLISH
        ),
        Hero(
            name="Starlight",
            age=14,
            gender="female",
            appearance="Glows with a gentle light, has silver hair and wears a star-themed outfit",
            personality_traits=["wise", "compassionate", "creative", "adventurous"],
            strengths=["light manipulation", "teleportation", "healing"],
            interests=["stargazing", "music", "ancient history"],
            language=Language.ENGLISH
        )
    ]
    
    # Russian heroes
    RUSSIAN_HEROES = [
        Hero(
            name="Капитан Чудо",
            age=10,
            gender="female",
            appearance="Носит красный плащ с серебряной звездой, у неё карие глаза и добрый взгляд",
            personality_traits=["храбрая", "добрая", "любознательная", "настойчивая"],
            strengths=["летает", "суперсила", "решение проблем"],
            interests=["путешествия по космосу", "помощь другим", "разгадывание загадок"],
            language=Language.RUSSIAN
        ),
        Hero(
            name="Ледяная Волшебница",
            age=16,
            gender="female",
            appearance="Носит голубое платье, украшенное снежинками, с белыми волосами и голубыми глазами",
            personality_traits=["спокойная", "умная", "элегантная", "могущественная"],
            strengths=["управление льдом", "телекинез", "невидимость"],
            interests=["зимние пейзажи", "магия", "древние руны"],
            language=Language.RUSSIAN
        )
    ]
    
    @classmethod
    def get_random_english_hero(cls) -> Hero:
        """Get a random English-speaking hero."""
        import random
        return random.choice(cls.ENGLISH_HEROES)
    
    @classmethod
    def get_random_russian_hero(cls) -> Hero:
        """Get a random Russian-speaking hero."""
        import random
        return random.choice(cls.RUSSIAN_HEROES)
    
    @classmethod
    def get_english_hero_by_index(cls, index: int) -> Hero:
        """Get an English-speaking hero by index."""
        return cls.ENGLISH_HEROES[index % len(cls.ENGLISH_HEROES)]
    
    @classmethod
    def get_russian_hero_by_index(cls, index: int) -> Hero:
        """Get a Russian-speaking hero by index."""
        return cls.RUSSIAN_HEROES[index % len(cls.RUSSIAN_HEROES)]
    
    @classmethod
    def get_all_english_heroes(cls) -> list[Hero]:
        """Get all English-speaking heroes."""
        return cls.ENGLISH_HEROES.copy()
    
    @classmethod
    def get_all_russian_heroes(cls) -> list[Hero]:
        """Get all Russian-speaking heroes."""
        return cls.RUSSIAN_HEROES.copy()


# Predefined children for examples
class Children:
    """Collection of predefined children for story generation."""
    
    @staticmethod
    def get_english_child() -> Child:
        """Get a predefined English-speaking child."""
        return Child(
            name="Emma",
            age=7,
            gender="female",
            interests=["unicorns", "fairies", "princesses"]
        )
    
    @staticmethod
    def get_russian_child() -> Child:
        """Get a predefined Russian-speaking child."""
        return Child(
            name="Аня",
            age=6,
            gender="female",
            interests=["котята", "цветы", "танцы"]
        )