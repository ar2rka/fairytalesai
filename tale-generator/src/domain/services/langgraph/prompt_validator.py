"""Prompt validation service using LLM-based content safety checks."""

import json
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from src.domain.services.langgraph.workflow_state import ValidationResult
from src.core.logging import get_logger

logger = get_logger("langgraph.prompt_validator")


class PromptValidatorService:
    """Service for validating story prompts for safety and appropriateness.
    
    Validates only: age appropriateness (moral) and absence of bad/forbidden content.
    Licensed character checks are not performed.
    """

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
        age_category: str,
        child_interests: List[str],
        moral: str = "kindness",
        model: str = "openai/gpt-4o-mini"
    ) -> ValidationResult:
        """Validate story prompt for safety and appropriateness.
        
        Args:
            prompt: The story generation prompt to validate
            child_name: Child's name
            age_category: Child's age category ('2-3', '3-5', or '5-7')
            child_interests: List of child's interests
            moral: Moral value for the story (validated for appropriateness)
            model: LLM model to use for validation
            
        Returns:
            ValidationResult with validation outcome
        """
        logger.info(f"Validating prompt for child_name='{child_name}', age_category={age_category}, moral='{moral}', child_interests={child_interests}")
        # Normalize age category for comparison
        from src.utils.age_category_utils import normalize_age_category
        try:
            normalized_age_category = normalize_age_category(age_category)
            if child_name == "Child" and normalized_age_category == "3-5":
                logger.warning(f"⚠️ Using default values! child_name='{child_name}', age_category={normalized_age_category} - this might indicate missing data")
        except (ValueError, AttributeError):
            # If normalization fails, just log the original value
            if child_name == "Child":
                logger.warning(f"⚠️ Using default values! child_name='{child_name}', age_category={age_category} - this might indicate missing data")
        
        # Quick check: moral must be non-empty
        moral_clean = (moral or "").strip()
        if not moral_clean:
            logger.warning("Moral is empty, using default 'kindness' for validation")
            moral_clean = "kindness"

        # Build validation prompt for LLM (safety + age + moral appropriateness)
        validation_prompt = self._build_validation_prompt(
            prompt, child_name, age_category, child_interests, moral_clean
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
            
            # Create validation result (licensed characters not checked)
            validation_result = ValidationResult(
                is_safe=validation_data.get("is_safe", True),
                has_licensed_characters=False,  # Not validated anymore
                is_age_appropriate=validation_data.get("is_age_appropriate", True),
                detected_issues=validation_data.get("detected_issues", []),
                reasoning=validation_data.get("reasoning", ""),
                recommendation=validation_data.get("recommendation", "approved"),
                timestamp=datetime.now()
            )
            
            # Final decision: reject only on safety concerns (bad/forbidden content)
            # Age appropriateness issues are warnings, not rejections
            rejection_reasons = []
            if not validation_result.is_safe:
                rejection_reasons.append("Safety concerns detected")
            
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
    
    def _build_validation_prompt(
        self,
        prompt: str,
        child_name: str,
        age_category: str,
        child_interests: List[str],
        moral: str,
    ) -> str:
        """Build validation prompt for LLM.
        
        Args:
            prompt: Story prompt to validate
            child_name: Child's name
            age_category: Child's age category ('2-3', '3-5', or '5-7')
            child_interests: Child's interests
            moral: Moral value for the story (must be appropriate for children)
            
        Returns:
            Validation prompt for LLM
        """
        from src.utils.age_category_utils import get_age_category_for_prompt
        from src.domain.value_objects import Language
        
        interests_str = ", ".join(child_interests) if child_interests else "none specified"
        age_display = get_age_category_for_prompt(age_category, Language.ENGLISH)
        
        return f"""You are a content safety validator for children's stories. Analyze the provided story prompt.

Story Prompt to Validate:
{prompt}

Child Context:
- Name: {child_name}
- Age: {age_display}
- Interests: {interests_str}
- Moral (intended lesson): {moral}

Evaluation Criteria (check only these):
1. Moral correctness: The stated moral "{moral}" must be appropriate for children—a positive value (e.g. kindness, honesty, bravery, friendship). Reject if moral is empty, harmful, promotes negative values, or is inappropriate for kids.
2. Age Appropriateness: Content must be suitable for children aged {age_display}. Consider: complexity of themes, scary elements, violence level, emotional intensity.
3. Safety: No violence, horror, discrimination, inappropriate themes, or forbidden content.
4. Coherence: Prompt is clear and actionable.

Do NOT check for licensed/trademarked characters.

Provide your assessment in the following JSON format:
{{
    "is_safe": true/false,
    "is_age_appropriate": true/false,
    "detected_issues": ["issue1", "issue2", ...],
    "reasoning": "Detailed explanation of your assessment",
    "recommendation": "approved" or "rejected"
}}

Reject (recommendation: "rejected") if: the moral is inappropriate, or there are safety concerns/forbidden content. Age appropriateness concerns can be noted in reasoning but do not require rejection.
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
            required_fields = ["is_safe", "is_age_appropriate", "recommendation"]
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
