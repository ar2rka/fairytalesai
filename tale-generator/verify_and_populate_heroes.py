"""Verify and populate hero data in the database."""

import sys
from src.infrastructure.persistence.models import HeroDB
from src.domain.value_objects import Language, Gender
from src.supabase_client import SupabaseClient
from datetime import datetime


def check_hero_count():
    """Check the number of heroes in the database."""
    try:
        client = SupabaseClient()
        
        # Get all heroes
        response = client.supabase.table('heroes').select('*').execute()
        all_heroes = response.data if response.data else []
        
        # Count by language
        en_heroes = [h for h in all_heroes if h.get('language') == 'en']
        ru_heroes = [h for h in all_heroes if h.get('language') == 'ru']
        
        print(f"\n{'='*60}")
        print(f"Hero Database Status")
        print(f"{'='*60}")
        print(f"Total heroes: {len(all_heroes)}")
        print(f"English heroes: {len(en_heroes)}")
        print(f"Russian heroes: {len(ru_heroes)}")
        print(f"{'='*60}\n")
        
        if len(en_heroes) > 0:
            print("Sample English Heroes:")
            for hero in en_heroes[:3]:
                print(f"  - {hero['name']} ({hero['gender']}): {hero['appearance'][:50]}...")
        
        if len(ru_heroes) > 0:
            print("\nSample Russian Heroes:")
            for hero in ru_heroes[:3]:
                print(f"  - {hero['name']} ({hero['gender']}): {hero['appearance'][:50]}...")
        
        print()
        
        return len(all_heroes), len(en_heroes), len(ru_heroes)
        
    except Exception as e:
        print(f"Error checking hero count: {str(e)}")
        return 0, 0, 0


def populate_sample_heroes():
    """Populate the database with sample heroes if needed."""
    
    client = SupabaseClient()
    
    # English heroes
    english_heroes = [
        {
            "name": "Captain Wonder",
            "age": 35,
            "gender": "male",
            "appearance": "A brave captain with a golden compass and a weathered blue coat",
            "personality_traits": ["brave", "wise", "adventurous", "kind"],
            "interests": ["exploration", "navigation", "helping others"],
            "strengths": ["leadership", "problem-solving", "courage"],
            "language": "en"
        },
        {
            "name": "Luna the Starkeeper",
            "age": 28,
            "gender": "female",
            "appearance": "A mystical guardian with silver hair and robes decorated with constellations",
            "personality_traits": ["wise", "gentle", "mysterious", "patient"],
            "interests": ["astronomy", "magic", "teaching"],
            "strengths": ["wisdom", "magic", "guidance"],
            "language": "en"
        },
        {
            "name": "Professor Spark",
            "age": 45,
            "gender": "male",
            "appearance": "An eccentric inventor with wild white hair and goggles",
            "personality_traits": ["curious", "intelligent", "enthusiastic", "creative"],
            "interests": ["invention", "science", "problem-solving"],
            "strengths": ["innovation", "technology", "teaching"],
            "language": "en"
        },
        {
            "name": "Aria the Forest Guardian",
            "age": 30,
            "gender": "female",
            "appearance": "A nature guardian with green eyes and clothing made of leaves and flowers",
            "personality_traits": ["caring", "gentle", "brave", "wise"],
            "interests": ["nature", "animals", "conservation"],
            "strengths": ["nature magic", "healing", "communication with animals"],
            "language": "en"
        },
        {
            "name": "Sir Brightshield",
            "age": 40,
            "gender": "male",
            "appearance": "A noble knight with shining armor and a shield that glows with light",
            "personality_traits": ["honorable", "brave", "protective", "just"],
            "interests": ["protecting others", "justice", "training"],
            "strengths": ["combat", "courage", "honor"],
            "language": "en"
        },
        {
            "name": "Maya the Dreamweaver",
            "age": 26,
            "gender": "female",
            "appearance": "A mystical being with flowing purple robes and eyes that shimmer like dreams",
            "personality_traits": ["imaginative", "kind", "mysterious", "inspiring"],
            "interests": ["dreams", "creativity", "helping children"],
            "strengths": ["dream magic", "inspiration", "creativity"],
            "language": "en"
        }
    ]
    
    # Russian heroes
    russian_heroes = [
        {
            "name": "Капитан Чудо",
            "age": 35,
            "gender": "male",
            "appearance": "Отважный капитан с золотым компасом в потёртом синем плаще",
            "personality_traits": ["храбрый", "мудрый", "отважный", "добрый"],
            "interests": ["исследования", "навигация", "помощь другим"],
            "strengths": ["лидерство", "решение проблем", "храбрость"],
            "language": "ru"
        },
        {
            "name": "Луна Хранительница Звёзд",
            "age": 28,
            "gender": "female",
            "appearance": "Мистическая хранительница с серебряными волосами и одеждой, украшенной созвездиями",
            "personality_traits": ["мудрая", "нежная", "таинственная", "терпеливая"],
            "interests": ["астрономия", "магия", "обучение"],
            "strengths": ["мудрость", "магия", "наставничество"],
            "language": "ru"
        },
        {
            "name": "Профессор Искра",
            "age": 45,
            "gender": "male",
            "appearance": "Эксцентричный изобретатель с растрёпанными белыми волосами и очками",
            "personality_traits": ["любопытный", "умный", "энтузиаст", "творческий"],
            "interests": ["изобретения", "наука", "решение задач"],
            "strengths": ["инновации", "технологии", "обучение"],
            "language": "ru"
        },
        {
            "name": "Ария Хранительница Леса",
            "age": 30,
            "gender": "female",
            "appearance": "Хранительница природы с зелёными глазами в одежде из листьев и цветов",
            "personality_traits": ["заботливая", "нежная", "смелая", "мудрая"],
            "interests": ["природа", "животные", "сохранение"],
            "strengths": ["магия природы", "исцеление", "общение с животными"],
            "language": "ru"
        },
        {
            "name": "Сэр Светлый Щит",
            "age": 40,
            "gender": "male",
            "appearance": "Благородный рыцарь в сияющих доспехах со щитом, излучающим свет",
            "personality_traits": ["благородный", "храбрый", "защитник", "справедливый"],
            "interests": ["защита других", "справедливость", "тренировки"],
            "strengths": ["боевые навыки", "храбрость", "честь"],
            "language": "ru"
        },
        {
            "name": "Майя Ткачиха Снов",
            "age": 26,
            "gender": "female",
            "appearance": "Мистическое существо в фиолетовых одеждах с глазами, сверкающими как сны",
            "personality_traits": ["творческая", "добрая", "таинственная", "вдохновляющая"],
            "interests": ["сны", "творчество", "помощь детям"],
            "strengths": ["магия снов", "вдохновение", "креативность"],
            "language": "ru"
        }
    ]
    
    print("\nPopulating heroes...")
    
    created_count = 0
    
    for hero_data in english_heroes + russian_heroes:
        try:
            # Check if hero already exists
            response = client.supabase.table('heroes').select('*').eq('name', hero_data['name']).execute()
            
            if response.data and len(response.data) > 0:
                print(f"  ⊘ Hero '{hero_data['name']}' already exists, skipping...")
                continue
            
            # Insert new hero
            now = datetime.utcnow().isoformat()
            hero_insert = {
                **hero_data,
                "created_at": now,
                "updated_at": now,
                "user_id": None  # Public heroes
            }
            
            insert_response = client.supabase.table('heroes').insert(hero_insert).execute()
            
            if insert_response.data:
                print(f"  ✓ Created hero: {hero_data['name']} ({hero_data['language']})")
                created_count += 1
            else:
                print(f"  ✗ Failed to create hero: {hero_data['name']}")
                
        except Exception as e:
            print(f"  ✗ Error creating hero {hero_data['name']}: {str(e)}")
    
    print(f"\n✓ Created {created_count} new heroes\n")
    return created_count


def main():
    """Main function to verify and populate heroes."""
    print("\n" + "="*60)
    print("Hero Database Verification and Population Tool")
    print("="*60)
    
    # Check current state
    total, en_count, ru_count = check_hero_count()
    
    # Determine if we need to populate
    min_heroes_per_language = 5
    
    needs_population = (en_count < min_heroes_per_language or 
                       ru_count < min_heroes_per_language)
    
    if needs_population:
        print(f"\n⚠️  Database needs more heroes!")
        print(f"   Minimum required: {min_heroes_per_language} per language")
        print(f"   Current: EN={en_count}, RU={ru_count}")
        
        response = input("\nWould you like to populate sample heroes? (y/n): ")
        
        if response.lower() == 'y':
            created = populate_sample_heroes()
            
            # Check again
            total, en_count, ru_count = check_hero_count()
            
            print(f"\n{'='*60}")
            print(f"Final Status")
            print(f"{'='*60}")
            print(f"Total heroes: {total}")
            print(f"English heroes: {en_count} {'✓' if en_count >= min_heroes_per_language else '⚠️'}")
            print(f"Russian heroes: {ru_count} {'✓' if ru_count >= min_heroes_per_language else '⚠️'}")
            print(f"{'='*60}\n")
        else:
            print("\nSkipping hero population.")
    else:
        print(f"\n✓ Database has sufficient heroes for both languages!")
        print(f"   EN: {en_count}/{min_heroes_per_language}")
        print(f"   RU: {ru_count}/{min_heroes_per_language}\n")
    
    return 0 if (en_count >= min_heroes_per_language and ru_count >= min_heroes_per_language) else 1


if __name__ == "__main__":
    sys.exit(main())
