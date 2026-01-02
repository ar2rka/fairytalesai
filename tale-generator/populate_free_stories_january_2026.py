#!/usr/bin/env python3
"""Script to populate daily_free_stories table with stories for every day in January 2026."""

import os
import sys
import logging
from typing import List
from datetime import datetime, timedelta
from dotenv import load_dotenv

# Add the src directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__)))

from src.supabase_client import SupabaseClient
from src.infrastructure.persistence.models import DailyFreeStoryDB

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


def generate_story_stub(
    category: str, 
    language: str, 
    story_number: int, 
    day: int, 
    story_date: str
) -> DailyFreeStoryDB:
    """Generate a story stub (mock data) for given category, language, and story number.
    
    Args:
        category: Age category ('2-3', '3-5', '5-7')
        language: Language code ('en', 'ru')
        story_number: Story number (1, 2, or 3)
        day: Day of month (1-31)
        story_date: Date in YYYY-MM-DD format
        
    Returns:
        DailyFreeStoryDB object with mock data
    """
    if language == 'ru':
        titles = {
            '2-3': [
                f"История про маленького друга - День {day}",
                f"Приключения пушистого зверька - День {day}",
                f"Сказка о добром медвежонке - День {day}"
            ],
            '3-5': [
                f"Волшебное путешествие - День {day}",
                f"Приключения в сказочном лесу - День {day}",
                f"История о храбром герое - День {day}"
            ],
            '5-7': [
                f"Тайна волшебного королевства - День {day}",
                f"Приключения юного исследователя - День {day}",
                f"Сказка о дружбе и смелости - День {day}"
            ]
        }
        names = {
            '2-3': [
                f"Маленький друг",
                f"Пушистый зверек",
                f"Добрый медвежонок"
            ],
            '3-5': [
                f"Волшебное путешествие",
                f"Сказочный лес",
                f"Храбрый герой"
            ],
            '5-7': [
                f"Тайна королевства",
                f"Юный исследователь",
                f"Дружба и смелость"
            ]
        }
        contents = {
            '2-3': [
                f"Это была чудесная история про маленького друга, который жил в красивом домике. Каждый день он встречал новых друзей и вместе они играли весело. История произошла {day} января 2026 года.",
                f"Однажды пушистый зверек отправился на прогулку. Он встретил много интересных животных и подружился с ними. Все вместе они провели замечательный день {day} января 2026 года.",
                f"Жил-был добрый медвежонок, который очень любил помогать другим. Он всегда находил время, чтобы поддержать своих друзей. Эта история случилась {day} января 2026 года."
            ],
            '3-5': [
                f"В далекой стране началось волшебное путешествие. Герой отправился в путь, чтобы найти сокровище дружбы. Путешествие началось {day} января 2026 года и было полным приключений.",
                f"В сказочном лесу жили удивительные существа. Однажды они решили отправиться в большое приключение. Это случилось {day} января 2026 года, и с тех пор лес стал еще более волшебным.",
                f"Храбрый герой услышал о проблеме, которая требовала решения. Не раздумывая, он отправился на помощь. Его подвиг произошел {day} января 2026 года и вдохновил многих."
            ],
            '5-7': [
                f"В волшебном королевстве была тайна, которую никто не мог разгадать. Юный принц решил найти ответ и отправился в опасное путешествие. Начало приключения - {day} января 2026 года.",
                f"Юный исследователь нашел старую карту, которая указывала на скрытое сокровище. Он собрал команду друзей и отправился в путь. Экспедиция началась {day} января 2026 года.",
                f"Дружба и смелость - вот что помогло героям преодолеть все препятствия. Они научились работать вместе и поддерживать друг друга. Эта история началась {day} января 2026 года."
            ]
        }
        morals = {
            '2-3': [
                "Дружба делает нас счастливыми",
                "Важно быть добрым к другим",
                "Помогать друзьям - это хорошо"
            ],
            '3-5': [
                "Дружба - это самое ценное сокровище",
                "Приключения учат нас быть смелыми",
                "Смелость помогает преодолевать трудности"
            ],
            '5-7': [
                "Тайны можно разгадать, если не сдаваться",
                "Исследования открывают новые горизонты",
                "Дружба и смелость помогают преодолеть любые препятствия"
            ]
        }
    else:  # English
        titles = {
            '2-3': [
                f"Story About a Little Friend - Day {day}",
                f"Adventures of a Fluffy Animal - Day {day}",
                f"Tale of a Kind Bear - Day {day}"
            ],
            '3-5': [
                f"Magic Journey - Day {day}",
                f"Adventures in the Fairy Forest - Day {day}",
                f"Story of a Brave Hero - Day {day}"
            ],
            '5-7': [
                f"Mystery of the Magic Kingdom - Day {day}",
                f"Adventures of a Young Explorer - Day {day}",
                f"Tale of Friendship and Courage - Day {day}"
            ]
        }
        names = {
            '2-3': [
                "Little Friend",
                "Fluffy Animal",
                "Kind Bear"
            ],
            '3-5': [
                "Magic Journey",
                "Fairy Forest",
                "Brave Hero"
            ],
            '5-7': [
                "Mystery Kingdom",
                "Young Explorer",
                "Friendship and Courage"
            ]
        }
        contents = {
            '2-3': [
                f"This was a wonderful story about a little friend who lived in a beautiful house. Every day he met new friends and they played together happily. The story happened on January {day}, 2026.",
                f"Once upon a time, a fluffy animal went for a walk. He met many interesting animals and became friends with them. Together they spent a wonderful day on January {day}, 2026.",
                f"There was a kind bear who loved to help others. He always found time to support his friends. This story happened on January {day}, 2026."
            ],
            '3-5': [
                f"In a distant land, a magic journey began. The hero set off to find the treasure of friendship. The journey started on January {day}, 2026 and was full of adventures.",
                f"In the fairy forest lived amazing creatures. One day they decided to go on a great adventure. This happened on January {day}, 2026, and since then the forest became even more magical.",
                f"A brave hero heard about a problem that needed solving. Without hesitation, he went to help. His feat happened on January {day}, 2026 and inspired many."
            ],
            '5-7': [
                f"In the magic kingdom there was a mystery that no one could solve. A young prince decided to find the answer and set off on a dangerous journey. The adventure began on January {day}, 2026.",
                f"A young explorer found an old map that pointed to hidden treasure. He gathered a team of friends and set off. The expedition began on January {day}, 2026.",
                f"Friendship and courage - that's what helped the heroes overcome all obstacles. They learned to work together and support each other. This story began on January {day}, 2026."
            ]
        }
        morals = {
            '2-3': [
                "Friendship makes us happy",
                "It's important to be kind to others",
                "Helping friends is good"
            ],
            '3-5': [
                "Friendship is the most valuable treasure",
                "Adventures teach us to be brave",
                "Courage helps overcome difficulties"
            ],
            '5-7': [
                "Mysteries can be solved if we don't give up",
                "Explorations open new horizons",
                "Friendship and courage help overcome any obstacles"
            ]
        }
    
    title = titles[category][story_number - 1]
    name = names[category][story_number - 1]
    content = contents[category][story_number - 1]
    moral = morals[category][story_number - 1]
    
    return DailyFreeStoryDB(
        story_date=story_date,
        title=title,
        name=name,
        content=content,
        moral=moral,
        age_category=category,
        language=language,
        is_active=True
    )


def get_january_2026_dates() -> List[datetime]:
    """Get all dates in January 2026.
    
    Returns:
        List of datetime objects for each day in January 2026
    """
    dates = []
    start_date = datetime(2026, 1, 1, 0, 0, 0)  # Start at noon for each day
    current_date = start_date
    
    # January has 31 days
    for _ in range(31):
        dates.append(current_date)
        current_date += timedelta(days=1)
    
    return dates


def insert_free_stories_for_january(
    client: SupabaseClient,
    dates: List[datetime]
) -> None:
    """Insert story stubs into daily_free_stories table for each day in January 2026.
    
    Args:
        client: Supabase client
        dates: List of dates for January 2026
    """
    stories_to_insert = []
    
    # For each day in January
    for day_index, target_date in enumerate(dates):
        day_number = day_index + 1
        story_date_str = target_date.strftime('%Y-%m-%d')
        logger.info(f"\nProcessing day {day_number}/31: {story_date_str}")
        
        # For each age category
        for category in ['2-3', '3-5', '5-7']:
            # For each language
            for language in ['en', 'ru']:
                # Create 3 stories for this day, category, and language
                for story_number in range(1, 4):
                    daily_story = generate_story_stub(
                        category, 
                        language, 
                        story_number, 
                        day_number, 
                        story_date_str
                    )
                    daily_story.created_at = target_date
                    stories_to_insert.append(daily_story)
                    logger.info(f"  ✓ Created: {daily_story.title[:50]}... (category: {category}, lang: {language}, story #{story_number})")
    
    if not stories_to_insert:
        logger.error("No stories to insert!")
        return
    
    logger.info(f"\n{'='*60}")
    logger.info(f"Inserting {len(stories_to_insert)} stories into daily_free_stories table...")
    logger.info(f"{'='*60}\n")
    
    # Insert stories into database in batches
    batch_size = 50
    inserted_count = 0
    failed_count = 0
    
    for i in range(0, len(stories_to_insert), batch_size):
        batch = stories_to_insert[i:i + batch_size]
        batch_dicts = []
        
        for daily_story in batch:
            try:
                # Convert to dict for insertion
                story_dict = daily_story.model_dump(exclude={'id'})
                
                # Ensure created_at is in ISO format
                if story_dict.get('created_at'):
                    if hasattr(story_dict['created_at'], 'isoformat'):
                        story_dict['created_at'] = story_dict['created_at'].isoformat()

                if not story_dict.get('updated_at'):
                        story_dict['updated_at'] = story_dict['created_at']

                batch_dicts.append(story_dict)
            except Exception as e:
                logger.error(f"  ✗ Error preparing story {daily_story.title[:50]}...: {str(e)}")
                failed_count += 1
        
        if batch_dicts:
            try:
                # Insert batch
                response = client.client.table("daily_free_stories").insert(batch_dicts).execute()
                
                if response.data:
                    batch_inserted = len(response.data)
                    inserted_count += batch_inserted
                    logger.info(f"  ✓ Inserted batch: {batch_inserted} stories (total: {inserted_count}/{len(stories_to_insert)})")
                else:
                    logger.error(f"  ✗ Failed to insert batch (no data returned)")
                    failed_count += len(batch_dicts)
            except Exception as e:
                logger.error(f"  ✗ Error inserting batch: {str(e)}")
                failed_count += len(batch_dicts)
    
    logger.info(f"\n{'='*60}")
    logger.info(f"Insertion complete!")
    logger.info(f"  Successfully inserted: {inserted_count}")
    logger.info(f"  Failed: {failed_count}")
    logger.info(f"{'='*60}")


def main():
    """Main function."""
    try:
        logger.info("=" * 60)
        logger.info("Populating daily_free_stories table for January 2026")
        logger.info("=" * 60)
        
        # Initialize client
        client = SupabaseClient()
        
        # Get dates for January 2026
        dates = get_january_2026_dates()
        logger.info(f"Will create stories for {len(dates)} days in January 2026")
        
        # Calculate total stories: 31 days × 3 categories × 2 languages × 3 stories = 558 stories
        total_stories = len(dates) * 3 * 2 * 3
        logger.info(f"Will create {total_stories} stories (31 days × 3 categories × 2 languages × 3 stories per combination)")
        
        # Insert stories (using stubs, no database fetching)
        insert_free_stories_for_january(client, dates)
        
        logger.info("\n" + "=" * 60)
        logger.info("Done!")
        logger.info("=" * 60)
        
    except Exception as e:
        logger.error(f"Error populating free stories: {str(e)}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()

