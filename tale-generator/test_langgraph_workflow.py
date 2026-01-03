"""Test script for LangGraph story generation workflow.

This script tests the LangGraph workflow implementation end-to-end.

Usage:
    uv run python test_langgraph_workflow.py
"""

import asyncio
import os
from datetime import datetime

# Set environment variables for testing
os.environ["LANGGRAPH_ENABLED"] = "true"
os.environ["LANGGRAPH_QUALITY_THRESHOLD"] = "7"
os.environ["LANGGRAPH_MAX_GENERATION_ATTEMPTS"] = "3"

from src.openrouter_client import OpenRouterClient
from src.domain.services.prompt_service import PromptService
from src.domain.services.langgraph import LangGraphWorkflowService
from src.domain.entities import Child
from src.domain.value_objects import Gender, Language, StoryLength
from src.infrastructure.config.settings import get_settings


async def test_workflow():
    """Test the LangGraph workflow."""
    
    print("=" * 60)
    print("LangGraph Story Generation Workflow Test")
    print("=" * 60)
    
    # Check settings
    settings = get_settings()
    print(f"\nLangGraph enabled: {settings.langgraph_workflow.enabled}")
    print(f"Quality threshold: {settings.langgraph_workflow.quality_threshold}")
    print(f"Max attempts: {settings.langgraph_workflow.max_generation_attempts}")
    
    # Initialize services
    print("\n1. Initializing services...")
    openrouter_client = OpenRouterClient()
    
    # Initialize PromptService with Supabase client if available
    from src.api.helpers.services import initialize_supabase_client, initialize_prompt_service
    supabase_client = initialize_supabase_client()
    prompt_service = initialize_prompt_service(supabase_client)
    
    if prompt_service._template_service:
        print("✅ PromptService initialized with Supabase prompts")
    else:
        print("⚠️ PromptService using built-in methods (Supabase not available)")
    
    # Create mock repositories (in real usage, use actual repositories)
    class MockChildRepository:
        async def find_exact_match(self, name, age, gender):
            return None
        async def save(self, child):
            child.id = "test-child-id"
            return child
    
    class MockHeroRepository:
        async def find_by_id(self, hero_id):
            return None
    
    workflow_service = LangGraphWorkflowService(
        openrouter_client=openrouter_client,
        prompt_service=prompt_service,
        child_repository=MockChildRepository(),
        hero_repository=MockHeroRepository()
    )
    
    print("✓ Services initialized")
    
    # Create test child
    print("\n2. Creating test child...")
    child = Child(
        name="Emma",
        age_category="5-7",
        gender=Gender.FEMALE,
        interests=["unicorns", "reading", "art"]
    )
    print(f"✓ Child created: {child.name}, age_category {child.age_category}")
    
    # Test workflow execution
    print("\n3. Executing LangGraph workflow...")
    print("This will:")
    print("  - Validate the prompt for safety")
    print("  - Generate a story")
    print("  - Assess story quality")
    print("  - Regenerate if quality < 7")
    print("  - Select best story from attempts")
    
    start_time = datetime.now()
    
    try:
        result = await workflow_service.execute_workflow(
            child=child,
            moral="kindness",
            language=Language.ENGLISH,
            story_length=StoryLength(minutes=5),
            story_type="child",
            user_id="test-user"
        )
        
        duration = (datetime.now() - start_time).total_seconds()
        
        print("\n" + "=" * 60)
        print("WORKFLOW RESULTS")
        print("=" * 60)
        
        if result.success:
            print(f"\n✓ Workflow completed successfully in {duration:.1f}s")
            print(f"\nStory Title: {result.story_title}")
            print(f"Quality Score: {result.quality_score}/10")
            print(f"Attempts Made: {result.attempts_count}")
            print(f"Selected Attempt: {result.selected_attempt_number}")
            
            print(f"\nAll Scores: {result.quality_metadata.get('all_scores', [])}")
            print(f"Selection Reason: {result.quality_metadata.get('selection_reason', 'N/A')}")

            print(f" Prompt: {result.prompt}")
            print(f" Story Title: {result.story_title}")
            print(f" Story content: { len(result.story_content)}")

            print(f"\n--- Story Content ---")
            print(result.story_content[:500] + "..." if len(result.story_content) > 500 else result.story_content)
            
            # Print quality assessment details
            if result.quality_metadata and result.quality_metadata.get('quality_assessments'):
                print(f"\n--- Quality Assessments ---")
                for i, assessment in enumerate(result.quality_metadata['quality_assessments'], 1):
                    print(f"\nAttempt {i}:")
                    print(f"  Overall: {assessment.get('overall_score', 0)}/10")
                    print(f"  Age Appropriateness: {assessment.get('age_appropriateness_score', 0)}/10")
                    print(f"  Moral Clarity: {assessment.get('moral_clarity_score', 0)}/10")
                    print(f"  Narrative Coherence: {assessment.get('narrative_coherence_score', 0)}/10")
                    print(f"  Feedback: {assessment.get('feedback', '')[:100]}...")
            
            # Print validation result
            if result.validation_result:
                print(f"\n--- Validation Result ---")
                print(f"  Safe: {result.validation_result.get('is_safe')}")
                print(f"  Licensed Characters: {result.validation_result.get('has_licensed_characters')}")
                print(f"  Age Appropriate: {result.validation_result.get('is_age_appropriate')}")
                print(f"  Recommendation: {result.validation_result.get('recommendation')}")
            
            # Print workflow metadata
            if result.workflow_metadata:
                print(f"\n--- Workflow Timing ---")
                print(f"  Validation: {result.workflow_metadata.get('validation_duration', 0):.2f}s")
                print(f"  Generation: {result.workflow_metadata.get('generation_duration', 0):.2f}s")
                print(f"  Assessment: {result.workflow_metadata.get('assessment_duration', 0):.2f}s")
                print(f"  Total: {result.workflow_metadata.get('total_duration', 0):.2f}s")
            
            print("\n✓ TEST PASSED")
            
        else:
            print(f"\n✗ Workflow failed: {result.error_message}")
            print("\n✗ TEST FAILED")
            
    except Exception as e:
        print(f"\n✗ Error executing workflow: {str(e)}")
        import traceback
        traceback.print_exc()
        print("\n✗ TEST FAILED")
    
    finally:
        await openrouter_client.close()
    
    print("\n" + "=" * 60)


async def test_validation_rejection():
    """Test prompt validation rejection (with licensed character)."""
    
    print("\n" + "=" * 60)
    print("Testing Prompt Validation Rejection")
    print("=" * 60)
    
    # Initialize services
    openrouter_client = OpenRouterClient()
    # Initialize PromptService with Supabase client if available
    from src.api.helpers.services import initialize_supabase_client, initialize_prompt_service
    supabase_client = initialize_supabase_client()
    prompt_service = initialize_prompt_service(supabase_client)
    
    class MockChildRepository:
        async def find_exact_match(self, name, age, gender):
            return None
        async def save(self, child):
            child.id = "test-child-id"
            return child
    
    class MockHeroRepository:
        async def find_by_id(self, hero_id):
            return None
    
    workflow_service = LangGraphWorkflowService(
        openrouter_client=openrouter_client,
        prompt_service=prompt_service,
        child_repository=MockChildRepository(),
        hero_repository=MockHeroRepository()
    )
    
    # Create child with licensed character interest
    child = Child(
        name="Test Child",
        age_category="3-5",
        gender=Gender.MALE,
        interests=["Mickey Mouse", "Disney characters"]  # Should trigger rejection
    )
    
    print(f"\nTesting with potentially problematic interests: {child.interests}")
    
    try:
        result = await workflow_service.execute_workflow(
            child=child,
            moral="sharing",
            language=Language.ENGLISH,
            story_length=StoryLength(minutes=5),
            story_type="child",
            user_id="test-user"
        )
        
        if not result.success and result.validation_result:
            print(f"\n✓ Validation correctly rejected prompt")
            print(f"  Reason: {result.error_message}")
            print(f"  Licensed Characters Detected: {result.validation_result.get('has_licensed_characters')}")
        elif result.success:
            print(f"\n⚠ Validation passed (may need stricter rules)")
            print(f"  Quality Score: {result.quality_score}/10")
        else:
            print(f"\n✗ Unexpected failure: {result.error_message}")
            
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
    
    finally:
        await openrouter_client.close()
    
    print("\n" + "=" * 60)


if __name__ == "__main__":
    print("\nRunning LangGraph Workflow Tests\n")
    
    # Run main workflow test
    asyncio.run(test_workflow())
    
    # Run validation rejection test
    print("\n\n")
    asyncio.run(test_validation_rejection())
    
    print("\n\nAll tests completed!")
