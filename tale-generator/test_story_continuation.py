"""Test script for story continuation generation."""

import asyncio
import sys
from src.supabase_client_async import AsyncSupabaseClient
from src.openrouter_client import OpenRouterClient
from src.domain.services.prompt_service import PromptService
from src.domain.value_objects import Language, StoryLength
from src.domain.entities import Child
from src.models import StoryDB

# Test IDs
PARENT_STORY_ID = "e39b7876-d719-4390-aaef-045acf907263"
CHILD_ID = "b881a962-81fe-467d-a23b-c98a419ad1f2"


async def test_story_continuation():
    """Test generating a story continuation."""
    print("=" * 80)
    print("Testing Story Continuation Generation")
    print("=" * 80)
    print()
    
    # Initialize clients
    print("Initializing clients...")
    supabase_client = AsyncSupabaseClient()
    openrouter_client = OpenRouterClient()
    prompt_service = PromptService()
    
    try:
        # Fetch parent story
        print(f"Fetching parent story: {PARENT_STORY_ID}")
        parent_story = await supabase_client.get_story(PARENT_STORY_ID)
        if not parent_story:
            print(f"❌ Error: Parent story not found!")
            return
        
        print(f"✓ Parent story found:")
        print(f"  - Title: {parent_story.title}")
        print(f"  - Language: {parent_story.language}")
        print(f"  - Summary: {parent_story.summary[:100] if parent_story.summary else 'No summary'}...")
        print()
        
        # Fetch child
        print(f"Fetching child: {CHILD_ID}")
        child_data = await supabase_client.get_child(CHILD_ID)
        if not child_data:
            print(f"❌ Error: Child not found!")
            return
        
        print(f"✓ Child found:")
        print(f"  - Name: {child_data.name}")
        print(f"  - Age: {child_data.age}")
        age_category = getattr(child_data, 'age_category', None)
        if age_category:
            print(f"  - Age category: {age_category}")
        print(f"  - Gender: {child_data.gender}")
        print(f"  - Interests: {', '.join(child_data.interests)}")
        print()
        
        # Convert to domain entity
        from src.domain.value_objects import Gender
        # Get age_category if available, otherwise calculate from age
        age_category = getattr(child_data, 'age_category', None)
        if not age_category:
            # Calculate age_category from age as fallback
            if child_data.age <= 3:
                age_category = '2-3'
            elif child_data.age <= 5:
                age_category = '3-5'
            else:
                age_category = '5-7'
        
        child = Child(
            id=child_data.id,
            name=child_data.name,
            age_category=age_category,
            gender=Gender(child_data.gender),
            interests=child_data.interests,
            age=child_data.age
        )
        
        # Generate prompt
        print("Generating prompt with parent story...")
        language = Language.ENGLISH if parent_story.language == "en" else Language.RUSSIAN
        story_length = StoryLength(minutes=5)
        moral = "kindness"
        
        prompt = prompt_service.generate_child_prompt(
            child=child,
            moral=moral,
            language=language,
            story_length=story_length,
            parent_story=parent_story
        )
        
        print("=" * 80)
        print("GENERATED PROMPT:")
        print("=" * 80)
        print(prompt)
        print("=" * 80)
        print()
        
        # Generate story
        print("Generating story content...")
        result = await openrouter_client.generate_story(
            prompt=prompt,
            max_retries=3,
            retry_delay=1.0,
            use_langgraph=False,  # Use simple generation for testing
            temperature=0.7
        )
        
        print("=" * 80)
        print("GENERATED STORY:")
        print("=" * 80)
        print(f"Model used: {result.model.value if result.model else 'unknown'}")
        print()
        print(result.content)
        print("=" * 80)
        print()
        
        print("✅ Story generation completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(test_story_continuation())

