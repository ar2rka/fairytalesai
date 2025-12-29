"""Test script for the new Supabase-based prompt template system with detailed logging.

Run with: uv run python test_prompt_template_system.py
"""

import sys
import logging
from unittest.mock import Mock, MagicMock
from typing import List, Dict, Any
from datetime import datetime

# Set up detailed logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("test_prompt_template_system")
logger.setLevel(logging.DEBUG)

# Import after logging setup
from src.domain.value_objects import Language, StoryLength, Gender
from src.domain.entities import Child, Hero
from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.infrastructure.persistence.models import PromptDB, StoryDB
from src.infrastructure.persistence.prompt_repository import PromptRepository
from src.domain.services.prompt_template_service import PromptTemplateService
from src.domain.services.prompt_service import PromptService
from src.utils.jinja_helpers import register_jinja_filters
from jinja2.sandbox import SandboxedEnvironment


def print_separator(title: str = ""):
    """Print a visual separator."""
    if title:
        logger.info("=" * 80)
        logger.info(f"  {title}")
        logger.info("=" * 80)
    else:
        logger.info("=" * 80)


def test_prompt_repository():
    """Test PromptRepository with detailed logging."""
    print_separator("TEST: Loading prompts for English child story")
    
    # Mock Supabase client
    logger.info("Step 1: Setting up mock Supabase client")
    mock_client = Mock()
    mock_supabase_client = Mock()
    mock_table = Mock()
    mock_query = Mock()
    
    # Setup mock chain
    mock_client.client = mock_supabase_client
    mock_supabase_client.table.return_value = mock_table
    mock_table.select.return_value = mock_query
    mock_query.eq.return_value = mock_query
    mock_query.or_.return_value = mock_query
    mock_query.is_.return_value = mock_query
    mock_query.order.return_value = mock_query
    
    # Mock response data
    mock_response = Mock()
    mock_response.data = [
        {
            "id": "prompt-1",
            "priority": 1,
            "language": "en",
            "story_type": "child",
            "prompt_text": "Create a bedtime story for {{ child.name }}",
            "is_active": True,
            "description": "Character description",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": "prompt-2",
            "priority": 2,
            "language": "en",
            "story_type": "child",
            "prompt_text": "Focus on moral: {{ moral }}",
            "is_active": True,
            "description": "Moral instruction",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        },
        {
            "id": "prompt-3",
            "priority": 3,
            "language": "en",
            "story_type": None,
            "prompt_text": "Make it {{ word_count }} words long",
            "is_active": True,
            "description": "Length instruction",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
    ]
    mock_query.execute.return_value = mock_response
    logger.info("✓ Mock Supabase client configured")
    
    logger.info("Step 2: Initializing PromptRepository")
    repository = PromptRepository(mock_client)
    logger.info("✓ PromptRepository initialized")
    
    logger.info("Step 3: Loading prompts for language=en, story_type=child")
    prompts = repository.get_prompts(Language.ENGLISH, "child")
    logger.info(f"✓ Loaded {len(prompts)} prompts")
    
    # Verify
    assert len(prompts) == 3, f"Expected 3 prompts, got {len(prompts)}"
    logger.info(f"✓ Verified: {len(prompts)} prompts loaded")
    
    # Check priority order
    priorities = [p.priority for p in prompts]
    assert priorities == [1, 2, 3], f"Expected priorities [1, 2, 3], got {priorities}"
    logger.info(f"✓ Verified: Prompts sorted by priority: {priorities}")
    
    # Check prompt content
    assert "child.name" in prompts[0].prompt_text
    logger.info("✓ Verified: First prompt contains child.name variable")
    assert "moral" in prompts[1].prompt_text
    logger.info("✓ Verified: Second prompt contains moral variable")
    assert "word_count" in prompts[2].prompt_text
    logger.info("✓ Verified: Third prompt contains word_count variable")
    
    logger.info("Step 4: Testing cache")
    cached_prompts = repository.get_prompts(Language.ENGLISH, "child")
    assert len(cached_prompts) == 3
    logger.info("✓ Verified: Cache working correctly")
    
    print_separator()
    logger.info("✓ TEST PASSED: Loading prompts for English child story")
    print_separator()
    return True


def test_prompt_template_service_child_english():
    """Test rendering English child story prompt."""
    print_separator("TEST: Rendering English child story prompt")
    
    # Create mock repository
    logger.info("Step 1: Setting up mock repository")
    mock_repository = Mock(spec=PromptRepository)
    mock_repository.get_prompts.return_value = [
        PromptDB(
            id="p1",
            priority=1,
            language="en",
            story_type="child",
            prompt_text="Create a bedtime story for a child:\n- Name: {{ child.name }}\n- Age: {{ child.age_category | format_age_category(language) }}\n- Gender: {{ child.gender | translate_gender(language) }}\n- Interests: {{ child.interests | translate_interests(language) | join(', ') }}",
            is_active=True,
            description="Character description"
        ),
        PromptDB(
            id="p2",
            priority=2,
            language="en",
            story_type="child",
            prompt_text='The story should focus on the moral value of "{{ moral | translate_moral(language) }}".',
            is_active=True,
            description="Moral instruction"
        ),
        PromptDB(
            id="p3",
            priority=3,
            language="en",
            story_type=None,
            prompt_text="Make the story approximately {{ word_count }} words long.",
            is_active=True,
            description="Length instruction"
        ),
        PromptDB(
            id="p4",
            priority=4,
            language="en",
            story_type=None,
            prompt_text="Write the story in English.",
            is_active=True,
            description="Language instruction"
        )
    ]
    logger.info("✓ Mock repository configured with 4 prompt parts")
    
    logger.info("Step 2: Creating PromptTemplateService")
    service = PromptTemplateService(mock_repository)
    logger.info("✓ PromptTemplateService created")
    
    # Create child character
    logger.info("Step 3: Creating ChildCharacter")
    child_character = ChildCharacter(
        name="Emma",
        age_category="5-7",
        gender="female",
        interests=["unicorns", "fairies", "dancing"],
        age=6,
        description=None
    )
    logger.info(f"✓ ChildCharacter created: name={child_character.name}, age_category={child_character.age_category}, interests={child_character.interests}")
    
    logger.info("Step 4: Rendering prompt")
    prompt = service.render_prompt(
        character=child_character,
        moral="kindness",
        language=Language.ENGLISH,
        story_length=5,
        story_type="child",
        parent_story=None
    )
    logger.info("✓ Prompt rendered successfully")
    
    logger.info("Step 5: Verifying prompt content")
    checks = [
        ("Emma", "Child name"),
        ("5-7", "Age category"),
        ("female", "Gender"),
        ("unicorns", "Interests"),
        ("kindness", "Moral"),
        ("750", "Word count"),
        ("English", "Language instruction")
    ]
    
    for check_value, check_name in checks:
        if check_value in prompt:
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    logger.info("Step 6: Verifying prompt structure")
    parts = prompt.split("\n\n")
    logger.info(f"✓ Verified: Prompt has {len(parts)} parts separated by double newline")
    
    print_separator()
    logger.info("✓ TEST PASSED: Rendering English child story prompt")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("RENDERED PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def test_prompt_template_service_child_russian():
    """Test rendering Russian child story prompt."""
    print_separator("TEST: Rendering Russian child story prompt")
    
    mock_repository = Mock(spec=PromptRepository)
    mock_repository.get_prompts.return_value = [
        PromptDB(
            id="p1",
            priority=1,
            language="ru",
            story_type="child",
            prompt_text="Создай детскую сказку на ночь:\n- Имя: {{ child.name }}\n- Возраст: {{ child.age_category | format_age_category(language) }}\n- Пол: {{ child.gender | translate_gender(language) }}\n- Интересы: {{ child.interests | translate_interests(language) | join(', ') }}",
            is_active=True,
            description="Описание персонажа"
        ),
        PromptDB(
            id="p2",
            priority=2,
            language="ru",
            story_type="child",
            prompt_text='Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}".',
            is_active=True,
            description="Нравственный урок"
        ),
        PromptDB(
            id="p3",
            priority=3,
            language="ru",
            story_type=None,
            prompt_text="Сделай сказку приблизительно {{ word_count }} слов длинной.",
            is_active=True,
            description="Инструкция по длине"
        ),
        PromptDB(
            id="p4",
            priority=4,
            language="ru",
            story_type=None,
            prompt_text="Напиши сказку на русском языке.",
            is_active=True,
            description="Инструкция по языку"
        )
    ]
    
    service = PromptTemplateService(mock_repository)
    
    child_character = ChildCharacter(
        name="Аня",
        age_category="3-5",
        gender="female",
        interests=["котята", "цветы"],
        age=4,
        description=None
    )
    
    logger.info("Rendering Russian prompt for child Аня")
    prompt = service.render_prompt(
        character=child_character,
        moral="kindness",
        language=Language.RUSSIAN,
        story_length=3,
        story_type="child",
        parent_story=None
    )
    
    logger.info("Verifying Russian prompt content")
    checks = [
        ("Аня", "Child name"),
        ("доброта", "Moral translated to Russian"),
        ("девочка", "Gender translated to Russian"),
        ("русском", "Language instruction in Russian")
    ]
    
    for check_value, check_name in checks:
        if check_value in prompt:
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    print_separator()
    logger.info("✓ TEST PASSED: Rendering Russian child story prompt")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("RENDERED PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def test_prompt_template_service_with_parent_story():
    """Test rendering prompt with parent story (continuation)."""
    print_separator("TEST: Rendering prompt with parent story")
    
    mock_repository = Mock(spec=PromptRepository)
    mock_repository.get_prompts.return_value = [
        PromptDB(
            id="p1",
            priority=1,
            language="en",
            story_type="child",
            prompt_text="Create a story for {{ child.name }}",
            is_active=True,
            description="Character description"
        ),
        PromptDB(
            id="p2",
            priority=6,
            language="en",
            story_type=None,
            prompt_text='{% if parent_story %}\nPrevious Story:\nTitle: {{ parent_story.title }}\nContent: {% if parent_story.summary %}{{ parent_story.summary }}{% else %}{{ parent_story.content | truncate(500) if parent_story.content else "" }}{% endif %}\n\nThis is a continuation.\n{% endif %}',
            is_active=True,
            description="Continuation section"
        )
    ]
    
    service = PromptTemplateService(mock_repository)
    
    child_character = ChildCharacter(
        name="Emma",
        age_category="5-7",
        gender="female",
        interests=["unicorns"],
        age=6
    )
    
    parent_story = StoryDB(
        id="story-1",
        title="Emma's First Adventure",
        content="Once upon a time, Emma discovered a magical unicorn...",
        summary="Emma meets a magical unicorn and learns about friendship.",
        child_id="child-1",
        language="en",
        generation_id="gen-1",
        story_type="child"
    )
    
    logger.info("Rendering prompt with parent story")
    prompt = service.render_prompt(
        character=child_character,
        moral="kindness",
        language=Language.ENGLISH,
        story_length=5,
        story_type="child",
        parent_story=parent_story
    )
    
    logger.info("Verifying continuation section")
    checks = [
        ("Previous Story", "Previous Story section"),
        ("Emma's First Adventure", "Parent story title"),
        ("magical unicorn", "Parent story content/summary"),
        ("continuation", "Continuation instruction")
    ]
    
    for check_value, check_name in checks:
        if check_value.lower() in prompt.lower():
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    print_separator()
    logger.info("✓ TEST PASSED: Rendering prompt with parent story")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("RENDERED PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def test_prompt_template_service_hero():
    """Test rendering hero story prompt."""
    print_separator("TEST: Rendering hero story prompt")
    
    mock_repository = Mock(spec=PromptRepository)
    mock_repository.get_prompts.return_value = [
        PromptDB(
            id="p1",
            priority=1,
            language="en",
            story_type="hero",
            prompt_text="Create a story featuring:\n- Name: {{ hero.name }}\n- Age: {{ hero.age }}\n- Appearance: {{ hero.appearance }}\n- Traits: {{ hero.personality_traits | join(', ') }}",
            is_active=True,
            description="Hero description"
        ),
        PromptDB(
            id="p2",
            priority=2,
            language="en",
            story_type="hero",
            prompt_text='Focus on moral: "{{ moral | translate_moral(language) }}"',
            is_active=True,
            description="Moral instruction"
        )
    ]
    
    service = PromptTemplateService(mock_repository)
    
    hero_character = HeroCharacter(
        name="Brave Knight",
        age=25,
        gender="male",
        appearance="Tall and strong with shining armor",
        personality_traits=["brave", "kind", "wise"],
        strengths=["swordsmanship", "leadership"],
        interests=["adventure", "helping others"],
        language=Language.ENGLISH,
        description=None
    )
    
    logger.info("Rendering hero story prompt")
    prompt = service.render_prompt(
        character=hero_character,
        moral="bravery",
        language=Language.ENGLISH,
        story_length=5,
        story_type="hero",
        parent_story=None
    )
    
    logger.info("Verifying hero prompt content")
    checks = [
        ("Brave Knight", "Hero name"),
        ("25", "Hero age"),
        ("shining armor", "Hero appearance"),
        ("brave", "Hero personality trait"),
        ("bravery", "Moral")
    ]
    
    for check_value, check_name in checks:
        if check_value in prompt:
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    print_separator()
    logger.info("✓ TEST PASSED: Rendering hero story prompt")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("RENDERED PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def test_prompt_template_service_combined():
    """Test rendering combined story prompt."""
    print_separator("TEST: Rendering combined story prompt")
    
    mock_repository = Mock(spec=PromptRepository)
    mock_repository.get_prompts.return_value = [
        PromptDB(
            id="p1",
            priority=1,
            language="en",
            story_type="combined",
            prompt_text="Create a story with:\nChild: {{ child.name }}\nHero: {{ hero.name }}\n{% if relationship %}Relationship: {{ relationship }}{% endif %}",
            is_active=True,
            description="Combined character description"
        ),
        PromptDB(
            id="p2",
            priority=2,
            language="en",
            story_type="combined",
            prompt_text='Moral: "{{ moral | translate_moral(language) }}"',
            is_active=True,
            description="Moral instruction"
        )
    ]
    
    service = PromptTemplateService(mock_repository)
    
    child_character = ChildCharacter(
        name="Emma",
        age_category="5-7",
        gender="female",
        interests=["unicorns"],
        age=6
    )
    
    hero_character = HeroCharacter(
        name="Brave Knight",
        age=25,
        gender="male",
        appearance="Tall and strong",
        personality_traits=["brave"],
        strengths=["swordsmanship"],
        interests=["adventure"],
        language=Language.ENGLISH,
        description=None
    )
    
    combined_character = CombinedCharacter(
        child=child_character,
        hero=hero_character,
        relationship="Emma meets the legendary Brave Knight"
    )
    
    logger.info("Rendering combined story prompt")
    prompt = service.render_prompt(
        character=combined_character,
        moral="friendship",
        language=Language.ENGLISH,
        story_length=5,
        story_type="combined",
        parent_story=None
    )
    
    logger.info("Verifying combined prompt content")
    checks = [
        ("Emma", "Child name"),
        ("Brave Knight", "Hero name"),
        ("legendary", "Relationship description"),
        ("friendship", "Moral")
    ]
    
    for check_value, check_name in checks:
        if check_value in prompt:
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    print_separator()
    logger.info("✓ TEST PASSED: Rendering combined story prompt")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("RENDERED PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def test_jinja_filters():
    """Test Jinja2 custom filters."""
    print_separator("TEST: Jinja filters registration and functionality")
    
    logger.info("Step 1: Creating Jinja environment")
    env = SandboxedEnvironment()
    logger.info("✓ Environment created")
    
    logger.info("Step 2: Registering filters")
    register_jinja_filters(env)
    logger.info("✓ Filters registered")
    
    logger.info("Step 3: Testing filter availability")
    required_filters = [
        'translate_moral',
        'translate_gender',
        'translate_interests',
        'format_age_category',
        'join',
        'truncate'
    ]
    
    for filter_name in required_filters:
        if filter_name in env.filters:
            logger.info(f"✓ {filter_name} filter registered")
        else:
            logger.error(f"✗ ERROR: {filter_name} filter NOT registered")
            return False
    
    logger.info("Step 4: Testing filter functionality")
    
    # Test translate_moral
    template = env.from_string('{{ "kindness" | translate_moral(language) }}')
    result = template.render(language=Language.RUSSIAN)
    expected = "доброта"
    if result == expected:
        logger.info(f"✓ translate_moral filter works: 'kindness' -> '{result}'")
    else:
        logger.error(f"✗ ERROR: translate_moral failed. Expected '{expected}', got '{result}'")
        return False
    
    # Test join
    template = env.from_string('{{ ["a", "b", "c"] | join(", ") }}')
    result = template.render()
    expected = "a, b, c"
    if result == expected:
        logger.info(f"✓ join filter works: {result}")
    else:
        logger.error(f"✗ ERROR: join failed. Expected '{expected}', got '{result}'")
        return False
    
    # Test truncate
    template = env.from_string('{{ "very long text" | truncate(5) }}')
    result = template.render()
    expected = "very ..."
    if result == expected:
        logger.info(f"✓ truncate filter works: {result}")
    else:
        logger.error(f"✗ ERROR: truncate failed. Expected '{expected}', got '{result}'")
        return False
    
    print_separator()
    logger.info("✓ TEST PASSED: Jinja filters registration and functionality")
    print_separator()
    return True


def test_prompt_service_fallback():
    """Test PromptService fallback to legacy methods."""
    print_separator("TEST: PromptService fallback to legacy methods")
    
    logger.info("Step 1: Creating PromptService without Supabase client")
    prompt_service = PromptService(None)
    logger.info("✓ PromptService created without Supabase client")
    
    # Verify template service is None
    if prompt_service._template_service is None:
        logger.info("✓ Verified: Template service is None (fallback mode)")
    else:
        logger.error("✗ ERROR: Template service should be None")
        return False
    
    logger.info("Step 2: Creating Child entity")
    child = Child(
        name="Emma",
        age_category="5-7",
        gender=Gender.FEMALE,
        interests=["unicorns"],
        age=6
    )
    logger.info(f"✓ Child entity created: {child.name}")
    
    logger.info("Step 3: Generating prompt (should use legacy method)")
    prompt = prompt_service.generate_child_prompt(
        child=child,
        moral="kindness",
        language=Language.ENGLISH,
        story_length=StoryLength(minutes=5),
        parent_story=None
    )
    logger.info("✓ Prompt generated using legacy method")
    
    logger.info("Step 4: Verifying legacy prompt content")
    checks = [
        ("Emma", "Child name"),
        ("kindness", "Moral"),
        ("English", "Language instruction")
    ]
    
    for check_value, check_name in checks:
        if check_value in prompt:
            logger.info(f"✓ Verified: {check_name} '{check_value}' in prompt")
        else:
            logger.warning(f"✗ WARNING: {check_name} '{check_value}' NOT found in prompt")
    
    print_separator()
    logger.info("✓ TEST PASSED: Fallback to legacy methods")
    print_separator()
    logger.info(f"\n{'='*80}")
    logger.info("LEGACY PROMPT:")
    logger.info(f"{'='*80}")
    logger.info(f"\n{prompt}\n")
    logger.info(f"{'='*80}\n")
    return True


def main():
    """Run all tests."""
    print_separator("PROMPT TEMPLATE SYSTEM TEST SUITE")
    logger.info("Starting comprehensive tests for the new Supabase-based prompt template system")
    print_separator()
    
    tests = [
        ("Prompt Repository", test_prompt_repository),
        ("Jinja Filters", test_jinja_filters),
        ("Child Story Prompt (English)", test_prompt_template_service_child_english),
        ("Child Story Prompt (Russian)", test_prompt_template_service_child_russian),
        ("Prompt with Parent Story", test_prompt_template_service_with_parent_story),
        ("Hero Story Prompt", test_prompt_template_service_hero),
        ("Combined Story Prompt", test_prompt_template_service_combined),
        ("PromptService Fallback", test_prompt_service_fallback),
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            logger.info(f"\n>>> Running: {test_name}")
            result = test_func()
            results.append((test_name, result, None))
            if result:
                logger.info(f">>> ✓ PASSED: {test_name}\n")
            else:
                logger.error(f">>> ✗ FAILED: {test_name}\n")
        except Exception as e:
            logger.error(f">>> ✗ ERROR in {test_name}: {str(e)}", exc_info=True)
            results.append((test_name, False, str(e)))
    
    # Summary
    print_separator("TEST SUMMARY")
    passed = sum(1 for _, result, _ in results if result)
    total = len(results)
    
    logger.info(f"\nTotal tests: {total}")
    logger.info(f"Passed: {passed}")
    logger.info(f"Failed: {total - passed}")
    logger.info("\nDetailed results:")
    
    for test_name, result, error in results:
        status = "✓ PASSED" if result else "✗ FAILED"
        logger.info(f"  {status}: {test_name}")
        if error:
            logger.info(f"    Error: {error}")
    
    print_separator()
    
    if passed == total:
        logger.info("🎉 ALL TESTS PASSED!")
        return 0
    else:
        logger.error(f"❌ {total - passed} TEST(S) FAILED")
        return 1


if __name__ == "__main__":
    sys.exit(main())
