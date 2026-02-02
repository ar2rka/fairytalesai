"""Workflow state models for LangGraph story generation."""

from typing import TypedDict, Optional, List, Dict, Any
from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime


class WorkflowStatus(str, Enum):
    """Workflow execution status."""
    PENDING = "pending"
    VALIDATING = "validating"
    GENERATING = "generating"
    ASSESSING = "assessing"
    SUCCESS = "success"
    REJECTED = "rejected"
    FAILED = "failed"


@dataclass
class ValidationResult:
    """Result of prompt validation."""
    is_safe: bool
    has_licensed_characters: bool
    is_age_appropriate: bool
    detected_issues: List[str] = field(default_factory=list)
    reasoning: str = ""
    recommendation: str = ""  # 'approved' or 'rejected'
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON storage."""
        return {
            "is_safe": self.is_safe,
            "has_licensed_characters": self.has_licensed_characters,
            "is_age_appropriate": self.is_age_appropriate,
            "detected_issues": self.detected_issues,
            "reasoning": self.reasoning,
            "recommendation": self.recommendation,
            "timestamp": self.timestamp.isoformat()
        }


@dataclass
class QualityAssessment:
    """Quality assessment result for a story."""
    overall_score: int  # 1-10
    age_appropriateness_score: int
    moral_clarity_score: int
    narrative_coherence_score: int
    character_consistency_score: int
    engagement_score: int
    language_quality_score: int
    feedback: str = ""
    improvement_suggestions: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON storage."""
        return {
            "overall_score": self.overall_score,
            "age_appropriateness_score": self.age_appropriateness_score,
            "moral_clarity_score": self.moral_clarity_score,
            "narrative_coherence_score": self.narrative_coherence_score,
            "character_consistency_score": self.character_consistency_score,
            "engagement_score": self.engagement_score,
            "language_quality_score": self.language_quality_score,
            "feedback": self.feedback,
            "improvement_suggestions": self.improvement_suggestions,
            "timestamp": self.timestamp.isoformat()
        }


@dataclass
class GenerationAttempt:
    """Represents a single story generation attempt."""
    attempt_number: int
    content: str
    title: str
    quality_assessment: Optional[QualityAssessment] = None
    model_used: str = ""
    temperature: float = 0.7
    tokens_used: int = 0
    generation_time: float = 0.0
    error: Optional[str] = None
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON storage."""
        return {
            "attempt_number": self.attempt_number,
            "content": self.content,
            "title": self.title,
            "quality_assessment": self.quality_assessment.to_dict() if self.quality_assessment else None,
            "model_used": self.model_used,
            "temperature": self.temperature,
            "tokens_used": self.tokens_used,
            "generation_time": self.generation_time,
            "error": self.error,
            "timestamp": self.timestamp.isoformat()
        }


class WorkflowState(TypedDict, total=False):
    """State dictionary for LangGraph workflow.
    
    This TypedDict defines all possible state fields for the story generation workflow.
    LangGraph uses this to track state transitions across nodes.
    """
    
    # Input parameters
    original_prompt: str
    child_id: str
    child_name: str
    age_category: str  # Age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
    child_gender: str
    child_interests: List[str]
    
    hero_id: Optional[str]
    hero_name: Optional[str]
    hero_description: Optional[str]
    
    story_type: str  # 'child', 'hero', 'combined'
    language: str  # 'en', 'ru'
    moral: str
    theme: Optional[str]  # story theme / type (e.g. adventure, space)
    story_length: int  # in minutes
    expected_word_count: int
    user_id: str
    generation_id: str  # UUID for tracking in Supabase
    
    # Workflow execution state
    workflow_status: str  # WorkflowStatus enum value
    current_attempt: int
    start_time: float
    
    # Validation results
    validation_result: Optional[Dict[str, Any]]  # ValidationResult.to_dict()
    validation_error: Optional[str]
    
    # Generation attempts
    generation_attempts: List[Dict[str, Any]]  # List of GenerationAttempt.to_dict()
    current_generation: Optional[Dict[str, Any]]
    generation_error: Optional[str]
    
    # Quality assessments
    quality_assessments: List[Dict[str, Any]]  # List of QualityAssessment.to_dict()
    current_assessment: Optional[Dict[str, Any]]
    assessment_error: Optional[str]
    
    # Final selection
    best_story: Optional[Dict[str, Any]]  # Selected GenerationAttempt.to_dict()
    selected_attempt_number: Optional[int]
    selection_reason: Optional[str]
    all_scores: List[int]
    
    # Error tracking
    error_messages: List[str]
    fatal_error: Optional[str]
    
    # Metadata
    total_duration: Optional[float]
    validation_duration: Optional[float]
    generation_duration: Optional[float]
    assessment_duration: Optional[float]


def create_initial_state(
    original_prompt: str,
    child_id: str,
    child_name: str,
    age_category: str,
    child_gender: str,
    child_interests: List[str],
    story_type: str,
    language: str,
    moral: str,
    story_length: int,
    expected_word_count: int,
    user_id: str,
    generation_id: str,
    hero_id: Optional[str] = None,
    hero_name: Optional[str] = None,
    hero_description: Optional[str] = None,
    theme: Optional[str] = None,
) -> WorkflowState:
    """Create initial workflow state with input parameters.
    
    Args:
        original_prompt: The story generation prompt
        child_id: Child UUID
        child_name: Child's name
        age_category: Child's age category as string interval (e.g., '2-3', '4-5', '6-7', '2-3 года')
        child_gender: Child's gender
        child_interests: List of child's interests
        story_type: Type of story (child/hero/combined)
        language: Story language (en/ru)
        moral: Moral value to teach
        story_length: Story length in minutes
        expected_word_count: Expected word count
        user_id: User UUID
        hero_id: Optional hero UUID
        hero_name: Optional hero name
        hero_description: Optional hero description
        theme: Optional story theme (e.g. adventure, space)
        
    Returns:
        Initial workflow state
    """
    import time
    
    state: WorkflowState = {
        # Input parameters
        "original_prompt": original_prompt,
        "child_id": child_id,
        "child_name": child_name,
        "age_category": age_category,
        "child_gender": child_gender,
        "child_interests": child_interests,
        "hero_id": hero_id,
        "hero_name": hero_name,
        "hero_description": hero_description,
        "story_type": story_type,
        "language": language,
        "moral": moral,
        "theme": theme,
        "story_length": story_length,
        "expected_word_count": expected_word_count,
        "user_id": user_id,
        "generation_id": generation_id,
        
        # Workflow execution state
        "workflow_status": WorkflowStatus.PENDING.value,
        "current_attempt": 0,
        "start_time": time.time(),
        
        # Validation results
        "validation_result": None,
        "validation_error": None,
        
        # Generation attempts
        "generation_attempts": [],
        "current_generation": None,
        "generation_error": None,
        
        # Quality assessments
        "quality_assessments": [],
        "current_assessment": None,
        "assessment_error": None,
        
        # Final selection
        "best_story": None,
        "selected_attempt_number": None,
        "selection_reason": None,
        "all_scores": [],
        
        # Error tracking
        "error_messages": [],
        "fatal_error": None,
        
        # Metadata
        "total_duration": None,
        "validation_duration": None,
        "generation_duration": None,
        "assessment_duration": None,
    }
    
    return state
