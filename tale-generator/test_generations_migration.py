"""Test script to verify generations table implementation."""

import asyncio
import os
import logging
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_generation_repository():
    """Test generation repository operations."""
    from src.supabase_client_async import AsyncSupabaseClient
    from src.infrastructure.persistence.models import GenerationDB
    import uuid
    
    logger.info("=" * 60)
    logger.info("Testing Generation Repository")
    logger.info("=" * 60)
    
    client = AsyncSupabaseClient()
    
    # Test 1: Create a generation record
    logger.info("\n1. Creating generation record...")
    generation_id = str(uuid.uuid4())
    test_generation = GenerationDB(
        generation_id=generation_id,
        attempt_number=1,
        model_used="openai/gpt-4o-mini",
        full_response={"test": "response"},
        status="pending",
        prompt="Test prompt for bedtime story",
        user_id=os.getenv("TEST_USER_ID", str(uuid.uuid4())),
        story_type="child",
        story_length=5,
        hero_appearance=None,
        relationship_description=None,
        moral="kindness",
        error_message=None,
        created_at=datetime.now()
    )
    
    try:
        created_gen = await client.create_generation(test_generation)
        logger.info(f"✓ Created generation: {created_gen.generation_id}")
        logger.info(f"  Status: {created_gen.status}")
        logger.info(f"  Model: {created_gen.model_used}")
    except Exception as e:
        logger.error(f"✗ Failed to create generation: {e}")
        return False
    
    # Test 2: Get the generation record
    logger.info("\n2. Retrieving generation record...")
    try:
        retrieved_gen = await client.get_generation(generation_id, 1)
        if retrieved_gen:
            logger.info(f"✓ Retrieved generation: {retrieved_gen.generation_id}")
            logger.info(f"  Status: {retrieved_gen.status}")
            logger.info(f"  Prompt length: {len(retrieved_gen.prompt)} chars")
        else:
            logger.error("✗ Generation not found")
            return False
    except Exception as e:
        logger.error(f"✗ Failed to retrieve generation: {e}")
        return False
    
    # Test 3: Update generation to success
    logger.info("\n3. Updating generation to success...")
    try:
        updated_gen = GenerationDB(
            generation_id=generation_id,
            attempt_number=1,
            model_used="openai/gpt-4o-mini",
            full_response={"test": "updated response", "content": "Once upon a time..."},
            status="success",
            prompt="Test prompt for bedtime story",
            user_id=test_generation.user_id,
            story_type="child",
            story_length=5,
            hero_appearance=None,
            relationship_description=None,
            moral="kindness",
            error_message=None,
            completed_at=datetime.now()
        )
        
        updated = await client.update_generation(updated_gen)
        logger.info(f"✓ Updated generation status: {updated.status}")
        logger.info(f"  Completed at: {updated.completed_at}")
    except Exception as e:
        logger.error(f"✗ Failed to update generation: {e}")
        return False
    
    # Test 4: Create retry attempt
    logger.info("\n4. Creating retry attempt...")
    try:
        retry_gen = GenerationDB(
            generation_id=generation_id,
            attempt_number=2,
            model_used="openai/gpt-4o",
            full_response=None,
            status="failed",
            prompt="Test prompt for bedtime story",
            user_id=test_generation.user_id,
            story_type="child",
            story_length=5,
            hero_appearance=None,
            relationship_description=None,
            moral="kindness",
            error_message="Rate limit exceeded",
            created_at=datetime.now(),
            completed_at=datetime.now()
        )
        
        retry_created = await client.create_generation(retry_gen)
        logger.info(f"✓ Created retry attempt: {retry_created.attempt_number}")
        logger.info(f"  Status: {retry_created.status}")
        logger.info(f"  Error: {retry_created.error_message}")
    except Exception as e:
        logger.error(f"✗ Failed to create retry: {e}")
        return False
    
    # Test 5: Get all attempts
    logger.info("\n5. Getting all attempts for generation...")
    try:
        all_attempts = await client.get_all_attempts(generation_id)
        logger.info(f"✓ Found {len(all_attempts)} attempts")
        for attempt in all_attempts:
            logger.info(f"  Attempt {attempt.attempt_number}: {attempt.status}")
    except Exception as e:
        logger.error(f"✗ Failed to get all attempts: {e}")
        return False
    
    # Test 6: Get latest attempt
    logger.info("\n6. Getting latest attempt...")
    try:
        latest = await client.get_latest_attempt(generation_id)
        if latest:
            logger.info(f"✓ Latest attempt: {latest.attempt_number}")
            logger.info(f"  Status: {latest.status}")
        else:
            logger.error("✗ No latest attempt found")
            return False
    except Exception as e:
        logger.error(f"✗ Failed to get latest attempt: {e}")
        return False
    
    # Test 7: Get user generations
    logger.info("\n7. Getting user generations...")
    try:
        user_gens = await client.get_user_generations(test_generation.user_id, limit=10)
        logger.info(f"✓ Found {len(user_gens)} generations for user")
        for gen in user_gens[:3]:  # Show first 3
            logger.info(f"  {gen.generation_id}: {gen.status} ({gen.story_type})")
    except Exception as e:
        logger.error(f"✗ Failed to get user generations: {e}")
        return False
    
    # Test 8: Get generations by status
    logger.info("\n8. Getting generations by status...")
    try:
        success_gens = await client.get_generations_by_status("success", limit=5)
        logger.info(f"✓ Found {len(success_gens)} successful generations")
    except Exception as e:
        logger.error(f"✗ Failed to get generations by status: {e}")
        return False
    
    logger.info("\n" + "=" * 60)
    logger.info("All generation repository tests passed! ✓")
    logger.info("=" * 60)
    return True


async def test_story_with_generation():
    """Test creating a story linked to a generation."""
    from src.supabase_client_async import AsyncSupabaseClient
    from src.infrastructure.persistence.models import GenerationDB
    from src.models import StoryDB
    import uuid
    
    logger.info("\n" + "=" * 60)
    logger.info("Testing Story-Generation Integration")
    logger.info("=" * 60)
    
    client = AsyncSupabaseClient()
    
    # Create a generation record first
    logger.info("\n1. Creating generation record...")
    generation_id = str(uuid.uuid4())
    test_user_id = os.getenv("TEST_USER_ID", str(uuid.uuid4()))
    
    generation = GenerationDB(
        generation_id=generation_id,
        attempt_number=1,
        model_used="openai/gpt-4o-mini",
        full_response={"content": "Test story content"},
        status="success",
        prompt="Create a bedtime story",
        user_id=test_user_id,
        story_type="child",
        story_length=5,
        hero_appearance=None,
        relationship_description=None,
        moral="bravery",
        error_message=None,
        created_at=datetime.now(),
        completed_at=datetime.now()
    )
    
    try:
        created_gen = await client.create_generation(generation)
        logger.info(f"✓ Created generation: {created_gen.generation_id}")
    except Exception as e:
        logger.error(f"✗ Failed to create generation: {e}")
        return False
    
    # Create a story linked to this generation
    logger.info("\n2. Creating story with generation_id...")
    story = StoryDB(
        title="The Brave Little Star",
        content="Once upon a time, there was a brave little star...",
        child_id=None,
        child_name="Test Child",
        child_age=7,
        child_gender="girl",
        child_interests=["stars", "adventure"],
        hero_id=None,
        hero_name=None,
        hero_gender=None,
        language="en",
        rating=None,
        audio_file_url=None,
        audio_provider=None,
        audio_generation_metadata=None,
        user_id=test_user_id,
        generation_id=generation_id,  # Link to generation
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    
    try:
        saved_story = await client.save_story(story)
        logger.info(f"✓ Created story: {saved_story.id}")
        logger.info(f"  Title: {saved_story.title}")
        logger.info(f"  Generation ID: {saved_story.generation_id}")
        
        # Verify the generation_id matches
        if saved_story.generation_id == generation_id:
            logger.info("✓ Generation ID correctly linked")
        else:
            logger.error("✗ Generation ID mismatch!")
            return False
    except Exception as e:
        logger.error(f"✗ Failed to create story: {e}")
        return False
    
    logger.info("\n" + "=" * 60)
    logger.info("Story-Generation integration test passed! ✓")
    logger.info("=" * 60)
    return True


async def main():
    """Run all tests."""
    logger.info("Starting Generations Migration Tests")
    logger.info("=" * 60)
    
    try:
        # Test 1: Generation repository operations
        gen_test_passed = await test_generation_repository()
        
        # Test 2: Story-generation integration
        if gen_test_passed:
            story_test_passed = await test_story_with_generation()
        else:
            logger.warning("Skipping story integration test due to generation test failure")
            story_test_passed = False
        
        # Final summary
        logger.info("\n" + "=" * 60)
        logger.info("TEST SUMMARY")
        logger.info("=" * 60)
        logger.info(f"Generation Repository Tests: {'✓ PASSED' if gen_test_passed else '✗ FAILED'}")
        logger.info(f"Story Integration Tests: {'✓ PASSED' if story_test_passed else '✗ FAILED'}")
        logger.info("=" * 60)
        
        if gen_test_passed and story_test_passed:
            logger.info("\n🎉 All tests passed successfully!")
            return True
        else:
            logger.error("\n❌ Some tests failed. Please review the errors above.")
            return False
            
    except Exception as e:
        logger.error(f"Test execution failed: {e}", exc_info=True)
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    exit(0 if success else 1)
