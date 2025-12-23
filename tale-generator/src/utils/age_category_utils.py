"""Utilities for age category handling and translation."""

from src.domain.value_objects import Language


def get_age_category_display(age_category: str, language: Language = Language.ENGLISH) -> str:
    """Get display text for age category in specified language.
    
    Args:
        age_category: Age category ('2-3', '3-5', or '5-7')
        language: Target language
        
    Returns:
        Display text for the age category
    """
    translations = {
        Language.ENGLISH: {
            '2-3': '2-3 years',
            '3-5': '3-5 years',
            '5-7': '5-7 years'
        },
        Language.RUSSIAN: {
            '2-3': '2-3 года',
            '3-5': '3-5 лет',
            '5-7': '5-7 лет'
        }
    }
    
    return translations.get(language, translations[Language.ENGLISH]).get(
        age_category, 
        age_category
    )


def get_age_category_for_prompt(age_category: str, language: Language = Language.ENGLISH) -> str:
    """Get age category text for use in prompts.
    
    Args:
        age_category: Age category ('2-3', '3-5', or '5-7')
        language: Target language
        
    Returns:
        Age category text formatted for prompts
    """
    if language == Language.RUSSIAN:
        return {
            '2-3': '2-3 года',
            '3-5': '3-5 лет',
            '5-7': '5-7 лет'
        }.get(age_category, age_category)
    else:
        return {
            '2-3': '2-3 years',
            '3-5': '3-5 years',
            '5-7': '5-7 years'
        }.get(age_category, age_category)
