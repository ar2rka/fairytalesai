#!/usr/bin/env python3
"""Script to create the heroes table in Supabase."""

import os
import sys
from dotenv import load_dotenv
from supabase import create_client, Client
from supabase.client import ClientOptions

# Add the src directory to the path so we can import our modules
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.models import HeroDB
from src.prompts import Heroes


def create_heroes_table():
    """Create the heroes table in Supabase and populate it with predefined heroes."""
    # Load environment variables
    load_dotenv()
    
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        raise ValueError(
            "Supabase credentials are required. "
            "Set SUPABASE_URL and SUPABASE_KEY environment variables."
        )
    
    # Create client with schema specification
    client: Client = create_client(
        supabase_url=supabase_url,
        supabase_key=supabase_key,
        options=ClientOptions(
            postgrest_client_timeout=10,
            storage_client_timeout=10,
            schema="tales",
        )
    )
    
    print("Creating heroes table...")
    
    # Note: In a real Supabase environment, you would typically create the table
    # using SQL migrations or the Supabase dashboard. This script is for demonstration.
    # The table structure would be:
    # CREATE TABLE heroes (
    #     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    #     name TEXT NOT NULL,
    #     gender TEXT NOT NULL,
    #     appearance TEXT NOT NULL,
    #     personality_traits TEXT[] NOT NULL,
    #     interests TEXT[] NOT NULL,
    #     strengths TEXT[] NOT NULL,
    #     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    #     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    # );
    
    print("Heroes table structure:")
    print("- id (UUID, primary key)")
    print("- name (TEXT)")
    print("- gender (TEXT)")
    print("- appearance (TEXT)")
    print("- personality_traits (TEXT[])")
    print("- interests (TEXT[])")
    print("- strengths (TEXT[])")
    print("- language (TEXT)")
    print("- created_at (TIMESTAMP)")
    print("- updated_at (TIMESTAMP)")
    
    print("\nTo create this table in Supabase, run the following SQL:")
    print("""
CREATE TABLE heroes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    gender TEXT NOT NULL,
    appearance TEXT NOT NULL,
    personality_traits TEXT[] NOT NULL,
    interests TEXT[] NOT NULL,
    strengths TEXT[] NOT NULL,
    language TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
    """)
    
    # Show how to populate with predefined heroes
    print("\nPredefined heroes that can be added to the table:")
    
    # English heroes
    english_heroes = Heroes.get_all_english_heroes()
    print(f"\nEnglish heroes ({len(english_heroes)}):")
    for i, hero in enumerate(english_heroes):
        print(f"{i+1}. {hero.name}")
        print(f"   Gender: {hero.gender}")
        print(f"   Appearance: {hero.appearance}")
        print(f"   Personality traits: {', '.join(hero.personality_traits)}")
        print(f"   Interests: {', '.join(hero.interests)}")
        print(f"   Strengths: {', '.join(hero.strengths)}")
    
    # Russian heroes
    russian_heroes = Heroes.get_all_russian_heroes()
    print(f"\nRussian heroes ({len(russian_heroes)}):")
    for i, hero in enumerate(russian_heroes):
        print(f"{i+1}. {hero.name}")
        print(f"   Gender: {hero.gender}")
        print(f"   Appearance: {hero.appearance}")
        print(f"   Personality traits: {', '.join(hero.personality_traits)}")
        print(f"   Interests: {', '.join(hero.interests)}")
        print(f"   Strengths: {', '.join(hero.strengths)}")


if __name__ == "__main__":
    create_heroes_table()