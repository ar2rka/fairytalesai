"""Quality assessment service for evaluating generated stories."""

import json
import logging
import re
from typing import Dict, Any, Optional
from datetime import datetime

from src.domain.services.langgraph.workflow_state import QualityAssessment
from src.core.logging import get_logger

logger = get_logger("langgraph.quality_assessor")


class QualityAssessorService:
    """Service for assessing story quality using LLM-based evaluation."""

    THEME_KEYWORDS = {
        "en": {
            "space": ["space", "planet", "star", "galaxy", "astronaut", "rocket", "cosmic"],
            "pirates": ["pirate", "ship", "treasure", "map", "captain", "island", "ocean"],
            "dinosaurs": ["dinosaur", "dinosaurs", "t-rex", "trex", "triceratops", "fossil", "prehistoric", "jurassic"],
            "mermaids": ["mermaid", "mermaids", "underwater", "coral", "sea", "ocean", "tail"],
            "animals": ["animal", "animals", "forest", "jungle", "habitat", "creature"],
            "mystery": ["mystery", "clue", "detective", "puzzle", "secret", "investigate"],
            "magic school": ["magic school", "wizard", "spell", "classroom", "wand", "academy"],
            "robots": ["robot", "robots", "machine", "circuit", "android", "mechanical"],
        },
        "ru": {
            "space": ["космос", "планета", "звезда", "галактика", "астронавт", "ракета"],
            "pirates": ["пират", "корабль", "сокровищ", "карта", "капитан", "остров", "океан"],
            "dinosaurs": ["динозавр", "динозавры", "тираннозавр", "трекс", "т-рекс", "ископаем", "доисторичес"],
            "mermaids": ["русалк", "подводн", "коралл", "море", "океан"],
            "animals": ["животн", "лес", "джунгл", "звер", "существ"],
            "mystery": ["тайн", "улик", "детектив", "загадк", "расслед"],
            "magic school": ["школа магии", "маг", "заклинан", "волшебн", "академ"],
            "robots": ["робот", "машин", "механичес", "андроид", "схем"],
        }
    }
    
    # Quality criteria weights for calculating overall score
    CRITERIA_WEIGHTS = {
        "theme_adherence_score": 0.20,  # High weight
        "age_appropriateness_score": 0.17,  # High weight
        "moral_clarity_score": 0.17,  # High weight
        "narrative_coherence_score": 0.17,  # High weight
        "character_consistency_score": 0.11,  # Medium weight
        "engagement_score": 0.10,  # Medium weight
        "language_quality_score": 0.08,  # Medium weight
    }
    
    def __init__(self, openrouter_client):
        """Initialize quality assessor service.
        
        Args:
            openrouter_client: AsyncOpenRouterClient for LLM API calls
        """
        self.openrouter_client = openrouter_client
    
    async def assess_quality(
        self,
        story_content: str,
        title: str,
        age_category: str,
        moral: str,
        theme: Optional[str],
        language: str,
        expected_word_count: int,
        model: str = "openai/gpt-4o-mini",
        plot: Optional[str] = None
    ) -> QualityAssessment:
        """Assess story quality across multiple criteria.
        
        Args:
            story_content: Generated story content
            title: Story title
            age_category: Target child's age category ('2-3', '3-5', or '5-7')
            moral: Expected moral value
            language: Story language (en/ru)
            expected_word_count: Expected word count
            model: LLM model to use for assessment
            
        Returns:
            QualityAssessment with scores and feedback
        """
        logger.info(f"Assessing quality for story: {title}")
        
        # Build assessment prompt for LLM
        assessment_prompt = self._build_assessment_prompt(
            story_content, title, age_category, moral, theme, language, expected_word_count, plot
        )
        
        try:
            # Call LLM for quality assessment
            # Use direct API call, NOT LangGraph workflow (we're already inside a workflow!)
            result = await self.openrouter_client.generate_story(
                assessment_prompt,
                model=model,
                max_tokens=800,
                temperature=0.3,  # Lower temperature for consistent assessment
                use_langgraph=False  # CRITICAL: Don't create nested workflow!
            )
            
            # Parse LLM response
            assessment_data = self._parse_assessment_response(result.content)

            # Deterministic guard: if theme-specific vocabulary is absent, cap theme score.
            heuristic_theme_score = self._heuristic_theme_score(
                story_content=story_content,
                theme=theme,
                language=language
            )
            if heuristic_theme_score is not None:
                model_theme_score = assessment_data.get("theme_adherence_score", 5)
                adjusted_theme_score = min(model_theme_score, heuristic_theme_score)
                assessment_data["theme_adherence_score"] = adjusted_theme_score
                if adjusted_theme_score < model_theme_score:
                    assessment_data["feedback"] = (
                        f"{assessment_data.get('feedback', '').strip()} "
                        f"Theme adherence adjusted by keyword check."
                    ).strip()
                    suggestions = assessment_data.get("improvement_suggestions", [])
                    if not isinstance(suggestions, list):
                        suggestions = [str(suggestions)]
                    suggestions.append(f"Make the '{theme}' theme explicit with concrete themed elements.")
                    assessment_data["improvement_suggestions"] = suggestions

            # Always recompute weighted overall score so theme adherence affects regeneration decisions.
            assessment_data["overall_score"] = self._calculate_weighted_score(assessment_data)
            
            # Create quality assessment
            quality_assessment = QualityAssessment(
                overall_score=assessment_data.get("overall_score", 5),
                theme_adherence_score=assessment_data.get("theme_adherence_score", 5),
                age_appropriateness_score=assessment_data.get("age_appropriateness_score", 5),
                moral_clarity_score=assessment_data.get("moral_clarity_score", 5),
                narrative_coherence_score=assessment_data.get("narrative_coherence_score", 5),
                character_consistency_score=assessment_data.get("character_consistency_score", 5),
                engagement_score=assessment_data.get("engagement_score", 5),
                language_quality_score=assessment_data.get("language_quality_score", 5),
                feedback=assessment_data.get("feedback", ""),
                improvement_suggestions=assessment_data.get("improvement_suggestions", []),
                timestamp=datetime.now()
            )
            
            logger.info(f"✅ Quality assessment complete: {quality_assessment.overall_score}/10")
            logger.info(f"📊 Scores breakdown: Age={quality_assessment.age_appropriateness_score}, Moral={quality_assessment.moral_clarity_score}, Narrative={quality_assessment.narrative_coherence_score}")
            logger.info(f"📝 Feedback length: {len(quality_assessment.feedback)} chars")
            logger.info(f"💡 Suggestions: {len(quality_assessment.improvement_suggestions)} items")
            return quality_assessment
            
        except Exception as e:
            logger.error(f"Quality assessment error: {str(e)}", exc_info=True)
            # Return default mid-range assessment on error
            return QualityAssessment(
                overall_score=5,
                theme_adherence_score=5,
                age_appropriateness_score=5,
                moral_clarity_score=5,
                narrative_coherence_score=5,
                character_consistency_score=5,
                engagement_score=5,
                language_quality_score=5,
                feedback=f"Assessment error: {str(e)}",
                improvement_suggestions=["Unable to complete assessment due to technical error"],
                timestamp=datetime.now()
            )
    
    def _build_assessment_prompt(
        self,
        story_content: str,
        title: str,
        age_category: str,
        moral: str,
        theme: Optional[str],
        language: str,
        expected_word_count: int,
        plot: Optional[str] = None
    ) -> str:
        """Build assessment prompt for LLM.
        
        Args:
            story_content: Story to assess
            title: Story title
            age_category: Target age category ('2-3', '3-5', or '5-7')
            moral: Expected moral
            language: Language (en/ru)
            expected_word_count: Expected word count
            
        Returns:
            Assessment prompt for LLM
        """
        from src.utils.age_category_utils import get_age_category_for_prompt
        from src.domain.value_objects import Language
        
        lang_enum = Language.ENGLISH if language == "en" else Language.RUSSIAN
        lang_name = "English" if language == "en" else "Russian"
        age_display = get_age_category_for_prompt(age_category, lang_enum)
        
        return f"""You are a children's story quality evaluator. Assess the provided story across multiple dimensions.

Story Title: {title}

Story Content:
{story_content}

Story Requirements:
- Target Age: {age_display}
- Moral: {moral}
- Theme: {theme or "adventure"}
- Plot Direction: {plot or "None specified"}
- Language: {lang_name}
- Expected Length: {expected_word_count} words

Evaluation Criteria (score each 1-10):
1. Theme Adherence (1-10): Does the story clearly match the requested theme "{theme or 'adventure'}" in setting, events, and imagery{f', while also incorporating the plot direction "{plot}"' if plot else ''}?
2. Age Appropriateness (1-10): Does the language complexity, themes, and content match children aged {age_display} developmental level?
3. Moral Clarity (1-10): Is the moral lesson about "{moral}" clearly and naturally integrated into the story?
4. Narrative Coherence (1-10): Does the story have a clear beginning, middle, and end with logical flow?
5. Character Consistency (1-10): Do characters behave believably and consistently throughout?
6. Engagement (1-10): Is the story interesting and likely to maintain a child's attention?
7. Language Quality (1-10): Is the grammar correct, vocabulary appropriate, and style engaging?

Additional Considerations:
- Does the story length approximately match the expected word count?
- Are there any concerning elements (scary, violent, inappropriate)?
- Is the story original and creative?
- The story must have a clear, natural ending. If there is a long repetitive, nonsensical, or stream-of-consciousness word salad at the end (e.g. endless synonyms, religious exclamations, or run-on words without proper sentences), score Narrative Coherence and Language Quality low (e.g. 1-3) and mention this in feedback.

Provide your assessment in the following JSON format:
{{
    "theme_adherence_score": <1-10>,
    "age_appropriateness_score": <1-10>,
    "moral_clarity_score": <1-10>,
    "narrative_coherence_score": <1-10>,
    "character_consistency_score": <1-10>,
    "engagement_score": <1-10>,
    "language_quality_score": <1-10>,
    "overall_score": <1-10>,
    "feedback": "Detailed explanation of scores and observations",
    "improvement_suggestions": ["suggestion1", "suggestion2", ...]
}}

IMPORTANT: Be critical but fair. A score of 7+ means high quality. Scores of 5-6 mean needs improvement. Below 5 means significant issues.
"""
    
    def _parse_assessment_response(self, response: str) -> Dict[str, Any]:
        """Parse LLM assessment response.
        
        Args:
            response: LLM response text
            
        Returns:
            Parsed assessment data
        """
        try:
            # Try to extract JSON from response
            if "```json" in response:
                json_start = response.find("```json") + 7
                json_end = response.find("```", json_start)
                json_str = response[json_start:json_end].strip()
            elif "```" in response:
                json_start = response.find("```") + 3
                json_end = response.find("```", json_start)
                json_str = response[json_start:json_end].strip()
            elif "{" in response and "}" in response:
                json_start = response.find("{")
                json_end = response.rfind("}") + 1
                json_str = response[json_start:json_end]
                # Ensure we have a closing brace
                if not json_str.endswith("}"):
                    # Try to find the last closing brace more carefully
                    brace_count = 0
                    for i in range(json_start, len(response)):
                        if response[i] == '{':
                            brace_count += 1
                        elif response[i] == '}':
                            brace_count -= 1
                            if brace_count == 0:
                                json_str = response[json_start:i+1]
                                break
                    # If still no closing brace, add one
                    if not json_str.endswith("}"):
                        json_str += "}"
            else:
                logger.warning("No JSON found in assessment response")
                return self._create_default_assessment()
            
            # Clean JSON string - remove ALL control characters (more aggressive)
            json_str = re.sub(r'[\x00-\x1f]', '', json_str)
            
            # Try to parse JSON
            try:
                data = json.loads(json_str)
            except json.JSONDecodeError as json_error:
                logger.warning(f"Initial JSON parse failed: {json_error}. Attempting recovery...")
                
                # Try to extract fields using regex as fallback
                try:
                    # Extract scores using regex
                    data = {}
                    
                    # Extract all score fields
                    score_fields = [
                        "theme_adherence_score",
                        "age_appropriateness_score",
                        "moral_clarity_score",
                        "narrative_coherence_score",
                        "character_consistency_score",
                        "engagement_score",
                        "language_quality_score",
                        "overall_score"
                    ]
                    
                    for field in score_fields:
                        pattern = rf'"{field}"\s*:\s*(\d+)'
                        match = re.search(pattern, json_str)
                        if match:
                            data[field] = int(match.group(1))
                    
                    # Extract feedback
                    feedback_match = re.search(r'"feedback"\s*:\s*"((?:[^"\\]|\\.)*)"', json_str, re.DOTALL)
                    if feedback_match:
                        # Unescape JSON string
                        feedback = feedback_match.group(1).replace('\\"', '"').replace('\\n', '\n')
                        data["feedback"] = feedback
                    else:
                        data["feedback"] = ""
                    
                    # Extract improvement_suggestions
                    suggestions_match = re.search(r'"improvement_suggestions"\s*:\s*\[(.*?)\]', json_str, re.DOTALL)
                    if suggestions_match:
                        suggestions_str = suggestions_match.group(1)
                        # Try to extract individual suggestions
                        suggestions = []
                        for match in re.finditer(r'"((?:[^"\\]|\\.)*)"', suggestions_str):
                            suggestion = match.group(1).replace('\\"', '"')
                            if suggestion:
                                suggestions.append(suggestion)
                        data["improvement_suggestions"] = suggestions
                    else:
                        data["improvement_suggestions"] = []
                    
                    logger.info(f"Successfully extracted assessment data using regex fallback")
                    
                except Exception as regex_error:
                    logger.error(f"Regex extraction also failed: {regex_error}")
                    raise json_error
            
            # Validate and clamp scores to 1-10 range
            score_fields = [
                "theme_adherence_score",
                "age_appropriateness_score",
                "moral_clarity_score",
                "narrative_coherence_score",
                "character_consistency_score",
                "engagement_score",
                "language_quality_score",
                "overall_score"
            ]
            
            for field in score_fields:
                if field in data:
                    # Clamp to valid range
                    data[field] = max(1, min(10, int(data[field])))
                else:
                    # Default to mid-range if missing
                    data[field] = 5
            
            # Ensure improvement_suggestions is a list
            if "improvement_suggestions" not in data:
                data["improvement_suggestions"] = []
            elif isinstance(data["improvement_suggestions"], str):
                data["improvement_suggestions"] = [data["improvement_suggestions"]]
            
            # Ensure feedback is a string
            if "feedback" not in data:
                data["feedback"] = ""
            
            return data
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse assessment JSON: {e}")
            return self._create_default_assessment()
        except Exception as e:
            logger.error(f"Error parsing assessment response: {e}")
            return self._create_default_assessment()
    
    def _calculate_weighted_score(self, assessment_data: Dict[str, Any]) -> int:
        """Calculate weighted overall score from individual criteria.
        
        Args:
            assessment_data: Assessment data with individual scores
            
        Returns:
            Weighted overall score (1-10)
        """
        weighted_sum = 0.0
        for criterion, weight in self.CRITERIA_WEIGHTS.items():
            score = assessment_data.get(criterion, 5)
            weighted_sum += score * weight
        
        # Round to nearest integer
        overall = round(weighted_sum)
        
        # Clamp to valid range
        return max(1, min(10, overall))
    
    def _create_default_assessment(self) -> Dict[str, Any]:
        """Create default assessment response (mid-range).
        
        Returns:
            Default assessment data
        """
        return {
            "theme_adherence_score": 5,
            "age_appropriateness_score": 5,
            "moral_clarity_score": 5,
            "narrative_coherence_score": 5,
            "character_consistency_score": 5,
            "engagement_score": 5,
            "language_quality_score": 5,
            "overall_score": 5,
            "feedback": "Unable to parse quality assessment response, using default scores",
            "improvement_suggestions": ["Re-assessment may be needed"]
        }

    def _heuristic_theme_score(self, story_content: str, theme: Optional[str], language: str) -> Optional[int]:
        """Return a conservative theme score using keyword coverage, or None if theme is unknown."""
        if not theme or not theme.strip():
            return None

        lang = "ru" if str(language).lower().startswith("ru") else "en"
        theme_key = theme.lower().strip()
        keywords = self.THEME_KEYWORDS.get(lang, {}).get(theme_key)
        if not keywords:
            return None

        text = story_content.lower()
        hits = 0
        for kw in keywords:
            if kw in text:
                hits += 1

        if hits == 0:
            return 1
        if hits == 1:
            return 3
        if hits == 2:
            return 5
        if hits == 3:
            return 7
        return 9
