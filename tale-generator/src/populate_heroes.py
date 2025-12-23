#!/usr/bin/env python3
"""Script to populate the heroes table in Supabase with predefined heroes."""

import os
import sys
import asyncio
from datetime import datetime
from dotenv import load_dotenv

# Add the src directory to the path so we can import our modules
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.supabase_client import SupabaseClient
from src.models import HeroDB
from src.prompts import Heroes


async def populate_heroes_table():
    """Populate the heroes table with predefined heroes."""
    try:
        # Initialize Supabase client
        supabase_client = SupabaseClient()
        
        print("Populating heroes table with predefined heroes...")
        
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
                # Use the language from the predefined hero
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
        
        for hero in retrieved_heroes:
            print(f"- {hero.name} ({hero.gender})")
        
        return saved_heroes
        
    except Exception as e:
        print(f"Error populating heroes table: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(populate_heroes_table())