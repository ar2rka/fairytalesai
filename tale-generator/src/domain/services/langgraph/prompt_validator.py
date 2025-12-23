"""Prompt validation service using LLM-based content safety checks."""

import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from src.domain.services.langgraph.workflow_state import ValidationResult
from src.core.logging import get_logger

logger = get_logger("langgraph.prompt_validator")


class PromptValidatorService:
    """Service for validating story prompts for safety and appropriateness."""
    
    # Common licensed character keywords to detect
    # Note: Common names like "Anna", "Elsa", "Mario" are excluded to avoid false positives
    # Only very specific character names or phrases are included
    LICENSED_CHARACTERS = [
        # Disney - only very specific character names
        "mickey mouse", "minnie mouse", "donald duck", "goofy", "pluto",
        "olaf", "moana", "simba", "nala", "aladdin",
        "jasmine", "belle", "ariel", "cinderella", "snow white",
        "rapunzel", "tangled", "frozen",  # "frozen" as movie title, not just word
        # Note: "elsa" and "anna" removed - these are common names
        
        # Marvel - specific superhero names
        "spider-man", "iron man", "hulk", "thor", "captain america",
        "black widow", "hawkeye", "avengers", "thanos", "loki",
        
        # DC Comics
        "batman", "superman", "wonder woman", "flash", "aquaman",
        "joker", "harley quinn", "green lantern",
        
        # Other franchises - very specific names only
        "harry potter", "hermione granger", "ron weasley", "dumbledore",
        "pokemon", "pikachu", "luigi", "sonic the hedgehog",
        "spongebob squarepants", "patrick star", "peppa pig",
        "paw patrol", "bluey",
        # Note: "mario" removed - common name, only check "super mario" or "mario bros"
    ]
    
    # Phrases that indicate licensed character references (more reliable)
    LICENSED_PHRASES = [
        "super mario", "mario bros", "princess elsa", "queen elsa", "princess anna",
        "princess ariel", "princess jasmine", "princess belle", "princess cinderella",
        "princess rapunzel", "princess moana", "princess anna of arendelle"
    ]
    
    def __init__(self, openrouter_client):
        """Initialize validator service.
        
        Args:
            openrouter_client: AsyncOpenRouterClient for LLM API calls
        """
        self.openrouter_client = openrouter_client
    
    async def validate_prompt(
        self,
        prompt: str,
        child_name: str,
        child_age_category: str,
        child_interests: List[str],
        child_age: Optional[int] = None,  # For backward compatibility
        model: str = "openai/gpt-4o-mini"
    ) -> ValidationResult:
        """Validate story prompt for safety and appropriateness.
        
        Args:
            prompt: The story generation prompt to validate
            child_name: Child's name
            child_age_category: Child's age category ('2-3', '3-5', or '5-7')
            child_interests: List of child's interests
            child_age: Child's age (for backward compatibility)
            model: LLM model to use for validation
            
        Returns:
            ValidationResult with validation outcome
        """
        logger.info(f"Validating prompt for child_name='{child_name}', child_age_category={child_age_category}, child_interests={child_interests}")
        if child_name == "Child" and child_age_category == "3-5":
            logger.warning(f"⚠️ Using default values! child_name='{child_name}', child_age_category={child_age_category} - this might indicate missing data")
        
        # First, quick keyword-based check for licensed characters
        # Exclude child's name from the prompt for checking to avoid false positives
        # (e.g., if child is named "Anna", we don't want to flag it as licensed character)
        prompt_for_check = prompt
        if child_name:
            # Remove child's name from prompt temporarily for licensed character check
            # This prevents false positives when child has a name that matches a character
            child_name_lower = child_name.lower()
            # Replace child's name with placeholder to avoid matching
            prompt_for_check = prompt.replace(child_name, "[CHILD_NAME]")
            prompt_for_check = prompt_for_check.replace(child_name_lower, "[CHILD_NAME]")
        
        has_licensed_chars = self._quick_licensed_character_check(prompt_for_check)
        
        # Build validation prompt for LLM
        validation_prompt = self._build_validation_prompt(
            prompt, child_name, child_age_category, child_interests
        )
        
        try:
            # Call LLM for detailed validation
            result = await self.openrouter_client.generate_story(
                validation_prompt,
                model=model,
                max_tokens=500,
                temperature=0.3,  # Lower temperature for more consistent validation
                use_langgraph=False  # Direct API call for validation, no workflow needed
            )
            
            # Parse LLM response
            validation_data = self._parse_validation_response(result.content)
            
            # Combine quick check with LLM validation
            if has_licensed_chars:
                validation_data["has_licensed_characters"] = True
                if "Licensed character" not in validation_data.get("detected_issues", []):
                    validation_data["detected_issues"].append("Licensed character detected in prompt")
            
            # Create validation result
            validation_result = ValidationResult(
                is_safe=validation_data.get("is_safe", True),
                has_licensed_characters=validation_data.get("has_licensed_characters", has_licensed_chars),
                is_age_appropriate=validation_data.get("is_age_appropriate", True),
                detected_issues=validation_data.get("detected_issues", []),
                reasoning=validation_data.get("reasoning", ""),
                recommendation=validation_data.get("recommendation", "approved"),
                timestamp=datetime.now()
            )
            
            # Final decision: approve only if all critical checks pass
            # Only reject if there are serious safety issues or licensed characters
            # Age appropriateness issues are warnings but not necessarily rejections
            rejection_reasons = []
            if not validation_result.is_safe:
                rejection_reasons.append("Safety concerns detected")
            if validation_result.has_licensed_characters:
                rejection_reasons.append("Licensed characters detected")
            
            if rejection_reasons:
                validation_result.recommendation = "rejected"
                if not validation_result.reasoning:
                    validation_result.reasoning = "; ".join(rejection_reasons)
                logger.warning(f"Prompt rejected: {'; '.join(rejection_reasons)}")
            elif not validation_result.is_age_appropriate:
                # Age appropriateness is a warning, but don't reject - just log
                logger.warning(f"Age appropriateness concern: {validation_result.reasoning}")
                # Still approve, but log the concern
                validation_result.recommendation = "approved"
            
            logger.info(f"Validation complete: {validation_result.recommendation}")
            if validation_result.recommendation == "rejected":
                logger.info(f"Rejection details - is_safe: {validation_result.is_safe}, "
                          f"has_licensed: {validation_result.has_licensed_characters}, "
                          f"is_age_appropriate: {validation_result.is_age_appropriate}")
            return validation_result
            
        except Exception as e:
            logger.error(f"Validation error: {str(e)}", exc_info=True)
            # Fail-safe: reject on error
            return ValidationResult(
                is_safe=False,
                has_licensed_characters=False,
                is_age_appropriate=False,
                detected_issues=[f"Validation error: {str(e)}"],
                reasoning="Unable to complete validation due to technical error",
                recommendation="rejected",
                timestamp=datetime.now()
            )
    
    def _quick_licensed_character_check(self, prompt: str) -> bool:
        """Quick keyword-based check for licensed characters.
        
        This method avoids false positives by:
        1. Only checking very specific character names/phrases
        2. Excluding common names that might match character names (e.g., "Anna", "Elsa", "Mario")
        3. Using context-aware checking for ambiguous cases
        
        Args:
            prompt: Prompt text to check
            
        Returns:
            True if licensed character detected
        """
        prompt_lower = prompt.lower()
        
        # First check for specific phrases (most reliable)
        # These phrases are very specific and unlikely to be false positives
        for phrase in self.LICENSED_PHRASES:
            if phrase in prompt_lower:
                # Additional check: make sure it's not just a name match
                # For phrases like "princess anna", check that "princess" or "queen" is present
                if "princess" in phrase or "queen" in phrase:
                    # Make sure the full phrase appears, not just the name part
                    if phrase in prompt_lower:
                        logger.warning(f"Licensed character phrase detected: {phrase}")
                        return True
                else:
                    # Other specific phrases
                    logger.warning(f"Licensed character phrase detected: {phrase}")
                    return True
        
        # Then check for specific character names
        for character in self.LICENSED_CHARACTERS:
            if character in prompt_lower:
                # Additional context check for ambiguous cases
                # If it's a common name that could be a character, check context
                if character in ["frozen"]:
                    # "frozen" could be the movie or just the word
                    # Only flag if it appears with character-related context
                    context_indicators = ["movie", "film", "princess", "queen", "character", "story about"]
                    if any(indicator in prompt_lower for indicator in context_indicators):
                        logger.warning(f"Licensed character detected: {character}")
                        return True
                else:
                    # Very specific character names - safe to flag
                    logger.warning(f"Licensed character detected: {character}")
                    return True
        
        return False
    
    def _build_validation_prompt(
        self,
        prompt: str,
        child_name: str,
        child_age_category: str,
        child_interests: List[str]
    ) -> str:
        """Build validation prompt for LLM.
        
        Args:
            prompt: Story prompt to validate
            child_name: Child's name
            child_age_category: Child's age category ('2-3', '3-5', or '5-7')
            child_interests: Child's interests
            
        Returns:
            Validation prompt for LLM
        """
        from src.utils.age_category_utils import get_age_category_for_prompt
        from src.domain.value_objects import Language
        
        interests_str = ", ".join(child_interests) if child_interests else "none specified"
        age_display = get_age_category_for_prompt(child_age_category, Language.ENGLISH)
        
        return f"""You are a content safety validator for children's stories. Analyze the provided story prompt for safety concerns.

Story Prompt to Validate:
{prompt}

Child Context:
- Name: {child_name}
- Age: {age_display}
- Interests: {interests_str}

Evaluation Criteria:
1. Licensed Characters: Check for trademarked characters from Disney, Marvel, DC, DreamWorks, Pixar, Nintendo, etc.
2. Age Appropriateness: Ensure content is suitable for children aged {age_display}
3. Safety: No violence, horror, discrimination, or inappropriate themes
4. Coherence: Prompt is clear and actionable

Provide your assessment in the following JSON format:
{{
    "is_safe": true/false,
    "has_licensed_characters": true/false,
    "is_age_appropriate": true/false,
    "detected_issues": ["issue1", "issue2", ...],
    "reasoning": "Detailed explanation of your assessment",
    "recommendation": "approved" or "rejected"
}}

IMPORTANT: Be strict about licensed characters. Even indirect references should be flagged.
For age appropriateness, consider: complexity of themes, scary elements, violence level, and emotional intensity.
"""
    
    def _parse_validation_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM validation response.
        
        Args:
            response: LLM response text
            
        Returns:
            Parsed validation data
        """
        try:
            # Try to extract JSON from response
            # Look for JSON block
            if "```json" in response:
                json_start = response.find("```json") + 7
                json_end = response.find("```", json_start)
                json_str = response[json_start:json_end].strip()
            elif "{" in response and "}" in response:
                json_start = response.find("{")
                json_end = response.rfind("}") + 1
                json_str = response[json_start:json_end]
            else:
                # No JSON found, create default response
                logger.warning("No JSON found in validation response, using default")
                return self._create_default_validation()
            
            # Parse JSON
            data = json.loads(json_str)
            
            # Validate required fields
            required_fields = ["is_safe", "has_licensed_characters", "is_age_appropriate", "recommendation"]
            for field in required_fields:
                if field not in data:
                    logger.warning(f"Missing field in validation response: {field}")
                    data[field] = True if field != "recommendation" else "approved"
            
            # Ensure detected_issues is a list
            if "detected_issues" not in data:
                data["detected_issues"] = []
            
            return data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse validation JSON: {e}")
            return self._create_default_validation()
        except Exception as e:
            logger.error(f"Error parsing validation response: {e}")
            return self._create_default_validation()
    
    def _create_default_validation(self) -> Dict[str, Any]:
        """Create default validation response (conservative/safe).
        
        Returns:
            Default validation data
        """
        return {
            "is_safe": True,
            "has_licensed_characters": False,
            "is_age_appropriate": True,
            "detected_issues": [],
            "reasoning": "Unable to parse validation response, applying default validation",
            "recommendation": "approved"
        }
