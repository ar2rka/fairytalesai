"""Simple test for story generation.

Usage:
    uv run python test_story_generation_simple.py
"""

import asyncio
import os
from src.openrouter_client import OpenRouterClient, OpenRouterModel
from src.domain.entities import Child
from src.domain.value_objects import Gender, Language

async def test_simple_story_generation():
    """Test simple story generation."""
    print("=" * 60)
    print("Simple Story Generation Test")
    print("=" * 60)
    
    # Check if API key is set
    if not os.getenv("OPENROUTER_API_KEY"):
        print("\n✗ Error: OPENROUTER_API_KEY environment variable is not set")
        print("Please set it before running the test")
        return False
    
    # Initialize client
    print("\n1. Initializing OpenRouter client...")
    try:
        client = OpenRouterClient()
        print("✓ Client initialized")
    except Exception as e:
        print(f"✗ Failed to initialize client: {e}")
        return False
    
    # Test prompt
    print("\n2. Generating story...")
    print("   This will make an actual API call to OpenRouter")
    
    prompt = """Create a short bedtime story for a child named Emma, age 5, about kindness.
The story should be appropriate for children and approximately 200 words long.
Write the story in English."""
    
    try:
        result = await client.generate_story(
            prompt=prompt,
            model=OpenRouterModel.GPT_4O_MINI,  # Using cheaper model for testing
            max_tokens=500,
            max_retries=2,
            temperature=0.7,
            use_langgraph=True,  # Use full workflow
            child_name="Emma",
            child_gender="female",
            child_interests=["reading", "art"],
            moral="kindness",
            language="en",
            story_length_minutes=3,
            user_id="test-user"
        )
        
        print("\n" + "=" * 60)
        print("SUCCESS!")
        print("=" * 60)
        
        print(f"\n✓ Story generated successfully")
        print(f"  Model used: {result.model.value}")
        
        if result.title:
            print(f"  Title: {result.title}")
        
        print(f"\n  Content preview (first 300 chars):")
        print(f"  {result.content[:300]}...")
        
        if result.full_response:
            quality_score = result.full_response.get('quality_score')
            if quality_score:
                print(f"\n  Quality score: {quality_score}/10")
        
        print("\n✓ TEST PASSED")
        return True
        
    except Exception as e:
        print(f"\n✗ Error generating story: {str(e)}")
        import traceback
        traceback.print_exc()
        print("\n✗ TEST FAILED")
        return False
    
    finally:
        await client.close()


if __name__ == "__main__":
    print("\nRunning Simple Story Generation Test\n")
    success = asyncio.run(test_simple_story_generation())
    exit(0 if success else 1)

