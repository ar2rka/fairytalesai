"""LangGraph workflow nodes for story generation."""

import time
import logging
from typing import Dict, Any

from src.domain.services.langgraph.workflow_state import (
    WorkflowState,
    WorkflowStatus,
    GenerationAttempt,
    QualityAssessment,
    ValidationResult
)
from src.domain.services.langgraph.prompt_validator import PromptValidatorService
from src.domain.services.langgraph.quality_assessor import QualityAssessorService
from src.domain.services.prompt_service import PromptService
from src.domain.entities import Child, Hero
from src.domain.value_objects import Language, Gender, StoryLength
from src.infrastructure.persistence.models import GenerationDB
from src.core.logging import get_logger
from src.openrouter_client import OpenRouterModel
from datetime import datetime

logger = get_logger("langgraph.workflow_nodes")


async def validate_prompt_node(
    state: WorkflowState,
    validator_service: PromptValidatorService,
    config: Dict[str, Any]
) -> WorkflowState:
    """Validate the story prompt for safety and appropriateness.
    
    Args:
        state: Current workflow state
        validator_service: Prompt validator service instance
        config: Configuration dict with validation_model
        
    Returns:
        Updated workflow state with validation results
    """
    logger.info("="*80)
    logger.info("Node: VALIDATE_PROMPT - Starting validation")
    logger.info(f"Child: name='{state['child_name']}', age_category={state.get('child_age_category', 'N/A')}, interests={state['child_interests']}")
    if state['child_name'] == "Child" and state.get('child_age_category') == "3-5":
        logger.warning(f"⚠️ Using default values in state! child_name='{state['child_name']}', child_age_category={state.get('child_age_category')} - this might indicate missing data")
    logger.info(f"Story Type: {state['story_type']}, Language: {state['language']}, Length: {state['story_length']} min")
    logger.info(f"Validation Model: {config.get('validation_model', 'openai/gpt-4o-mini')}")
    logger.info(f"Prompt length: {len(state['original_prompt'])} chars")
    start_time = time.time()
    
    state["workflow_status"] = WorkflowStatus.VALIDATING.value
    
    try:
        # Run validation
        validation_result = await validator_service.validate_prompt(
            prompt=state["original_prompt"],
            child_name=state["child_name"],
            child_age_category=state.get("child_age_category", "3-5"),  # Default for backward compatibility
            child_interests=state["child_interests"],
            model=config.get("validation_model", "openai/gpt-4o-mini")
        )
        
        # Store validation result
        state["validation_result"] = validation_result.to_dict()
        state["validation_duration"] = time.time() - start_time
        
        logger.info(f"Validation completed in {state['validation_duration']:.2f}s")
        logger.info(f"Recommendation: {validation_result.recommendation}")
        logger.info(f"Is Safe: {validation_result.is_safe}")
        logger.info(f"Age Appropriate: {validation_result.is_age_appropriate}")
        logger.info(f"Has Licensed Characters: {validation_result.has_licensed_characters}")
        logger.info(f"Reasoning: {validation_result.reasoning}")
        
        if validation_result.recommendation == "rejected":
            state["workflow_status"] = WorkflowStatus.REJECTED.value
            
            # Build detailed rejection message
            rejection_details = []
            if not validation_result.is_safe:
                rejection_details.append("Safety concerns")
            if validation_result.has_licensed_characters:
                rejection_details.append("Licensed characters detected")
            if not validation_result.is_age_appropriate:
                rejection_details.append("Age appropriateness concerns")
            if validation_result.detected_issues:
                rejection_details.append(f"Issues: {', '.join(validation_result.detected_issues[:3])}")
            
            rejection_message = validation_result.reasoning or "; ".join(rejection_details) or "Validation failed"
            state["error_messages"].append(f"Prompt validation failed: {rejection_message}")
            logger.warning(f"❌ Prompt REJECTED: {rejection_message}")
            logger.warning(f"   Details - is_safe: {validation_result.is_safe}, "
                         f"has_licensed: {validation_result.has_licensed_characters}, "
                         f"is_age_appropriate: {validation_result.is_age_appropriate}")
            
            # Update generation record in Supabase
            supabase_client = config.get("supabase_client")
            if supabase_client and state.get("generation_id"):
                try:
                    generation_update = GenerationDB(
                        generation_id=state["generation_id"],
                        attempt_number=1,
                        model_used=config.get("validation_model", "unknown"),
                        full_response=None,
                        status="failed",
                        prompt=state["original_prompt"],
                        user_id=state["user_id"],
                        story_type=state["story_type"],
                        story_length=state["story_length"],
                        hero_appearance=state.get("hero_description"),
                        relationship_description=None,
                        moral=state["moral"],
                        error_message=f"Validation rejected: {validation_result.reasoning}",
                        completed_at=datetime.now()
                    )
                    await supabase_client.update_generation(generation_update)
                    logger.info("✅ Updated generation record with validation rejection")
                except Exception as db_error:
                    logger.warning(f"⚠️ Failed to update generation record: {str(db_error)}")
        else:
            logger.info(f"✅ Prompt validation PASSED")
            
            # Update generation record with validation success
            supabase_client = config.get("supabase_client")
            if supabase_client and state.get("generation_id"):
                try:
                    generation_update = GenerationDB(
                        generation_id=state["generation_id"],
                        attempt_number=1,
                        model_used=config.get("validation_model", "unknown"),
                        full_response={"validation_result": validation_result.to_dict()},
                        status="pending",  # Still pending, generation hasn't started
                        prompt=state["original_prompt"],
                        user_id=state["user_id"],
                        story_type=state["story_type"],
                        story_length=state["story_length"],
                        hero_appearance=state.get("hero_description"),
                        relationship_description=None,
                        moral=state["moral"],
                        error_message=None
                    )
                    await supabase_client.update_generation(generation_update)
                    logger.info("✅ Updated generation record with validation success")
                except Exception as db_error:
                    logger.warning(f"⚠️ Failed to update generation record: {str(db_error)}")
        
    except Exception as e:
        logger.error(f"❌ Validation node error: {str(e)}", exc_info=True)
        state["validation_error"] = str(e)
        state["workflow_status"] = WorkflowStatus.REJECTED.value
        state["error_messages"].append(f"Validation error: {str(e)}")
        
        # Update generation record with error
        supabase_client = config.get("supabase_client")
        if supabase_client and state.get("generation_id"):
            try:
                generation_update = GenerationDB(
                    generation_id=state["generation_id"],
                    attempt_number=1,
                    model_used=config.get("validation_model", "unknown"),
                    full_response=None,
                    status="failed",
                    prompt=state["original_prompt"],
                    user_id=state["user_id"],
                    story_type=state["story_type"],
                    story_length=state["story_length"],
                    hero_appearance=state.get("hero_description"),
                    relationship_description=None,
                    moral=state["moral"],
                    error_message=f"Validation error: {str(e)}",
                    completed_at=datetime.now()
                )
                await supabase_client.update_generation(generation_update)
            except Exception as db_error:
                logger.warning(f"⚠️ Failed to update generation record: {str(db_error)}")
    
    logger.info("="*80)
    return state


async def generate_story_node(
    state: WorkflowState,
    prompt_service: PromptService,
    openrouter_client,
    config: Dict[str, Any]
) -> WorkflowState:
    """Generate story content using LLM.
    
    Args:
        state: Current workflow state
        prompt_service: Prompt service instance
        openrouter_client: OpenRouter client for LLM calls
        config: Configuration dict with generation settings
        
    Returns:
        Updated workflow state with generation attempt
    """
    logger.info("="*80)
    logger.info("Node: GENERATE_STORY - Starting generation")
    start_time = time.time()
    
    state["workflow_status"] = WorkflowStatus.GENERATING.value
    
    # Increment attempt counter
    current_attempt = state.get("current_attempt", 0)
    max_attempts = config.get("max_attempts", 3)
    state["current_attempt"] = current_attempt + 1
    attempt_number = state["current_attempt"]
    
    logger.info(f"📝 Generation attempt {attempt_number}/{max_attempts}")
    
    # Safety check: if we somehow reached this node beyond max attempts, log warning
    if attempt_number > max_attempts:
        logger.warning(f"⚠️ Attempt {attempt_number} exceeds max ({max_attempts}), but proceeding anyway")
    logger.info(f"Story Type: {state['story_type']}")
    logger.info(f"Child: {state['child_name']}, Age Category: {state.get('child_age_category', 'N/A')}")
    logger.info(f"Language: {state['language']}, Moral: {state['moral']}")
    logger.info(f"Expected word count: {state.get('expected_word_count', 'N/A')}")
    
    try:
        # Create child entity for prompt generation
        child = Child(
            name=state["child_name"],
            age_category=state.get("child_age_category", "3-5"),  # Default for backward compatibility
            gender=Gender(state["child_gender"]),
            interests=state["child_interests"]
        )
        
        # Create hero entity if needed
        hero = None
        if state["story_type"] in ["hero", "combined"] and state.get("hero_id"):
            hero = Hero(
                id=state["hero_id"],
                name=state["hero_name"],
                description=state.get("hero_description", "")
            )
        
        # Build prompt based on story type
        # Safely convert language - it might already be a Language enum or a string
        language_str = state["language"]
        if isinstance(language_str, Language):
            language = language_str
        elif isinstance(language_str, str):
            language = Language(language_str)
        else:
            # Fallback
            language = Language.ENGLISH
        
        story_length = StoryLength(minutes=state["story_length"])
        moral = state["moral"]
        
        # Get previous quality feedback if this is a retry
        previous_feedback = None
        if attempt_number > 1 and state.get("quality_assessments"):
            last_assessment = state["quality_assessments"][-1]
            if isinstance(last_assessment, dict):
                # Safely extract values, ensuring they are the right types
                suggestions = last_assessment.get("improvement_suggestions", [])
                # Ensure suggestions are strings, not objects
                if suggestions:
                    suggestions = [str(s) for s in suggestions if s]
                
                previous_feedback = {
                    "score": last_assessment.get("overall_score", 0),
                    "feedback": str(last_assessment.get("feedback", "")),
                    "suggestions": suggestions
                }
        
        # Generate prompt with feedback if available
        if state["story_type"] == "child":
            prompt = prompt_service.generate_child_prompt(child, moral, language, story_length)
        elif state["story_type"] == "hero":
            prompt = prompt_service.generate_hero_prompt(hero, moral, language, story_length)
        else:  # combined
            prompt = prompt_service.generate_combined_prompt(child, hero, moral, language, story_length)
        
        # Add feedback for regeneration attempts
        if previous_feedback:
            feedback_text = f"\n\nPrevious Attempt Feedback:\n"
            feedback_text += f"The previous story scored {previous_feedback['score']}/10.\n"
            feedback_text += f"Issues identified: {previous_feedback['feedback']}\n"
            # Safely convert suggestions to strings
            suggestions = previous_feedback.get('suggestions', [])
            if suggestions:
                suggestions_str = ', '.join(str(s) for s in suggestions)
                feedback_text += f"Please address these points: {suggestions_str}\n"
            prompt += feedback_text
        
        # Store prompt in state for database tracking
        state["current_prompt"] = prompt
        
        # Determine temperature based on attempt number
        temp_config = {
            1: config.get("first_attempt_temperature", 0.7),
            2: config.get("second_attempt_temperature", 0.8),
            3: config.get("third_attempt_temperature", 0.6)
        }
        temperature = temp_config.get(attempt_number, 0.7)
        
        logger.info(f"🌡️ Temperature: {temperature}")
        
        # Determine model to use
        model = config.get("generation_model")
        if model:
            model = OpenRouterModel(model)
            logger.info(f"🤖 Model: {model.value}")
        else:
            logger.info("🤖 Model: default")
            model = None  # Use default
        
        # Log if this is a regeneration with feedback
        if previous_feedback:
            logger.info(f"🔁 Regeneration with feedback: previous score was {previous_feedback['score']}/10")
            logger.info(f"Feedback: {previous_feedback['feedback'][:100]}...")
        
        # Generate story
        logger.info("🚀 Calling OpenRouter API...")
        # Use direct API call, NOT LangGraph workflow (we're already inside a workflow!)
        result = await openrouter_client.generate_story(
            prompt,
            model=model,
            temperature=temperature,
            max_retries=3,
            use_langgraph=False  # CRITICAL: Don't create nested workflow!
        )
        
        # Extract title
        lines = result.content.strip().split('\n')
        title = lines[0].replace('#', '').strip() if lines else "A Bedtime Story"
        
        # Safely extract model value (handle both enum and string)
        model_used_str = "unknown"
        if result.model:
            if hasattr(result.model, 'value'):
                model_used_str = result.model.value
            else:
                model_used_str = str(result.model)
        
        # Create generation attempt
        generation_attempt = GenerationAttempt(
            attempt_number=attempt_number,
            content=result.content,
            title=title,
            model_used=model_used_str,
            temperature=temperature,
            tokens_used=0,  # TODO: Extract from result if available
            generation_time=time.time() - start_time
        )
        
        # Store attempt
        state["generation_attempts"].append(generation_attempt.to_dict())
        state["current_generation"] = generation_attempt.to_dict()
        state["generation_duration"] = time.time() - start_time
        
        logger.info(f"✅ Story generated successfully in {state['generation_duration']:.2f}s")
        logger.info(f"📚 Title: {title}")
        logger.info(f"📝 Content length: {len(result.content)} chars, ~{len(result.content.split())} words")
        logger.info(f"🤖 Model used: {model_used_str}")
        logger.info(f"🌡️ Temperature: {temperature}")
        
        # Update generation record in Supabase for this attempt
        supabase_client = config.get("supabase_client")
        if supabase_client and state.get("generation_id"):
            try:
                # Use the generated prompt (may include feedback for retries)
                prompt_for_db = prompt
                
                generation_update = GenerationDB(
                    generation_id=state["generation_id"],
                    attempt_number=attempt_number,
                    model_used=model_used_str,
                    full_response=result.full_response if hasattr(result, 'full_response') else None,
                    status="success",
                    prompt=prompt_for_db,
                    user_id=state["user_id"],
                    story_type=state["story_type"],
                    story_length=state["story_length"],
                    hero_appearance=state.get("hero_description"),
                    relationship_description=None,
                    moral=state["moral"],
                    error_message=None,
                    completed_at=datetime.now()
                )
                await supabase_client.update_generation(generation_update)
                logger.info(f"✅ Updated generation record for attempt {attempt_number}")
            except Exception as db_error:
                logger.warning(f"⚠️ Failed to update generation record: {str(db_error)}")
        
    except Exception as e:
        logger.error(f"❌ Generation node error: {str(e)}", exc_info=True)
        state["generation_error"] = str(e)
        state["workflow_status"] = WorkflowStatus.FAILED.value
        state["error_messages"].append(f"Generation error: {str(e)}")
        
        # Store failed attempt
        failed_attempt = GenerationAttempt(
            attempt_number=attempt_number,
            content="",
            title="",
            error=str(e),
            generation_time=time.time() - start_time
        )
        state["generation_attempts"].append(failed_attempt.to_dict())
        
        # Update generation record in Supabase with failure
        supabase_client = config.get("supabase_client")
        if supabase_client and state.get("generation_id"):
            try:
                # Try to get the prompt that was used (stored in state or fallback to original)
                prompt_for_db = state.get("current_prompt") or state.get("original_prompt", "")
                
                # Safely extract model value
                model_used_str = "unknown"
                if model:
                    if hasattr(model, 'value'):
                        model_used_str = model.value
                    else:
                        model_used_str = str(model)
                
                generation_update = GenerationDB(
                    generation_id=state["generation_id"],
                    attempt_number=attempt_number,
                    model_used=model_used_str,
                    full_response=None,
                    status="failed",
                    prompt=prompt_for_db,
                    user_id=state["user_id"],
                    story_type=state["story_type"],
                    story_length=state["story_length"],
                    hero_appearance=state.get("hero_description"),
                    relationship_description=None,
                    moral=state["moral"],
                    error_message=str(e),
                    completed_at=datetime.now()
                )
                await supabase_client.update_generation(generation_update)
                logger.info(f"✅ Updated generation record with failure for attempt {attempt_number}")
            except Exception as db_error:
                logger.warning(f"⚠️ Failed to update generation record: {str(db_error)}")
    
    logger.info("="*80)
    return state


async def assess_quality_node(
    state: WorkflowState,
    quality_assessor: QualityAssessorService,
    config: Dict[str, Any]
) -> WorkflowState:
    """Assess the quality of generated story.
    
    Args:
        state: Current workflow state
        quality_assessor: Quality assessor service instance
        config: Configuration dict with assessment settings
        
    Returns:
        Updated workflow state with quality assessment
    """
    logger.info("="*80)
    logger.info("Node: ASSESS_QUALITY - Assessing story quality")
    logger.info(f"Assessment Model: {config.get('assessment_model', 'openai/gpt-4o-mini')}")
    logger.info(f"Quality Threshold: {config.get('quality_threshold', 7)}/10")
    start_time = time.time()
    
    state["workflow_status"] = WorkflowStatus.ASSESSING.value
    
    try:
        # Get current generation
        current_gen = state.get("current_generation")
        if not current_gen or not current_gen.get("content"):
            raise ValueError("No story content to assess")
        
        # Assess quality
        quality_assessment = await quality_assessor.assess_quality(
            story_content=current_gen["content"],
            title=current_gen["title"],
            child_age_category=state.get("child_age_category", "3-5"),  # Default for backward compatibility
            moral=state["moral"],
            language=state["language"],
            expected_word_count=state["expected_word_count"],
            model=config.get("assessment_model", "openai/gpt-4o-mini")
        )
        
        # Store assessment
        assessment_dict = quality_assessment.to_dict()
        state["quality_assessments"].append(assessment_dict)
        state["current_assessment"] = assessment_dict
        state["assessment_duration"] = time.time() - start_time
        
        # Update current generation with quality score
        if state["generation_attempts"]:
            state["generation_attempts"][-1]["quality_assessment"] = assessment_dict
        
        # Track all scores
        if "all_scores" not in state:
            state["all_scores"] = []
        state["all_scores"].append(quality_assessment.overall_score)
        
        logger.info(f"✅ Quality assessment complete in {state['assessment_duration']:.2f}s")
        logger.info(f"🎯 Overall Score: {quality_assessment.overall_score}/10")
        
        # Update generation record in Supabase with quality assessment
        supabase_client = config.get("supabase_client")
        if supabase_client and state.get("generation_id") and state.get("current_attempt"):
            try:
                attempt_number = state["current_attempt"]
                current_gen = state.get("current_generation", {})
                existing_response = current_gen.get("full_response") if isinstance(current_gen.get("full_response"), dict) else {}
                
                generation_update = GenerationDB(
                    generation_id=state["generation_id"],
                    attempt_number=attempt_number,
                    model_used=current_gen.get("model_used", "unknown"),
                    full_response={
                        **existing_response,
                        "quality_assessment": assessment_dict
                    },
                    status="success",  # Generation succeeded, quality assessed
                    prompt=state.get("original_prompt", ""),
                    user_id=state["user_id"],
                    story_type=state["story_type"],
                    story_length=state["story_length"],
                    hero_appearance=state.get("hero_description"),
                    relationship_description=None,
                    moral=state["moral"],
                    error_message=None
                )
                await supabase_client.update_generation(generation_update)
                logger.info(f"✅ Updated generation record with quality assessment for attempt {attempt_number}")
            except Exception as db_error:
                logger.warning(f"⚠️ Failed to update generation record with quality: {str(db_error)}")
        logger.info(f"")
        logger.info(f"📊 Detailed Scores:")
        logger.info(f"  👶 Age Appropriateness: {quality_assessment.age_appropriateness_score}/10")
        logger.info(f"  🎓 Moral Clarity: {quality_assessment.moral_clarity_score}/10")
        logger.info(f"  📖 Narrative Coherence: {quality_assessment.narrative_coherence_score}/10")
        logger.info(f"  🎭 Character Consistency: {quality_assessment.character_consistency_score}/10")
        logger.info(f"  🎨 Engagement: {quality_assessment.engagement_score}/10")
        logger.info(f"  💬 Language Quality: {quality_assessment.language_quality_score}/10")
        logger.info(f"")
        logger.info(f"💡 Assessment Feedback:")
        feedback_lines = quality_assessment.feedback.split('\n')
        for line in feedback_lines[:5]:  # Show first 5 lines
            if line.strip():
                logger.info(f"  {line.strip()}")
        if len(feedback_lines) > 5:
            logger.info(f"  ... ({len(feedback_lines) - 5} more lines)")
        
        if quality_assessment.improvement_suggestions:
            logger.info(f"")
            logger.info(f"🔧 Improvement Suggestions:")
            for i, suggestion in enumerate(quality_assessment.improvement_suggestions[:3], 1):
                logger.info(f"  {i}. {suggestion}")
            if len(quality_assessment.improvement_suggestions) > 3:
                logger.info(f"  ... (+{len(quality_assessment.improvement_suggestions) - 3} more)")
        
        logger.info(f"")
        if quality_assessment.overall_score >= config.get('quality_threshold', 7):
            logger.info(f"✅ Quality threshold MET ({quality_assessment.overall_score} >= {config.get('quality_threshold', 7)})")
        else:
            logger.info(f"⚠️ Quality threshold NOT met ({quality_assessment.overall_score} < {config.get('quality_threshold', 7)})")
        
    except Exception as e:
        logger.error(f"❌ Assessment node error: {str(e)}", exc_info=True)
        state["assessment_error"] = str(e)
        state["error_messages"].append(f"Assessment error: {str(e)}")
        
        # Use default score of 5 on error
        if "all_scores" not in state:
            state["all_scores"] = []
        state["all_scores"].append(5)
        logger.warning("⚠️ Using default score of 5/10 due to assessment error")
    
    logger.info("="*80)
    return state


async def select_best_story_node(
    state: WorkflowState,
    config: Dict[str, Any]
) -> WorkflowState:
    """Select the best story from all generation attempts.
    
    Args:
        state: Current workflow state
        config: Configuration dict
        
    Returns:
        Updated workflow state with best story selected
    """
    logger.info("="*80)
    logger.info("Node: SELECT_BEST_STORY - Selecting best story")
    
    try:
        generation_attempts = state.get("generation_attempts", [])
        
        if not generation_attempts:
            raise ValueError("No generation attempts to select from")
        
        logger.info(f"Evaluating {len(generation_attempts)} generation attempts")
        
        # Find attempt with highest quality score
        best_attempt = None
        best_score = 0
        best_attempt_number = 0
        
        for i, attempt in enumerate(generation_attempts, 1):
            quality_assessment = attempt.get("quality_assessment")
            if quality_assessment:
                score = quality_assessment.get("overall_score", 0)
                logger.info(f"  Attempt {i}: Score {score}/10")
                # Prefer later attempts if scores are equal (shows improvement)
                if score >= best_score:
                    best_score = score
                    best_attempt = attempt
                    best_attempt_number = attempt.get("attempt_number", 0)
            else:
                logger.info(f"  Attempt {i}: No quality assessment")
        
        if not best_attempt:
            # No quality assessments, use first non-error attempt
            logger.warning("No quality assessments found, using first valid attempt")
            for attempt in generation_attempts:
                if attempt.get("content") and not attempt.get("error"):
                    best_attempt = attempt
                    best_attempt_number = attempt.get("attempt_number", 0)
                    break
        
        if not best_attempt:
            raise ValueError("No valid stories generated")
        
        # Store selection
        state["best_story"] = best_attempt
        state["selected_attempt_number"] = best_attempt_number
        state["selection_reason"] = f"Selected attempt {best_attempt_number} with score {best_score}/10"
        state["workflow_status"] = WorkflowStatus.SUCCESS.value
        
        # Calculate total duration
        state["total_duration"] = time.time() - state.get("start_time", time.time())
        
        logger.info(f"✅ Best story selected: Attempt {best_attempt_number}")
        logger.info(f"🎯 Final Score: {best_score}/10")
        logger.info(f"⏱️ Total Workflow Duration: {state['total_duration']:.2f}s")
        logger.info(f"All scores: {state.get('all_scores', [])}")
        
        # Update final generation record in Supabase with selection
        supabase_client = config.get("supabase_client")
        if supabase_client and state.get("generation_id") and best_attempt_number:
            try:
                best_attempt_data = best_attempt or {}
                existing_response = best_attempt_data.get("full_response") if isinstance(best_attempt_data.get("full_response"), dict) else {}
                
                generation_update = GenerationDB(
                    generation_id=state["generation_id"],
                    attempt_number=best_attempt_number,
                    model_used=best_attempt_data.get("model_used", "unknown"),
                    full_response={
                        **existing_response,
                        "selected": True,
                        "selection_reason": state.get("selection_reason"),
                        "final_score": best_score,
                        "total_attempts": len(state.get("generation_attempts", [])),
                        "workflow_metadata": {
                            "total_duration": state.get("total_duration"),
                            "validation_duration": state.get("validation_duration"),
                            "generation_duration": state.get("generation_duration"),
                            "assessment_duration": state.get("assessment_duration"),
                        }
                    },
                    status="success",
                    prompt=state.get("original_prompt", ""),
                    user_id=state["user_id"],
                    story_type=state["story_type"],
                    story_length=state["story_length"],
                    hero_appearance=state.get("hero_description"),
                    relationship_description=None,
                    moral=state["moral"],
                    error_message=None,
                    completed_at=datetime.now()
                )
                await supabase_client.update_generation(generation_update)
                logger.info(f"✅ Updated final generation record with selection: attempt {best_attempt_number}")
            except Exception as db_error:
                logger.warning(f"⚠️ Failed to update final generation record: {str(db_error)}")
        
    except Exception as e:
        logger.error(f"❌ Selection node error: {str(e)}", exc_info=True)
        state["workflow_status"] = WorkflowStatus.FAILED.value
        state["fatal_error"] = str(e)
        state["error_messages"].append(f"Selection error: {str(e)}")
    
    logger.info("="*80)
    return state


def should_regenerate(state: WorkflowState, config: Dict[str, Any]) -> bool:
    """Determine if story should be regenerated.
    
    Args:
        state: Current workflow state
        config: Configuration with quality_threshold and max_attempts
        
    Returns:
        True if should regenerate, False otherwise
    """
    logger.info("="*80)
    logger.info("🤔 DECISION: Should regenerate?")
    
    # Check if max attempts reached FIRST - this is critical to prevent infinite loops
    max_attempts = config.get("max_attempts", 3)
    current_attempt = state.get("current_attempt", 0)
    
    logger.info(f"Current attempt: {current_attempt}/{max_attempts}")
    
    # IMPORTANT: Check max attempts BEFORE checking quality to prevent infinite loops
    if current_attempt >= max_attempts:
        logger.info(f"❌ Max attempts ({max_attempts}) reached, selecting best story")
        logger.info("Decision: NO - proceed to selection")
        logger.info("="*80)
        return False
    
    # Check number of generation attempts already made
    generation_attempts = state.get("generation_attempts", [])
    num_attempts_made = len(generation_attempts)
    
    logger.info(f"Generation attempts made: {num_attempts_made}/{max_attempts}")
    
    # Safety check: prevent infinite loop if we've already made max attempts
    if num_attempts_made >= max_attempts:
        logger.warning(f"⚠️ Already made {num_attempts_made} attempts (max: {max_attempts}), forcing selection")
        logger.info("Decision: NO - max attempts already made")
        logger.info("="*80)
        return False
    
    # Check if current quality meets threshold
    quality_threshold = config.get("quality_threshold", 7)
    current_assessment = state.get("current_assessment")
    
    if not current_assessment:
        # If no assessment but we haven't reached max attempts, allow one more regeneration
        # But check attempts count first to prevent infinite loop
        if num_attempts_made < max_attempts:
            logger.warning("⚠️ No quality assessment available, will regenerate (one more attempt)")
            logger.info("Decision: YES - regenerate (no assessment)")
            logger.info("="*80)
            return True
        else:
            logger.warning("⚠️ No quality assessment but max attempts reached, selecting best")
            logger.info("Decision: NO - max attempts reached")
            logger.info("="*80)
            return False
    
    current_score = current_assessment.get("overall_score", 0)
    
    logger.info(f"Current score: {current_score}/10")
    logger.info(f"Quality threshold: {quality_threshold}/10")
    
    if current_score >= quality_threshold:
        logger.info(f"✅ Quality threshold met ({current_score} >= {quality_threshold}), selecting story")
        logger.info("Decision: NO - quality is good enough")
        logger.info("="*80)
        return False
    
    # Quality below threshold, but check if we can still regenerate
    if num_attempts_made < max_attempts:
        logger.info(f"🔁 Quality below threshold ({current_score} < {quality_threshold}), will regenerate")
        logger.info("Decision: YES - try to improve quality")
        logger.info("="*80)
        return True
    else:
        logger.info(f"🔁 Quality below threshold ({current_score} < {quality_threshold}) but max attempts reached")
        logger.info("Decision: NO - max attempts reached, selecting best")
        logger.info("="*80)
        return False
