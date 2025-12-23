#!/usr/bin/env python3
"""Script to populate the heroes table in Supabase with predefined heroes using the Supabase client."""

import os
import sys
import asyncio
from datetime import datetime
from dotenv import load_dotenv

# Add the src directory to the path so we can import our modules
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.supabase_client import SupabaseClient
from src.models import HeroDB, Language
from src.prompts import Heroes


async def populate_heroes_table():
    """Populate the heroes table with predefined heroes using the Supabase client."""
    try:
        print("Populating heroes table with predefined heroes...")
        
        # Initialize Supabase client
        supabase_client = SupabaseClient()
        
        # Get all predefined heroes
        english_heroes = Heroes.get_all_english_heroes()
        russian_heroes = Heroes.get_all_russian_heroes()
        
        all_heroes = english_heroes + russian_heroes
        print(f"Found {len(all_heroes)} heroes to populate")
        
        # Save each hero to the database
        saved_heroes = []
        for i, hero in enumerate(all_heroes):
            try:
                # Convert prompt Hero to database HeroDB
                hero_db = HeroDB(
                    name=hero.name,
                    gender=hero.gender,
                    appearance=hero.appearance,
                    personality_traits=hero.personality_traits,
                    interests=hero.interests,
                    strengths=hero.strengths,
                    language=hero.language,
                    created_at=datetime.now(),
                    updated_at=datetime.now()
                )
                
                # Save to database
                saved_hero = supabase_client.save_hero(hero_db)
                saved_heroes.append(saved_hero)
                print(f"✓ Saved hero: {saved_hero.name} (ID: {saved_hero.id})")
            except Exception as e:
                print(f"✗ Error saving hero {hero.name}: {e}")
        
        print(f"\nSuccessfully saved {len(saved_heroes)} heroes to the database!")
        
        # Verify by retrieving all heroes
        print("\nVerifying saved heroes...")
        retrieved_heroes = supabase_client.get_all_heroes()
        print(f"Retrieved {len(retrieved_heroes)} heroes from the database:")
        
        # Group by language for better display
        english_count = sum(1 for h in retrieved_heroes if h.language == Language.ENGLISH)
        russian_count = sum(1 for h in retrieved_heroes if h.language == Language.RUSSIAN)
        
        print(f"  English heroes: {english_count}")
        print(f"  Russian heroes: {russian_count}")
        
        # Show details of first few heroes
        for hero in retrieved_heroes[:5]:  # Show first 5
            print(f"  - {hero.name} ({hero.gender}, {hero.language.value})")
        
        if len(retrieved_heroes) > 5:
            print(f"  ... and {len(retrieved_heroes) - 5} more")
        
        return saved_heroes
        
    except Exception as e:
        print(f"Error populating heroes table: {e}")
        raise


async def main():
    """Main function to populate the heroes table."""
    try:
        print("Starting heroes table population...")
        print("=" * 50)
        
        saved_heroes = await populate_heroes_table()
        
        print("\n" + "=" * 50)
        print("✅ Heroes table population completed successfully!")
        print(f"Total heroes saved: {len(saved_heroes)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error in main execution: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    if success:
        sys.exit(0)
    else:
        sys.exit(1)