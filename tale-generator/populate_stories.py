"""Script to populate the database with sample stories."""

import asyncio
import logging
import os
import random
import re
import time
import uuid
from datetime import datetime
from src.supabase_client_async import AsyncSupabaseClient
from src.models import StoryDB, ChildDB, Language
from src.openrouter_client import OpenRouterClient, OpenRouterModel
from src.prompts.builders import EnglishPromptBuilder, RussianPromptBuilder
from src.prompts.character_types import ChildCharacter, HeroCharacter, CombinedCharacter
from src.domain.entities import Hero
from src.voice_providers.elevenlabs_provider import ElevenLabsProvider

# Set up logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),  # Log to console
        logging.FileHandler('populate_stories.log')  # Also log to file
    ]
)
logger = logging.getLogger("tale_generator.populate")

# Sample children data
CHILDREN = [
    {
        "name": "Emma",
        "age": 6,
        "gender": "female",
        "interests": ["unicorns", "fairies", "princesses"]
    },
    {
        "name": "Liam",
        "age": 7,
        "gender": "male",
        "interests": ["dinosaurs", "trucks", "robots"]
    },
    {
        "name": "Olivia",
        "age": 5,
        "gender": "female",
        "interests": ["cats", "flowers", "dancing"]
    },
    {
        "name": "Noah",
        "age": 8,
        "gender": "male",
        "interests": ["space", "aliens", "planets"]
    },
    {
        "name": "Ava",
        "age": 4,
        "gender": "female",
        "interests": ["bunnies", "carrots", "gardens"]
    }
]

# Sample morals
MORALS = [
    "kindness",
    "honesty",
    "bravery",
    "friendship",
    "perseverance",
    "empathy",
    "respect",
    "responsibility"
]

# Sample models to use
MODELS = [
    OpenRouterModel.GPT_4O_MINI,
    OpenRouterModel.CLAUDE_3_HAIKU,
    OpenRouterModel.LLAMA_3_1_8B,
    OpenRouterModel.GEMMA_2_27B,
    OpenRouterModel.MIXTRAL_8X22B,
    OpenRouterModel.GROK_41_FREE,
    OpenRouterModel.GEMINI_20_FREE
]

# Sample languages
LANGUAGES = [
    Language.ENGLISH,
    Language.RUSSIAN
]

# Whether to generate audio for stories (set to False by default)
GENERATE_AUDIO = False

# Story type options
STORY_TYPES = ["child", "hero", "combined"]


def clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers.
    
    Args:
        content: Raw story content from AI
        
    Returns:
        Cleaned content without formatting markers
    """
    # Remove sequences of 3 or more asterisks
    cleaned = re.sub(r'\*{3,}', '', content)
    
    # Remove sequences of 3 or more underscores
    cleaned = re.sub(r'_{3,}', '', cleaned)
    
    # Remove sequences of 3 or more hyphens (but not in words)
    cleaned = re.sub(r'(?<!\w)-{3,}(?!\w)', '', cleaned)
    
    # Clean up any excessive whitespace that might have been left
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    
    return cleaned.strip()


async def create_story_prompt(child, moral, language: Language, story_type: str = "child", hero_index: int = 0):
    """Create a language-specific prompt for story generation using the new prompt builder system."""
    start_time = time.time()
    # Select appropriate builder based on language
    builder = EnglishPromptBuilder() if language == Language.ENGLISH else RussianPromptBuilder()
    
    if story_type == "hero":
        # Retrieve heroes from database
        try:
            logger.info(f"Starting hero story prompt creation for language {language.value}")
            supabase_client = AsyncSupabaseClient()
            heroes_start = time.time()
            all_heroes = await supabase_client.get_all_heroes()
            heroes_duration = time.time() - heroes_start
            logger.info(f"Retrieved {len(all_heroes)} heroes in {heroes_duration:.2f}s")
            
            # Filter heroes by language
            filter_start = time.time()
            language_heroes = [h for h in all_heroes if h.language == language]
            filter_duration = time.time() - filter_start
            logger.info(f"Filtered heroes by language in {filter_duration:.2f}s, found {len(language_heroes)} heroes")
            
            if not language_heroes:
                raise ValueError(f"No heroes found in database for language: {language.value}")
            
            # Select hero by index
            hero_selection_start = time.time()
            hero_entity = language_heroes[hero_index % len(language_heroes)]
            hero_selection_duration = time.time() - hero_selection_start
            logger.info(f"Selected hero {hero_entity.name} in {hero_selection_duration:.2f}s")
            
            # Convert domain Hero entity to HeroCharacter
            conversion_start = time.time()
            hero_character = HeroCharacter(
                name=hero_entity.name,
                age=25,  # Default age for heroes (HeroDB doesn't have age field)
                gender=hero_entity.gender if isinstance(hero_entity.gender, str) else hero_entity.gender.value,
                appearance=hero_entity.appearance,
                personality_traits=hero_entity.personality_traits,
                strengths=hero_entity.strengths,
                interests=hero_entity.interests,
                language=hero_entity.language,
                description=None
            )
            conversion_duration = time.time() - conversion_start
            logger.info(f"Converted hero entity in {conversion_duration:.2f}s")
            
            # Build prompt using builder pattern
            prompt_building_start = time.time()
            prompt = (builder
                .set_character(hero_character)
                .set_moral(moral)
                .set_story_length(3)
                .build())
            prompt_building_duration = time.time() - prompt_building_start
            logger.info(f"Built prompt in {prompt_building_duration:.2f}s")
            
            total_duration = time.time() - start_time
            logger.info(f"Completed hero story prompt creation in {total_duration:.2f}s")
            return prompt.strip(), hero_entity  # Return hero_entity for later use
            
        except Exception as e:
            logger.error(f"Error creating hero story prompt: {e}")
            raise
    elif story_type == "combined":
        # Retrieve heroes from database
        try:
            logger.info(f"Starting combined story prompt creation for language {language.value}")
            supabase_client = AsyncSupabaseClient()
            heroes_start = time.time()
            all_heroes = await supabase_client.get_all_heroes()
            heroes_duration = time.time() - heroes_start
            logger.info(f"Retrieved {len(all_heroes)} heroes in {heroes_duration:.2f}s")
            
            # Filter heroes by language
            filter_start = time.time()
            language_heroes = [h for h in all_heroes if h.language == language]
            filter_duration = time.time() - filter_start
            logger.info(f"Filtered heroes by language in {filter_duration:.2f}s, found {len(language_heroes)} heroes")
            
            if not language_heroes:
                raise ValueError(f"No heroes found in database for language: {language.value}")
            
            # Select hero by index
            hero_selection_start = time.time()
            hero_entity = language_heroes[hero_index % len(language_heroes)]
            hero_selection_duration = time.time() - hero_selection_start
            logger.info(f"Selected hero {hero_entity.name} in {hero_selection_duration:.2f}s")
            
            # Convert dict to ChildCharacter
            child_conversion_start = time.time()
            child_character = ChildCharacter(
                name=child['name'],
                age=child['age'],
                gender=child['gender'],
                interests=child['interests'],
                description=None
            )
            child_conversion_duration = time.time() - child_conversion_start
            logger.info(f"Converted child data to character in {child_conversion_duration:.2f}s")
            
            # Convert domain Hero entity to HeroCharacter
            hero_conversion_start = time.time()
            hero_character = HeroCharacter(
                name=hero_entity.name,
                age=25,  # Default age for heroes (HeroDB doesn't have age field)
                gender=hero_entity.gender if isinstance(hero_entity.gender, str) else hero_entity.gender.value,
                appearance=hero_entity.appearance,
                personality_traits=hero_entity.personality_traits,
                strengths=hero_entity.strengths,
                interests=hero_entity.interests,
                language=hero_entity.language,
                description=None
            )
            hero_conversion_duration = time.time() - hero_conversion_start
            logger.info(f"Converted hero entity in {hero_conversion_duration:.2f}s")
            
            # Create relationship description based on language
            relationship_start = time.time()
            if language == Language.ENGLISH:
                relationship = f"{child['name']} meets the legendary {hero_entity.name}"
            else:  # Russian
                relationship = f"{child['name']} встречает легендарного героя {hero_entity.name}"
            relationship_duration = time.time() - relationship_start
            logger.info(f"Created relationship description in {relationship_duration:.2f}s")
            
            # Create CombinedCharacter
            combined_char_start = time.time()
            combined_character = CombinedCharacter(
                child=child_character,
                hero=hero_character,
                relationship=relationship
            )
            combined_char_duration = time.time() - combined_char_start
            logger.info(f"Created combined character in {combined_char_duration:.2f}s")
            
            # Build prompt using builder pattern
            prompt_building_start = time.time()
            prompt = (builder
                .set_character(combined_character)
                .set_moral(moral)
                .set_story_length(5)  # Combined stories are longer
                .build())
            prompt_building_duration = time.time() - prompt_building_start
            logger.info(f"Built prompt in {prompt_building_duration:.2f}s")
            
            total_duration = time.time() - start_time
            logger.info(f"Completed combined story prompt creation in {total_duration:.2f}s")
            return prompt.strip(), hero_entity  # Return hero_entity for later use
            
        except Exception as e:
            logger.error(f"Error creating combined story prompt: {e}")
            raise
    else:
        logger.info("Starting child story prompt creation")
        # Convert dict to ChildCharacter
        conversion_start = time.time()
        child_character = ChildCharacter(
            name=child['name'],
            age=child['age'],
            gender=child['gender'],
            interests=child['interests'],
            description=None
        )
        conversion_duration = time.time() - conversion_start
        logger.info(f"Converted child data to character in {conversion_duration:.2f}s")
        
        # Build prompt using builder pattern
        prompt_building_start = time.time()
        prompt = (builder
            .set_character(child_character)
            .set_moral(moral)
            .set_story_length(3)
            .build())
        prompt_building_duration = time.time() - prompt_building_start
        logger.info(f"Built prompt in {prompt_building_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"Completed child story prompt creation in {total_duration:.2f}s")
        return prompt.strip(), None  # Return hero_entity as None for child stories


async def generate_sample_stories():
    """Generate sample stories and save them to the database."""
    start_time = time.time()
    try:
        # Initialize clients
        logger.info("Initializing clients...")
        client_init_start = time.time()
        openrouter_client = OpenRouterClient()
        supabase_client = AsyncSupabaseClient()
        client_init_duration = time.time() - client_init_start
        logger.info(f"Clients initialized in {client_init_duration:.2f}s")
        
        children_save_start = time.time()
        logger.info("Starting to save children to database...")
        
        # Save children to database
        saved_children = []
        children_processing_start = time.time()
        for i, child_data in enumerate(CHILDREN):
            child_start = time.time()
            try:
                child_db = ChildDB(
                    name=child_data["name"],
                    age=child_data["age"],
                    gender=child_data["gender"],
                    interests=child_data["interests"],
                    created_at=datetime.now().isoformat(),
                    updated_at=datetime.now().isoformat()
                )
                saved_child = await supabase_client.save_child(child_db)
                saved_children.append(saved_child)
                child_duration = time.time() - child_start
                logger.info(f"Saved child: {saved_child.name} with ID: {saved_child.id} in {child_duration:.2f}s")
            except Exception as e:
                child_duration = time.time() - child_start
                logger.error(f"Error saving child {child_data['name']} in {child_duration:.2f}s: {e}")
        children_processing_duration = time.time() - children_processing_start
        logger.info(f"Processed all children in {children_processing_duration:.2f}s")
        children_save_duration = time.time() - children_save_start
        logger.info(f"Children saving completed in {children_save_duration:.2f}s")
        
        story_generation_start = time.time()
        logger.info(f"Generating 10 sample stories...")
        
        # Create tasks for concurrent story generation
        tasks_creation_start = time.time()
        tasks = []
        for i in range(10):
            # Select a child (rotate through the list)
            child_index = i % len(saved_children)
            child = saved_children[child_index]
            child_data = CHILDREN[child_index]
            
            # Select a moral (rotate through the list)
            moral = MORALS[i % len(MORALS)]
            
            # Select a model (rotate through the list)
            model = MODELS[i % len(MODELS)]
            
            # Select a language (rotate through the list)
            language = LANGUAGES[i % len(LANGUAGES)]
            
            # Select a story type (rotate through the list)
            story_type = STORY_TYPES[i % len(STORY_TYPES)]
            
            # Create a task for generating this story
            task = generate_single_story(openrouter_client, supabase_client, child, child_data, moral, model, language, story_type, i)
            tasks.append(task)
        tasks_creation_duration = time.time() - tasks_creation_start
        logger.info(f"Created 10 story generation tasks in {tasks_creation_duration:.2f}s")
        
        # Execute all tasks concurrently
        story_execution_start = time.time()
        generated_stories = await asyncio.gather(*tasks, return_exceptions=True)
        story_execution_duration = time.time() - story_execution_start
        
        # Filter out any exceptions
        successful_stories = [story for story in generated_stories if not isinstance(story, Exception)]
        
        logger.info(f"Successfully generated and saved {len(successful_stories)} stories in {story_execution_duration:.2f}s!")
        story_generation_duration = time.time() - story_generation_start
        logger.info(f"Total story generation process took {story_generation_duration:.2f}s")
        
        rating_start = time.time()
        # Demonstrate rating functionality by adding random ratings to some stories
        logger.info("Adding ratings to stories...")
        rated_count = 0
        rating_process_start = time.time()
        for story in successful_stories:
            rating_story_start = time.time()
            # Randomly rate about half of the stories
            if random.choice([True, False]):
                try:
                    rating = random.randint(1, 10)
                    updated_story = await supabase_client.update_story_rating(story.id, rating)
                    rating_story_duration = time.time() - rating_story_start
                    if updated_story:
                        logger.info(f"Rated story '{story.title}' with {rating}/10 in {rating_story_duration:.2f}s")
                        rated_count += 1
                except Exception as e:
                    rating_story_duration = time.time() - rating_story_start
                    logger.error(f"Error rating story {story.id} in {rating_story_duration:.2f}s: {e}")
        rating_process_duration = time.time() - rating_process_start
        logger.info(f"Rating process completed in {rating_process_duration:.2f}s")
        rating_duration = time.time() - rating_start
        logger.info(f"Successfully rated {rated_count} stories in {rating_duration:.2f}s!")
        
        # Display summary
        summary_start = time.time()
        logger.info("Summary of generated stories:")
        for i, story in enumerate(successful_stories, 1):
            model_info = story.model_used if story.model_used else "Unknown"
            rating_info = f", Rating: {story.rating}/10" if story.rating else ""
            story_type_info = getattr(story, 'story_type', 'child')  # Default to 'child' for backward compatibility
            
            # Add hero information for hero and combined stories
            if story_type_info in ["hero", "combined"] and hasattr(story, 'hero_name') and story.hero_name:
                hero_info = f", Hero: {story.hero_name}"
            else:
                hero_info = ""
            
            logger.info(f"  {i}. {story.title} (Type: {story_type_info}, Moral: {story.moral}, Child: {story.child_name}{hero_info}, Model: {model_info}, Language: {story.language.value}{rating_info})")
        
        summary_duration = time.time() - summary_start
        logger.info(f"Summary display completed in {summary_duration:.2f}s")
        
        total_duration = time.time() - start_time
        logger.info(f"Entire process completed in {total_duration:.2f}s")
            
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)


async def generate_single_story(openrouter_client, supabase_client, child, child_data, moral, model, language, story_type, index):
    """Generate a single story asynchronously."""
    story_start_time = time.time()
    story_type_display = "combined" if story_type == "combined" else ("hero" if story_type == "hero" else "child")
    logger.info(f"Generating {story_type_display} story {index+1}/10 for {child.name} with moral '{moral}' using {model.value} in {language.value}...")
    
    try:
        # Create prompt and get hero entity if applicable
        prompt_start = time.time()
        prompt, hero_entity = await create_story_prompt(child_data, moral, language, story_type, index)
        prompt_duration = time.time() - prompt_start
        logger.info(f"Prompt creation took {prompt_duration:.2f}s")
        
        # Generate story content with retry functionality
        story_gen_start = time.time()
        result = await openrouter_client.generate_story(
            prompt, 
            model=model, 
            max_tokens=500,
            max_retries=3,
            retry_delay=1.0
        )
        story_gen_duration = time.time() - story_gen_start
        logger.info(f"Story generation took {story_gen_duration:.2f}s")
        
        # Clean the content to remove formatting markers
        cleaned_content = clean_story_content(result.content)
        
        # Extract title (first line or create one)
        title_extraction_start = time.time()
        lines = cleaned_content.strip().split('\n')
        title = lines[0].replace('#', '').strip() if lines and lines[0].strip() else f"{child.name}'s Adventure"
        title_extraction_duration = time.time() - title_extraction_start
        logger.info(f"Title extraction took {title_extraction_duration:.2f}s")
        
        # Generate summary
        summary_start = time.time()
        summary = ""
        try:
            if language == Language.RUSSIAN:
                summary_prompt = f"""Создай краткое резюме этой сказки в 2-3 предложениях. Резюме должно передавать основную сюжетную линию и главную мораль истории.

Название: {title}

Сказка:
{cleaned_content}

Резюме (2-3 предложения):"""
            else:
                summary_prompt = f"""Create a brief summary of this story in 2-3 sentences. The summary should convey the main plot and moral of the story.

Title: {title}

Story:
{cleaned_content}

Summary (2-3 sentences):"""
            
            summary_result = await openrouter_client.generate_story(
                summary_prompt,
                model=OpenRouterModel.GPT_4O_MINI,
                max_tokens=200,
                temperature=0.5,
                use_langgraph=False
            )
            summary = summary_result.content.strip().replace("**", "").replace("*", "").strip()
            logger.info(f"Summary generated in {time.time() - summary_start:.2f}s")
        except Exception as e:
            logger.warning(f"Failed to generate summary: {str(e)}")
            summary = ""
        
        # Format datetime for JSON serialization
        datetime_formatting_start = time.time()
        now_iso = datetime.now().isoformat()
        datetime_formatting_duration = time.time() - datetime_formatting_start
        logger.info(f"DateTime formatting took {datetime_formatting_duration:.2f}s")
        
        # Generate audio if requested
        audio_file_url = None
        if GENERATE_AUDIO:
            audio_start = time.time()
            try:
                # Initialize ElevenLabs client
                elevenlabs_init_start = time.time()
                elevenlabs_client = ElevenLabsProvider()
                elevenlabs_init_duration = time.time() - elevenlabs_init_start
                logger.info(f"ElevenLabs client initialized in {elevenlabs_init_duration:.2f}s")
                
                # Generate speech from the story content
                speech_gen_start = time.time()
                audio_data = await elevenlabs_client.generate_speech(
                    text=cleaned_content,
                    language=language.value
                )
                speech_gen_duration = time.time() - speech_gen_start
                logger.info(f"Speech generation took {speech_gen_duration:.2f}s")
                
                if audio_data:
                    # Upload audio file to Supabase storage
                    upload_start = time.time()
                    async_supabase_client = AsyncSupabaseClient()
                    audio_file_url = await async_supabase_client.upload_audio_file(
                        file_data=audio_data,
                        filename=f"{uuid.uuid4()}.mp3",
                        story_id=child.id
                    )
                    upload_duration = time.time() - upload_start
                    
                    if audio_file_url:
                        logger.info(f"Audio file uploaded successfully: {audio_file_url} in {upload_duration:.2f}s")
                    else:
                        logger.warning(f"Failed to upload audio file to Supabase storage in {upload_duration:.2f}s")
                else:
                    logger.warning("Failed to generate audio")
                    
            except Exception as e:
                audio_duration = time.time() - audio_start
                logger.error(f"Error generating or uploading audio in {audio_duration:.2f}s: {str(e)}", exc_info=True)
            audio_duration = time.time() - audio_start
            logger.info(f"Audio processing completed in {audio_duration:.2f}s")
        
        # Prepare hero fields if story type is hero or combined
        hero_prep_start = time.time()
        hero_id = None
        hero_name = None
        hero_gender = None
        hero_appearance = None
        relationship_description = None
        
        if story_type in ["hero", "combined"] and hero_entity:
            hero_id = hero_entity.id
            hero_name = hero_entity.name
            hero_gender = hero_entity.gender if isinstance(hero_entity.gender, str) else hero_entity.gender.value
            hero_appearance = hero_entity.appearance
            
            # Add relationship description for combined stories
            if story_type == "combined":
                if language == Language.ENGLISH:
                    relationship_description = f"{child.name} meets the legendary {hero_entity.name}"
                else:  # Russian
                    relationship_description = f"{child.name} встречает легендарного героя {hero_entity.name}"
        hero_prep_duration = time.time() - hero_prep_start
        logger.info(f"Hero field preparation took {hero_prep_duration:.2f}s")
        
        # Create StoryDB object with hero fields
        story_creation_start = time.time()
        story = StoryDB(
            title=title,
            content=cleaned_content,
            summary=summary,
            moral=moral,
            story_type=story_type,
            child_id=child.id,
            child_name=child.name,
            child_age=child.age,
            child_gender=child.gender,
            child_interests=child.interests,
            hero_id=hero_id,
            hero_name=hero_name,
            hero_gender=hero_gender,
            hero_appearance=hero_appearance,
            relationship_description=relationship_description,
            model_used=model.value,
            full_response=result.full_response,
            language=language,
            audio_file_url=audio_file_url,
            created_at=now_iso,
            updated_at=now_iso
        )
        story_creation_duration = time.time() - story_creation_start
        logger.info(f"Story object creation took {story_creation_duration:.2f}s")
        
        # Save to database
        story_save_start = time.time()
        saved_story = await supabase_client.save_story(story)
        story_save_duration = time.time() - story_save_start
        logger.info(f"Story saved with ID: {saved_story.id}, Type: {story_type} in {story_save_duration:.2f}s")
        
        story_total_duration = time.time() - story_start_time
        logger.info(f"Total story generation process took {story_total_duration:.2f}s")
        return saved_story
        
    except Exception as e:
        logger.error(f"Error generating story {index+1}: {e}")
        raise  # Re-raise the exception to be caught by gather


if __name__ == "__main__":
    asyncio.run(generate_sample_stories())