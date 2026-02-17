"""LangGraph workflow for story generation with quality validation."""

import logging
from typing import Dict, Any, Literal
from langgraph.graph import StateGraph, END

from src.domain.services.langgraph.workflow_state import (
    WorkflowState,
    WorkflowStatus,
    create_initial_state
)
from src.domain.services.langgraph.workflow_nodes import (
    validate_prompt_node,
    generate_story_node,
    assess_quality_node,
    select_best_story_node,
    should_regenerate
)
from src.domain.services.langgraph.prompt_validator import PromptValidatorService
from src.domain.services.langgraph.quality_assessor import QualityAssessorService
from src.domain.services.prompt_service import PromptService
from src.core.logging import get_logger

logger = get_logger("langgraph.workflow")


class StoryGenerationWorkflow:
    """LangGraph-based story generation workflow with validation and quality assessment."""
    
    def __init__(
        self,
        openrouter_client,
        prompt_service: PromptService,
        config: Dict[str, Any]
    ):
        """Initialize workflow.
        
        Args:
            openrouter_client: AsyncOpenRouterClient instance
            prompt_service: PromptService instance
            config: Configuration dict with workflow settings
        """
        self.openrouter_client = openrouter_client
        self.prompt_service = prompt_service
        self.config = config
        
        # Initialize services
        self.validator_service = PromptValidatorService(openrouter_client)
        self.quality_assessor = QualityAssessorService(openrouter_client)
        
        # Build workflow graph
        self.graph = self._build_graph()
    
    def _build_graph(self) -> StateGraph:
        """Build LangGraph StateGraph for story generation workflow.
        
        Returns:
            Compiled StateGraph
        """
        logger.info("Building LangGraph workflow")
        
        # Create state graph
        workflow = StateGraph(WorkflowState)
        
        # Add nodes
        workflow.add_node("validate_prompt", self._validate_prompt_wrapper)
        workflow.add_node("generate_story", self._generate_story_wrapper)
        workflow.add_node("assess_quality", self._assess_quality_wrapper)
        workflow.add_node("select_best_story", self._select_best_story_wrapper)
        
        # Set entry point
        workflow.set_entry_point("validate_prompt")
        
        # Add conditional edges from validation
        workflow.add_conditional_edges(
            "validate_prompt",
            self._route_after_validation,
            {
                "approved": "generate_story",
                "rejected": END
            }
        )
        
        # Linear edge from generation to assessment
        workflow.add_edge("generate_story", "assess_quality")
        
        # Conditional edges from assessment
        workflow.add_conditional_edges(
            "assess_quality",
            self._route_after_assessment,
            {
                "regenerate": "generate_story",
                "select": "select_best_story"
            }
        )
        
        # End after selection
        workflow.add_edge("select_best_story", END)
        
        # Compile graph
        compiled_graph = workflow.compile()
        logger.info("LangGraph workflow compiled successfully")
        
        return compiled_graph
    
    async def _validate_prompt_wrapper(self, state: WorkflowState) -> WorkflowState:
        """Wrapper for validate_prompt_node with service injection.
        
        Args:
            state: Current workflow state
            
        Returns:
            Updated state
        """
        return await validate_prompt_node(
            state,
            self.validator_service,
            self.config
        )
    
    async def _generate_story_wrapper(self, state: WorkflowState) -> WorkflowState:
        """Wrapper for generate_story_node with service injection.
        
        Args:
            state: Current workflow state
            
        Returns:
            Updated state
        """
        return await generate_story_node(
            state,
            self.prompt_service,
            self.openrouter_client,
            self.config
        )
    
    async def _assess_quality_wrapper(self, state: WorkflowState) -> WorkflowState:
        """Wrapper for assess_quality_node with service injection.
        
        Args:
            state: Current workflow state
            
        Returns:
            Updated state
        """
        return await assess_quality_node(
            state,
            self.quality_assessor,
            self.config
        )
    
    async def _select_best_story_wrapper(self, state: WorkflowState) -> WorkflowState:
        """Wrapper for select_best_story_node with service injection.
        
        Args:
            state: Current workflow state
            
        Returns:
            Updated state
        """
        return await select_best_story_node(state, self.config)
    
    def _route_after_validation(
        self,
        state: WorkflowState
    ) -> Literal["approved", "rejected"]:
        """Route workflow after validation.
        
        Args:
            state: Current workflow state
            
        Returns:
            Next step: "approved" or "rejected"
        """
        validation_result = state.get("validation_result")
        
        if not validation_result:
            logger.warning("No validation result, rejecting")
            return "rejected"
        
        recommendation = validation_result.get("recommendation", "rejected")
        
        if recommendation == "approved":
            logger.info("Validation approved, proceeding to generation")
            return "approved"
        else:
            logger.info("Validation rejected, ending workflow")
            return "rejected"
    
    def _route_after_assessment(
        self,
        state: WorkflowState
    ) -> Literal["regenerate", "select"]:
        """Route workflow after quality assessment.
        
        Args:
            state: Current workflow state
            
        Returns:
            Next step: "regenerate" or "select"
        """
        if should_regenerate(state, self.config):
            logger.info("Quality below threshold, regenerating")
            return "regenerate"
        else:
            logger.info("Quality acceptable or max attempts reached, selecting best")
            return "select"
    
    async def execute(self, initial_state: WorkflowState) -> WorkflowState:
        """Execute the complete workflow.
        
        Args:
            initial_state: Initial workflow state with input parameters
            
        Returns:
            Final workflow state with results
        """
        logger.info("Executing story generation workflow")
        
        try:
            # Run workflow
            final_state = await self.graph.ainvoke(initial_state)
            
            logger.info(f"Workflow complete: status={final_state.get('workflow_status')}")
            return final_state
            
        except Exception as e:
            logger.error(f"Workflow execution error: {str(e)}", exc_info=True)
            
            # Return error state
            initial_state["workflow_status"] = WorkflowStatus.FAILED.value
            initial_state["fatal_error"] = str(e)
            initial_state["error_messages"].append(f"Workflow error: {str(e)}")
            
            return initial_state


def create_workflow(
    openrouter_client,
    prompt_service: PromptService,
    quality_threshold: int = 7,
    theme_threshold: int = 7,
    max_generation_attempts: int = 3,
    validation_model: str = "openai/gpt-4o-mini",
    assessment_model: str = "openai/gpt-4o-mini",
    generation_model: str = None,
    first_attempt_temperature: float = 0.7,
    second_attempt_temperature: float = 0.8,
    third_attempt_temperature: float = 0.6,
    supabase_client=None
) -> StoryGenerationWorkflow:
    """Create a configured StoryGenerationWorkflow instance.
    
    Args:
        openrouter_client: AsyncOpenRouterClient instance
        prompt_service: PromptService instance
        quality_threshold: Minimum quality score to accept (1-10)
        max_generation_attempts: Maximum generation attempts
        theme_threshold: Minimum theme adherence score to accept (1-10)
        validation_model: Model for prompt validation
        assessment_model: Model for quality assessment
        generation_model: Model for story generation (None = use default)
        first_attempt_temperature: Temperature for 1st attempt
        second_attempt_temperature: Temperature for 2nd attempt
        third_attempt_temperature: Temperature for 3rd attempt
        
    Returns:
        Configured workflow instance
    """
    config = {
        "quality_threshold": quality_threshold,
        "theme_threshold": theme_threshold,
        "max_attempts": max_generation_attempts,
        "validation_model": validation_model,
        "assessment_model": assessment_model,
        "generation_model": generation_model,
        "first_attempt_temperature": first_attempt_temperature,
        "second_attempt_temperature": second_attempt_temperature,
        "third_attempt_temperature": third_attempt_temperature,
        "supabase_client": supabase_client,
    }
    
    return StoryGenerationWorkflow(
        openrouter_client,
        prompt_service,
        config
    )
