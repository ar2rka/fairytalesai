"""Jinja2 template filters and helpers for prompt rendering."""

from typing import List
from src.domain.value_objects import Language
from src.utils.age_category_utils import get_age_category_for_prompt


# Moral translations
MORAL_TRANSLATIONS = {
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

# Gender translations
GENDER_TRANSLATIONS = {
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

# Theme translations (API sends English key; we translate to target language for prompt)
THEME_TRANSLATIONS = {
    Language.ENGLISH: {
        "adventure": "adventure",
        "space": "space",
        "fantasy": "fantasy",
        "pirates": "pirates",
        "dinosaurs": "dinosaurs",
        "mermaids": "mermaids",
        "mystery": "mystery",
        "magic school": "magic school",
        "magic": "magic",
        "ocean": "ocean",
        "forest": "forest",
        "robots": "robots",
        "fairies": "fairies",
        "knights": "knights",
        "animals": "animals",
    },
    Language.RUSSIAN: {
        "adventure": "приключения",
        "space": "космос",
        "fantasy": "фэнтези",
        "pirates": "пираты",
        "dinosaurs": "динозавры",
        "mermaids": "русалки",
        "mystery": "тайна",
        "magic school": "школа магии",
        "magic": "магия",
        "ocean": "океан",
        "forest": "лес",
        "robots": "роботы",
        "fairies": "феи",
        "knights": "рыцари",
        "animals": "животные",
    }
}

# Interest translations
INTEREST_TRANSLATIONS = {
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


def translate_moral(moral: str, language: Language) -> str:
    """Translate moral value to target language.
    
    Args:
        moral: Moral value in English
        language: Target language
        
    Returns:
        Translated moral value
    """
    moral_lower = moral.lower()
    translations = MORAL_TRANSLATIONS.get(language, {})
    return translations.get(moral_lower, moral)


def translate_theme(theme: str, language: Language) -> str:
    """Translate story theme to target language.
    
    API sends theme in English; this returns the theme in the language of the prompt.
    
    Args:
        theme: Theme key in English (e.g. 'adventure', 'space')
        language: Target language
        
    Returns:
        Theme in target language
    """
    if not theme or not theme.strip():
        # Default: adventure (en) / приключения (ru)
        return THEME_TRANSLATIONS.get(language, {}).get("adventure", "adventure")
    theme_lower = theme.lower().strip()
    translations = THEME_TRANSLATIONS.get(language, {})
    return translations.get(theme_lower, theme)


def translate_gender(gender: str, language: Language) -> str:
    """Translate gender to target language.
    
    Args:
        gender: Gender value ('male', 'female', 'other')
        language: Target language
        
    Returns:
        Translated gender value
    """
    translations = GENDER_TRANSLATIONS.get(language, {})
    return translations.get(gender.lower(), gender)


def translate_interests(interests: List[str], language: Language) -> List[str]:
    """Translate list of interests to target language.
    
    Args:
        interests: List of interest strings
        language: Target language
        
    Returns:
        List of translated interests
    """
    if language == Language.ENGLISH:
        return interests
    
    interest_map = INTEREST_TRANSLATIONS.get(language, {})
    return [interest_map.get(interest.lower(), interest) for interest in interests]


def format_age_category(age_category: str, language: Language) -> str:
    """Format age category for prompts.
    
    Args:
        age_category: Age category string (e.g., '2-3', '4-5')
        language: Target language
        
    Returns:
        Formatted age category text
    """
    return get_age_category_for_prompt(age_category, language)


def join_list(items: List[str], separator: str = ", ") -> str:
    """Join list of strings with separator.
    
    Args:
        items: List of strings to join
        separator: Separator string (default: ", ")
        
    Returns:
        Joined string
    """
    return separator.join(items)


def truncate_text(text: str, length: int = 500) -> str:
    """Truncate text to specified length.
    
    Args:
        text: Text to truncate
        length: Maximum length
        
    Returns:
        Truncated text with "..." if truncated
    """
    if not text:
        return ""
    if len(text) <= length:
        return text
    return text[:length] + "..."


def register_jinja_filters(environment):
    """Register all custom filters with Jinja environment.
    
    Args:
        environment: Jinja2 Environment instance
    """
    environment.filters['translate_moral'] = translate_moral
    environment.filters['translate_theme'] = translate_theme
    environment.filters['translate_gender'] = translate_gender
    environment.filters['translate_interests'] = translate_interests
    environment.filters['format_age_category'] = format_age_category
    environment.filters['join'] = join_list
    environment.filters['truncate'] = truncate_text
