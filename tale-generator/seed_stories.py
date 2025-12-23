"""Script to seed the database with sample stories without requiring OpenRouter."""

import logging
from src.supabase_client import SupabaseClient
from src.models import StoryDB, ChildDB, Language
from src.openrouter_client import OpenRouterModel
from datetime import datetime
import random

# Set up logger
logger = logging.getLogger("tale_generator.seed")

# Sample stories data - English
ENGLISH_STORIES = [
    {
        "title": "The Kind Little Dragon",
        "content": "Once upon a time, there was a little dragon named Spark who lived in a cave near a village. Unlike other dragons who breathed fire, Spark could only breathe warm, gentle air. The other dragons teased him, but Spark didn't mind. One day, the village caught fire, and Spark used his warm breath to help put out the flames and save everyone. The villagers realized that Spark's gentle nature was actually his greatest strength. From that day on, Spark was celebrated as the village's hero, teaching everyone that kindness is more powerful than strength.",
        "moral": "kindness"
    },
    {
        "title": "The Honest Rabbit",
        "content": "Benny the rabbit found a shiny coin in the forest. He was excited because he could buy the biggest carrot at the market. But as he hopped home, he heard the old tortoise crying. 'I lost my coin for medicine,' sobbed the tortoise. Benny recognized the coin as the one he had found. Even though he really wanted that carrot, Benny gave the coin to the tortoise. The tortoise was so grateful that he shared his garden with Benny. Benny learned that being honest made him feel happier than any carrot ever could.",
        "moral": "honesty"
    },
    {
        "title": "Brave Little Squirrel",
        "content": "Nutkin the squirrel was the smallest in his family and often felt scared. When a fierce storm hit the forest and trapped his baby sister in a fallen tree, all the bigger animals were too afraid to help. Despite his fear, Nutkin climbed the treacherous branches and rescued his sister. His family was amazed at his courage. Nutkin learned that bravery isn't about not being scared—it's about doing what's right even when you're afraid.",
        "moral": "bravery"
    },
    {
        "title": "The Three Little Fish Friends",
        "content": "Coral, Pearl, and Shell were three fish who lived in different parts of the ocean. When a big shark threatened their reef, each fish had a different idea about how to solve the problem. They argued at first, but then realized that by combining their different strengths—Coral's speed, Pearl's intelligence, and Shell's knowledge of hiding places—they could protect their home together. Working as a team, they successfully drove away the shark and became the best of friends. They learned that friendship and teamwork can overcome any challenge.",
        "moral": "friendship"
    },
    {
        "title": "The Persistent Caterpillar",
        "content": "Crawly was a caterpillar who dreamed of flying. Everyone laughed at him because caterpillars don't have wings. But Crawly didn't give up. Day after day, he practiced moving in different ways and studied the birds who could fly. After many months of what seemed like slow progress, Crawly formed a cocoon. When he emerged, he had become a beautiful butterfly. His persistence had transformed him completely. Children learned that perseverance through difficult times can lead to amazing transformations.",
        "moral": "perseverance"
    }
]

# Sample stories data - Russian
RUSSIAN_STORIES = [
    {
        "title": "Добрый маленький дракон",
        "content": "Жил-был маленький дракончик по имени Искрёнок, который жил в пещере недалеко от деревни. В отличие от других драконов, которые дышали огнём, Искрёнок мог лишь дышать тёплым, ласковым воздухом. Другие драконы смеялись над ним, но Искрёнок не обижался. Однажды деревня загорелась, и Искрёнок своим тёплым дыханием помог потушить пламя и спасти всех. Жители деревни поняли, что доброта Искрёнка - его величайшая сила. С того дня Искрёнок стал героем деревни, научив всех, что доброта сильнее огня.",
        "moral": "kindness"
    },
    {
        "title": "Честный кролик",
        "content": "Кролик Бени нашёл блестящую монетку в лесу. Он обрадовался, ведь теперь мог купить самый большой овощ на рынке. Но по дороге домой услышал, как старая черепаха плачет. 'Я потеряла свою монету для лекарства,' - горько плакала черепаха. Бени узнал монету - это была та самая! Хоть ему очень хотелось овоща, он отдал монету черепахе. Черепаха была так благодарна, что поделилась с ним своим огородом. Бени понял, что честность делает его счастливее любого овоща.",
        "moral": "honesty"
    },
    {
        "title": "Храбрый белочек",
        "content": "Белочка Нуткин был самым маленьким в своей семье и часто боялся. Когда в лесу разбушевалась буря и завалило младшую сестренку упавшим деревом, все большие звери боялись помочь. Несмотря на свой страх, Нуткин взобрался по опасным веткам и спас сестренку. Его семья была поражена его храбростью. Нуткин понял, что храбрость - это не отсутствие страха, а умение делать правильное дело даже когда страшно.",
        "moral": "bravery"
    },
    {
        "title": "Три рыбки-подружки",
        "content": "Коралл, Жемчужина и Ракушка были тремя рыбками, живущими в разных частях океана. Когда большая акула угрожала их рифу, у каждой рыбки было свое решение проблемы. Сначала они поспорили, но потом поняли, что объединив свои силы - скорость Коралла, ум Жемчужины и знание укрытий Ракушки - они смогут защитить свой дом вместе. Работая командой, они успешно прогнали акулу и стали лучшими друзьями. Они узнали, что дружба и командная работа могут преодолеть любые трудности.",
        "moral": "friendship"
    },
    {
        "title": "Упорная гусеница",
        "content": "Гусеница Кроули мечтала летать. Все смеялись над ним, потому что у гусениц нет крыльев. Но Кроули не сдавался. День за днём он тренировался двигаться по-разному и изучал птиц, которые умеют летать. После многих месяцев, казавшихся медленным прогрессом, Кроули сделал кокон. Когда он вышел из него, он стал красивой бабочкой. Его настойчивость полностью изменила его. Дети узнали, что упорство в трудные времена может привести к удивительным превращениям.",
        "moral": "perseverance"
    }
]

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

# Sample models
MODELS = [
    OpenRouterModel.GPT_4O_MINI.value,
    OpenRouterModel.CLAUDE_3_HAIKU.value,
    OpenRouterModel.LLAMA_3_1_8B.value,
    OpenRouterModel.GEMMA_2_27B.value,
    OpenRouterModel.MIXTRAL_8X22B.value
]

# Languages
LANGUAGES = [
    Language.ENGLISH,
    Language.RUSSIAN
]

def seed_database():
    """Seed the database with sample stories."""
    try:
        logger.info("Seeding database with children...")
        
        # Initialize Supabase client
        client = SupabaseClient()
        
        # Save children to database
        saved_children = []
        for child_data in CHILDREN:
            try:
                child_db = ChildDB(
                    name=child_data["name"],
                    age=child_data["age"],
                    gender=child_data["gender"],
                    interests=child_data["interests"],
                    created_at=datetime.now().isoformat(),
                    updated_at=datetime.now().isoformat()
                )
                saved_child = client.save_child(child_db)
                saved_children.append(saved_child)
                logger.info(f"Seeded child: {saved_child.name} with ID: {saved_child.id}")
            except Exception as e:
                logger.error(f"Error seeding child {child_data['name']}: {e}")
        
        logger.info("Seeding database with sample stories...")
        
        # Create 10 stories by duplicating and varying the sample stories
        seeded_stories = []
        
        for i in range(10):
            # Select language
            language = LANGUAGES[i % len(LANGUAGES)]
            
            # Select appropriate stories based on language
            stories = ENGLISH_STORIES if language == Language.ENGLISH else RUSSIAN_STORIES
            
            # Select a sample story (rotate through the list)
            sample_story = stories[i % len(stories)]
            
            # Select a child (rotate through the list)
            child_index = i % len(saved_children)
            child = saved_children[child_index]
            child_data = CHILDREN[child_index]
            
            # Select a model (rotate through the list)
            model = MODELS[i % len(MODELS)]
            
            # Create story with child information
            story = StoryDB(
                title=sample_story["title"],
                content=sample_story["content"],
                moral=sample_story["moral"],
                child_id=child.id,
                child_name=child.name,
                child_age=child.age,
                child_gender=child.gender,
                child_interests=child.interests,
                model_used=model,
                full_response=None,  # No full response for seeded stories
                language=language,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            )
            
            # Save to database
            saved_story = client.save_story(story)
            seeded_stories.append(saved_story)
            logger.info(f"Seeded story: {saved_story.title} for {saved_story.child_name} using {model} in {language.value}")
        
        logger.info(f"Successfully seeded {len(seeded_stories)} stories!")
        
        # Demonstrate rating functionality by adding random ratings to some stories
        logger.info("Adding ratings to stories...")
        rated_count = 0
        for story in seeded_stories:
            # Randomly rate about half of the stories
            if random.choice([True, False]):
                try:
                    rating = random.randint(1, 10)
                    updated_story = client.update_story_rating(story.id, rating)
                    if updated_story:
                        logger.info(f"Rated story '{story.title}' with {rating}/10")
                        rated_count += 1
                except Exception as e:
                    logger.error(f"Error rating story {story.id}: {e}")
        
        logger.info(f"Successfully rated {rated_count} stories!")
        
        # Display summary
        logger.info("Summary of seeded stories:")
        for i, story in enumerate(seeded_stories, 1):
            model_info = story.model_used if story.model_used else "Unknown"
            rating_info = f", Rating: {story.rating}/10" if story.rating else ""
            logger.info(f"  {i}. {story.title} (Moral: {story.moral}, Child: {story.child_name}, Model: {model_info}, Language: {story.language.value}{rating_info})")
            
    except Exception as e:
        logger.error(f"Error seeding database: {e}", exc_info=True)

if __name__ == "__main__":
    seed_database()