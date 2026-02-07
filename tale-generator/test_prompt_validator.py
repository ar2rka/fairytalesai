"""Tests for PromptValidatorService: safety and age checks only, no licensed character validation.

Run with: uv run python -m unittest test_prompt_validator -v
Or: uv run python test_prompt_validator.py
"""

import json
import asyncio
import unittest
from unittest.mock import AsyncMock, MagicMock

from src.domain.services.langgraph.prompt_validator import PromptValidatorService


def _make_llm_response(
    is_safe: bool = True,
    is_age_appropriate: bool = True,
    recommendation: str = "approved",
    **kwargs,
) -> str:
    """Build JSON string that _parse_validation_response expects."""
    data = {
        "is_safe": is_safe,
        "is_age_appropriate": is_age_appropriate,
        "recommendation": recommendation,
        "detected_issues": kwargs.get("detected_issues", []),
        "reasoning": kwargs.get("reasoning", ""),
    }
    return json.dumps(data)


def run_async(coro):
    """Run async test coroutine."""
    return asyncio.run(coro)


class TestPromptValidatorNoLicensedCheck(unittest.TestCase):
    """Licensed characters are not validated; has_licensed_characters is always False."""

    def setUp(self):
        self.mock_client = MagicMock()
        self.mock_client.generate_story = AsyncMock()
        self.validator = PromptValidatorService(self.mock_client)

    def test_prompt_with_licensed_character_names_does_not_reject(self):
        """Prompt containing Mickey Mouse, princess Elsa etc. does not cause rejection."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True, is_age_appropriate=True, recommendation="approved"
            )
        )
        prompt = "A bedtime story about Mickey Mouse and princess Elsa visiting a forest."
        result = run_async(
            self.validator.validate_prompt(
                prompt=prompt,
                child_name="Alex",
                age_category="3-5",
                child_interests=["animals"],
            )
        )
        self.assertEqual(result.recommendation, "approved")
        self.assertFalse(result.has_licensed_characters)
        self.assertTrue(result.is_safe)

    def test_has_licensed_characters_always_false_when_approved(self):
        """has_licensed_characters is always False regardless of prompt (no licensed check)."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True, is_age_appropriate=True, recommendation="approved"
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="Story with Pikachu and Spider-Man.",
                child_name="Child",
                age_category="5-7",
                child_interests=[],
            )
        )
        self.assertFalse(result.has_licensed_characters)
        self.assertEqual(result.recommendation, "approved")


class TestPromptValidatorSafetyRejection(unittest.TestCase):
    """Rejection only on is_safe=False (bad/forbidden content)."""

    def setUp(self):
        self.mock_client = MagicMock()
        self.mock_client.generate_story = AsyncMock()
        self.validator = PromptValidatorService(self.mock_client)

    def test_unsafe_content_rejected(self):
        """When LLM returns is_safe=False, recommendation is rejected."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=False,
                is_age_appropriate=False,
                recommendation="rejected",
                reasoning="Violence and inappropriate themes.",
                detected_issues=["Violence", "Inappropriate content"],
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="A story with graphic violence.",
                child_name="Test",
                age_category="5-7",
                child_interests=[],
            )
        )
        self.assertEqual(result.recommendation, "rejected")
        self.assertFalse(result.is_safe)
        self.assertFalse(result.has_licensed_characters)

    def test_safe_content_approved(self):
        """When LLM returns is_safe=True, recommendation is approved."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True, is_age_appropriate=True, recommendation="approved"
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="A gentle story about a rabbit learning to share.",
                child_name="Mia",
                age_category="2-3",
                child_interests=["bunnies"],
            )
        )
        self.assertEqual(result.recommendation, "approved")
        self.assertTrue(result.is_safe)


class TestPromptValidatorAgeAppropriatenessWarning(unittest.TestCase):
    """Age appropriateness is a warning only; does not force rejection."""

    def setUp(self):
        self.mock_client = MagicMock()
        self.mock_client.generate_story = AsyncMock()
        self.validator = PromptValidatorService(self.mock_client)

    def test_age_inappropriate_but_safe_still_approved(self):
        """When is_safe=True but is_age_appropriate=False, we still approve (warning only)."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True,
                is_age_appropriate=False,
                recommendation="approved",
                reasoning="Themes might be complex for 2-3.",
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="A story about losing a pet.",
                child_name="Sam",
                age_category="2-3",
                child_interests=[],
            )
        )
        self.assertEqual(result.recommendation, "approved")
        self.assertTrue(result.is_safe)
        self.assertFalse(result.is_age_appropriate)


class TestValidationPromptContent(unittest.TestCase):
    """Validation prompt asks only for safety and age, not licensed characters."""

    def setUp(self):
        self.validator = PromptValidatorService(MagicMock())

    def test_build_validation_prompt_does_not_ask_for_licensed_characters(self):
        """_build_validation_prompt tells LLM not to check for licensed characters."""
        prompt_text = self.validator._build_validation_prompt(
            prompt="Some prompt.",
            child_name="Child",
            age_category="3-5",
            child_interests=[],
            moral="kindness",
        )
        self.assertIn("do not check for licensed", prompt_text.lower())
        self.assertIn("is_safe", prompt_text)
        self.assertIn("is_age_appropriate", prompt_text)
        self.assertNotIn("has_licensed_characters", prompt_text)

    def test_build_validation_prompt_includes_moral(self):
        """_build_validation_prompt includes moral in context and validates it."""
        prompt_text = self.validator._build_validation_prompt(
            prompt="A story.",
            child_name="Kid",
            age_category="5-7",
            child_interests=["dinosaurs"],
            moral="honesty",
        )
        self.assertIn("honesty", prompt_text)
        self.assertIn("Moral", prompt_text)
        self.assertIn("moral", prompt_text.lower())

    def test_build_validation_prompt_includes_safety_and_age(self):
        """_build_validation_prompt includes safety and age criteria."""
        prompt_text = self.validator._build_validation_prompt(
            prompt="A story.",
            child_name="Kid",
            age_category="5-7",
            child_interests=["dinosaurs"],
            moral="kindness",
        )
        self.assertTrue(
            "age" in prompt_text.lower(),
            "Prompt should mention age",
        )
        self.assertTrue(
            "safety" in prompt_text.lower() or "violence" in prompt_text.lower() or "forbidden" in prompt_text.lower(),
            "Prompt should mention safety/forbidden content",
        )


class TestParseValidationResponse(unittest.TestCase):
    """Parsing LLM response does not require has_licensed_characters."""

    def setUp(self):
        self.validator = PromptValidatorService(MagicMock())

    def test_parse_response_without_has_licensed_characters(self):
        """Parsing works when LLM does not return has_licensed_characters."""
        response = _make_llm_response(
            is_safe=True, is_age_appropriate=True, recommendation="approved"
        )
        data = self.validator._parse_validation_response(response)
        self.assertTrue(data["is_safe"])
        self.assertTrue(data["is_age_appropriate"])
        self.assertEqual(data["recommendation"], "approved")


class TestMoralValidation(unittest.TestCase):
    """Moral is passed to validation and checked for appropriateness."""

    def setUp(self):
        self.mock_client = MagicMock()
        self.mock_client.generate_story = AsyncMock()
        self.validator = PromptValidatorService(self.mock_client)

    def test_validate_prompt_accepts_moral_parameter(self):
        """validate_prompt accepts moral and uses it in validation (LLM sees it)."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True, is_age_appropriate=True, recommendation="approved"
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="A story about sharing.",
                child_name="Mia",
                age_category="3-5",
                child_interests=[],
                moral="friendship",
            )
        )
        self.assertEqual(result.recommendation, "approved")
        call_args = self.mock_client.generate_story.call_args
        self.assertIsNotNone(call_args)
        validation_prompt = call_args[0][0]
        self.assertIn("friendship", validation_prompt)

    def test_validate_prompt_default_moral_kindness(self):
        """When moral is not passed, default is used and validation runs."""
        self.mock_client.generate_story.return_value = MagicMock(
            content=_make_llm_response(
                is_safe=True, is_age_appropriate=True, recommendation="approved"
            )
        )
        result = run_async(
            self.validator.validate_prompt(
                prompt="A story.",
                child_name="X",
                age_category="3-5",
                child_interests=[],
            )
        )
        self.assertEqual(result.recommendation, "approved")
        call_args = self.mock_client.generate_story.call_args
        validation_prompt = call_args[0][0]
        self.assertIn("kindness", validation_prompt)


class TestValidationErrorHandling(unittest.TestCase):
    """On error, reject and has_licensed_characters is False."""

    def setUp(self):
        self.mock_client = MagicMock()
        self.mock_client.generate_story = AsyncMock(side_effect=Exception("API error"))
        self.validator = PromptValidatorService(self.mock_client)

    def test_on_llm_error_returns_rejected_with_no_licensed(self):
        """When generate_story raises, result is rejected and has_licensed_characters is False."""
        result = run_async(
            self.validator.validate_prompt(
                prompt="Any prompt.",
                child_name="X",
                age_category="3-5",
                child_interests=[],
            )
        )
        self.assertEqual(result.recommendation, "rejected")
        self.assertFalse(result.is_safe)
        self.assertFalse(result.has_licensed_characters)


if __name__ == "__main__":
    unittest.main()
