"""LangGraph workflow service for orchestrating story generation."""

import logging
from typing import Optional, List, Dict, Any
from datetime import datetime

from src.domain.entities import Child, Hero, Story
from src.domain.value_objects import Language, StoryLength
from src.domain.services.langgraph.story_generation_workflow import create_workflow
from src.domain.services.langgraph.workflow_state import (
    create_initial_state,
    WorkflowStatus
)
from src.infrastructure.config.settings import get_settings
from src.infrastructure.persistence.models import GenerationDB
from src.core.logging import get_logger
from src.core.constants import READING_SPEED_WPM
import uuid

logger = get_logger("langgraph.workflow_service")


class LangGraphWorkflowResult:
    """Result from LangGraph workflow execution."""
    
    def __init__(
        self,
        success: bool,
        story_content: Optional[str] = None,
        story_title: Optional[str] = None,
        prompt: Optional[str] = None,
        quality_score: Optional[int] = None,
        attempts_count: int = 0,
        selected_attempt_number: Optional[int] = None,
        quality_metadata: Optional[Dict[str, Any]] = None,
        validation_result: Optional[Dict[str, Any]] = None,
        workflow_metadata: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None,
        all_attempts: Optional[List[Dict[str, Any]]] = None
    ):
        """Initialize workflow result.
        
        Args:
            success: Whether workflow succeeded
            story_content: Generated story content
            story_title: Story title
            prompt: Prompt used for story generation
            quality_score: Overall quality score (1-10)
            attempts_count: Number of generation attempts
            selected_attempt_number: Which attempt was selected
            quality_metadata: Detailed quality assessment data
            validation_result: Prompt validation outcome
            workflow_metadata: Workflow execution metadata
            error_message: Error message if failed
            all_attempts: All generation attempts
        """
        self.success = success
        self.story_content = story_content
        self.story_title = story_title
        self.prompt = prompt
        self.quality_score = quality_score
        self.attempts_count = attempts_count
        self.selected_attempt_number = selected_attempt_number
        self.quality_metadata = quality_metadata
        self.validation_result = validation_result
        self.workflow_metadata = workflow_metadata
        self.error_message = error_message
        self.all_attempts = all_attempts or []


class LangGraphWorkflowService:
    """Service for executing LangGraph story generation workflow."""
    
    def __init__(
        self,
        openrouter_client,
        prompt_service,
        child_repository,
        hero_repository,
        supabase_client=None
    ):
        """Initialize workflow service.
        
        Args:
            openrouter_client: AsyncOpenRouterClient instance
            prompt_service: PromptService instance
            child_repository: ChildRepository instance
            hero_repository: HeroRepository instance
            supabase_client: Optional AsyncSupabaseClient for tracking generations
        """
        self.openrouter_client = openrouter_client
        self.prompt_service = prompt_service
        self.child_repository = child_repository
        self.hero_repository = hero_repository
        self.supabase_client = supabase_client
        
        # Load settings
        settings = get_settings()
        self.workflow_settings = settings.langgraph_workflow
        
        logger.info("LangGraph workflow service initialized")
    
    async def execute_workflow(
        self,
        child: Child,
        moral: str,
        language: Language,
        story_length: StoryLength,
        story_type: str = "child",
        hero: Optional[Hero] = None,
        user_id: str = "",
        theme: Optional[str] = None
    ) -> LangGraphWorkflowResult:
        """Execute LangGraph workflow for story generation.
        
        Args:
            child: Child entity
            moral: Moral value to teach
            language: Story language
            story_length: Story length
            story_type: Type of story (child/hero/combined)
            hero: Optional hero entity
            user_id: User ID for tracking
            theme: Optional story theme (e.g. adventure, space)
            
        Returns:
            LangGraphWorkflowResult with generated story or error
        """
        logger.info("🌟 " + "="*78 + " 🌟")
        logger.info("🚀 LANGGRAPH WORKFLOW STARTED")
        logger.info("="*80)
        logger.info(f"👶 Child: {child.name}, Age Category: {child.age_category}, Gender: {child.gender.value}")
        logger.info(f"🎯 Moral: {moral}")
        logger.info(f"🌍 Language: {language.value}")
        logger.info(f"⏱️ Story Length: {story_length.minutes} minutes")
        logger.info(f"📖 Story Type: {story_type}")
        if hero:
            logger.info(f"🦸 Hero: {hero.name}")
        logger.info(f"👤 User ID: {user_id}")
        logger.info("="*80)
        logger.info("⚙️ Workflow Configuration:")
        logger.info(f"  Quality Threshold: {self.workflow_settings.quality_threshold}/10")
        logger.info(f"  Max Attempts: {self.workflow_settings.max_generation_attempts}")
        logger.info(f"  Validation Model: {self.workflow_settings.validation_model}")
        logger.info(f"  Assessment Model: {self.workflow_settings.assessment_model}")
        logger.info(f"  Generation Model: {self.workflow_settings.generation_model or 'default'}")
        logger.info(f"  Temperatures: [{self.workflow_settings.first_attempt_temperature}, {self.workflow_settings.second_attempt_temperature}, {self.workflow_settings.third_attempt_temperature}]")
        logger.info("="*80)
        
        try:
            # Generate initial prompt
            if story_type == "child":
                prompt = self.prompt_service.generate_child_prompt(
                    child, moral, language, story_length, theme=theme
                )
            elif story_type == "hero":
                prompt = self.prompt_service.generate_hero_prompt(
                    hero, moral, language, story_length, theme=theme
                )
            else:  # combined
                prompt = self.prompt_service.generate_combined_prompt(
                    child, hero, moral, language, story_length, theme=theme
                )
            
            # Calculate expected word count
            expected_word_count = story_length.minutes * READING_SPEED_WPM
            
            # Generate unique generation_id for tracking
            generation_id = str(uuid.uuid4())
            logger.info(f"📋 Generation ID: {generation_id}")
            
            # Create initial generation record in Supabase if client is available
            if self.supabase_client:
                try:
                    initial_generation = GenerationDB(
                        generation_id=generation_id,
                        attempt_number=1,
                        model_used="",  # Will be updated when generation starts
                        full_response=None,
                        status="pending",
                        prompt=prompt,
                        user_id=user_id,
                        story_type=story_type,
                        story_length=story_length.minutes,
                        hero_appearance=hero.appearance if hero else None,
                        relationship_description=None,
                        moral=moral,
                        error_message=None,
                        created_at=datetime.now()
                    )
                    await self.supabase_client.create_generation(initial_generation)
                    logger.info(f"✅ Created initial generation record in Supabase: {generation_id}")
                except Exception as e:
                    logger.warning(f"⚠️ Failed to create generation record in Supabase: {str(e)}")
            
            # Create initial workflow state
            logger.info(f"Creating initial state with child: name='{child.name}', age_category={child.age_category}, interests={child.interests}")
            if child.name == "Child" and child.age_category == "3-5":
                logger.warning(f"⚠️ Child entity has default values! name='{child.name}', age_category={child.age_category} - this might indicate missing data")
            
            initial_state = create_initial_state(
                original_prompt=prompt,
                child_id=str(child.id) if child.id else "",
                child_name=child.name,
                age_category=child.age_category,
                child_gender=child.gender.value,
                child_interests=child.interests or [],
                story_type=story_type,
                language=language.value,
                moral=moral,
                story_length=story_length.minutes,
                expected_word_count=expected_word_count,
                user_id=user_id,
                generation_id=generation_id,
                hero_id=str(hero.id) if hero and hero.id else None,
                hero_name=hero.name if hero else None,
                hero_description=hero.description if hero else None,
                theme=theme
            )
            
            # Create workflow
            workflow = create_workflow(
                openrouter_client=self.openrouter_client,
                prompt_service=self.prompt_service,
                quality_threshold=self.workflow_settings.quality_threshold,
                theme_threshold=max(7, self.workflow_settings.quality_threshold),
                max_generation_attempts=self.workflow_settings.max_generation_attempts,
                validation_model=self.workflow_settings.validation_model,
                assessment_model=self.workflow_settings.assessment_model,
                generation_model=self.workflow_settings.generation_model,
                first_attempt_temperature=self.workflow_settings.first_attempt_temperature,
                second_attempt_temperature=self.workflow_settings.second_attempt_temperature,
                third_attempt_temperature=self.workflow_settings.third_attempt_temperature,
                supabase_client=self.supabase_client
            )
            
            # Execute workflow
            logger.info("🔄 Executing workflow graph...")
            final_state = await workflow.execute(initial_state)
            
            # Process result
            logger.info("📦 Processing workflow result...")
            result = self._process_workflow_result(final_state)
            
            if result.success:
                logger.info("="*80)
                logger.info("✅ LANGGRAPH WORKFLOW COMPLETED SUCCESSFULLY")
                logger.info(f"🎯 Final Quality Score: {result.quality_score}/10")
                logger.info(f"📝 Story Title: {result.story_title}")
                logger.info(f"🔢 Attempts: {result.attempts_count}")
                logger.info(f"✅ Selected: Attempt {result.selected_attempt_number}")
                logger.info("="*80)
            else:
                logger.error("="*80)
                logger.error("❌ LANGGRAPH WORKFLOW FAILED")
                logger.error(f"Error: {result.error_message}")
                logger.error("="*80)
            
            return result
            
        except Exception as e:
            logger.error("="*80)
            logger.error("❌ LANGGRAPH WORKFLOW EXCEPTION")
            logger.error(f"Workflow execution failed: {str(e)}", exc_info=True)
            logger.error("="*80)
            return LangGraphWorkflowResult(
                success=False,
                error_message=f"Workflow execution failed: {str(e)}"
            )
    
    def _process_workflow_result(self, final_state: Dict[str, Any]) -> LangGraphWorkflowResult:
        """Process workflow final state into result object.
        
        Args:
            final_state: Final workflow state
            
        Returns:
            LangGraphWorkflowResult
        """
        workflow_status = final_state.get("workflow_status")
        
        # Check if workflow succeeded
        if workflow_status == WorkflowStatus.SUCCESS.value:
            best_story = final_state.get("best_story")
            
            if not best_story:
                logger.error("Workflow succeeded but no best story selected")
                return LangGraphWorkflowResult(
                    success=False,
                    error_message="No story selected despite successful workflow",
                    prompt=final_state.get("original_prompt")
                )
            
            # Extract quality assessment from best story
            quality_assessment = best_story.get("quality_assessment")
            quality_score = quality_assessment.get("overall_score") if quality_assessment else None
            
            # Build quality metadata
            quality_metadata = {
                "overall_score": quality_score,
                "all_scores": final_state.get("all_scores", []),
                "selected_attempt_number": final_state.get("selected_attempt_number"),
                "selection_reason": final_state.get("selection_reason"),
                "quality_assessments": final_state.get("quality_assessments", [])
            }
            
            # Build workflow metadata
            workflow_metadata = {
                "total_duration": final_state.get("total_duration"),
                "validation_duration": final_state.get("validation_duration"),
                "generation_duration": final_state.get("generation_duration"),
                "assessment_duration": final_state.get("assessment_duration"),
                "workflow_status": workflow_status
            }
            
            return LangGraphWorkflowResult(
                success=True,
                story_content=best_story.get("content", ""),
                story_title=best_story.get("title", ""),
                prompt=final_state.get("original_prompt"),
                quality_score=quality_score,
                attempts_count=final_state.get("current_attempt", 1),
                selected_attempt_number=final_state.get("selected_attempt_number"),
                quality_metadata=quality_metadata,
                validation_result=final_state.get("validation_result"),
                workflow_metadata=workflow_metadata,
                all_attempts=final_state.get("generation_attempts", [])
            )
        
        elif workflow_status == WorkflowStatus.REJECTED.value:
            # Prompt was rejected
            validation_result = final_state.get("validation_result", {})
            reasoning = validation_result.get("reasoning", "Prompt validation failed")
            
            return LangGraphWorkflowResult(
                success=False,
                error_message=f"Prompt rejected: {reasoning}",
                prompt=final_state.get("original_prompt"),
                validation_result=validation_result,
                workflow_metadata={
                    "workflow_status": workflow_status,
                    "validation_duration": final_state.get("validation_duration")
                }
            )
        
        else:
            # Workflow failed
            error_messages = final_state.get("error_messages", [])
            fatal_error = final_state.get("fatal_error")
            
            error_msg = fatal_error if fatal_error else "; ".join(error_messages) if error_messages else "Unknown workflow error"
            
            return LangGraphWorkflowResult(
                success=False,
                error_message=error_msg,
                prompt=final_state.get("original_prompt"),
                workflow_metadata={
                    "workflow_status": workflow_status,
                    "error_messages": error_messages
                }
            )
