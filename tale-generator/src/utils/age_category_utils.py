"""Utilities for age category handling and translation."""

import re
from typing import Optional
from src.domain.value_objects import Language


def normalize_age_category(age_category: str) -> str:
    """Normalize age category string to standard format (e.g., '2-3 года' -> '2-3').
    
    Extracts numeric range from string, supporting formats like:
    - '2-3 года'
    - '4-5'
    - '6-7 лет'
    - '2-3 years'
    
    Args:
        age_category: Age category string in various formats
        
    Returns:
        Normalized age category in format 'X-Y' (e.g., '2-3', '4-5', '6-7')
        
    Raises:
        ValueError: If age category cannot be normalized
    """
    if not age_category or not age_category.strip():
        raise ValueError("Age category cannot be empty")
    
    # Remove extra whitespace
    age_category = age_category.strip()
    
    # Try to extract pattern like "2-3", "4-5", etc.
    # Pattern matches: one or two digits, dash, one or two digits
    match = re.search(r'(\d{1,2})\s*-\s*(\d{1,2})', age_category)
    
    if match:
        start_age = int(match.group(1))
        end_age = int(match.group(2))
        
        # Validate range
        if start_age < 1 or end_age < 1:
            raise ValueError(f"Invalid age range: ages must be positive")
        if start_age >= end_age:
            raise ValueError(f"Invalid age range: start age ({start_age}) must be less than end age ({end_age})")
        if end_age > 18:
            raise ValueError(f"Invalid age range: end age ({end_age}) exceeds maximum (18)")
        
        return f"{start_age}-{end_age}"
    
    # If no match found, try to see if it's already in correct format
    if re.match(r'^\d{1,2}-\d{1,2}$', age_category):
        return age_category
    
    # Support "8+" / "9+" (Big Kid) — normalize to range 8-12 for pipeline compatibility
    if re.match(r'^(\d{1,2})\s*\+\s*$', age_category):
        return "8-12"
    
    raise ValueError(f"Cannot normalize age category: '{age_category}'. Expected format: 'X-Y', '8+', or 'X-Y года/лет/years'")


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
            '5-7': '5-7 years',
            '8-12': '9+ years'
        },
        Language.RUSSIAN: {
            '2-3': '2-3 года',
            '3-5': '3-5 лет',
            '5-7': '5-7 лет',
            '8-12': '9+ лет'
        }
    }
    
    return translations.get(language, translations[Language.ENGLISH]).get(
        age_category, 
        age_category
    )


def get_age_category_for_prompt(age_category: str, language: Language = Language.ENGLISH) -> str:
    """Get age category text for use in prompts.
    
    Args:
        age_category: Age category (normalized format like '2-3', '4-5', '8-12', or '8+')
        language: Target language
        
    Returns:
        Age category text formatted for prompts
    """
    # Normalize first to ensure consistent format (e.g. '8+' -> '8-12')
    normalized = normalize_age_category(age_category)
    
    # Use display map for 8-12 so we show "9+ years" in prompts
    if normalized == "8-12":
        return get_age_category_display(normalized, language)
    
    # Extract age range for X-Y format
    match = re.match(r'(\d+)-(\d+)', normalized)
    if not match:
        return age_category
    
    start_age = int(match.group(1))
    end_age = int(match.group(2))
    
    if language == Language.RUSSIAN:
        # Russian pluralization rules
        if end_age == 1:
            return f"{start_age}-{end_age} год"
        elif end_age in [2, 3, 4]:
            return f"{start_age}-{end_age} года"
        else:
            return f"{start_age}-{end_age} лет"
    else:
        # English
        if end_age == 1:
            return f"{start_age}-{end_age} year"
        else:
            return f"{start_age}-{end_age} years"


def calculate_age_from_category(age_category: str) -> int:
    """Calculate numeric age from age category for backward compatibility.
    
    Uses the lower bound of the range as the age value.
    
    Args:
        age_category: Age category string (will be normalized)
        
    Returns:
        Numeric age value (lower bound of range)
    """
    normalized = normalize_age_category(age_category)
    match = re.match(r'(\d+)-(\d+)', normalized)
    if match:
        return int(match.group(1))
    return 4  # Default fallback


def age_to_category(age: int) -> str:
    """Convert numeric age to age category.
    
    Args:
        age: Numeric age value
        
    Returns:
        Age category string ('2-3', '3-5', '5-7', or '8-12')
    """
    if age <= 3:
        return '2-3'
    elif age <= 5:
        return '3-5'
    elif age <= 7:
        return '5-7'
    else:
        return '8-12'
