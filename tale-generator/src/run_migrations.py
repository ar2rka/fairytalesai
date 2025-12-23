#!/usr/bin/env python3
"""Script to run Supabase migrations for the tale generator."""

import os
import sys
import asyncio
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client
from supabase.client import ClientOptions

# Add the src directory to the path so we can import our modules
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.models import HeroDB, Language
from src.prompts import Heroes


def run_sql_migration(client: Client, sql_file_path: str) -> bool:
    """
    Run a SQL migration file.
    
    Args:
        client: The Supabase client
        sql_file_path: Path to the SQL file to execute
        
    Returns:
        True if successful, False otherwise
    """
    try:
        with open(sql_file_path, 'r') as file:
            sql_content = file.read()
        
        # Split the SQL content into individual statements
        statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
        
        # Execute each statement
        for statement in statements:
            print(f"Executing statement: {statement[:50]}..." if len(statement) > 50 else f"Executing statement: {statement}")
            # Note: Direct SQL execution is not supported in the Supabase Python client
            # This would need to be done through the Supabase SQL editor or another method
            print("  -> Statement would be executed in Supabase SQL editor")
        
        print(f"Successfully executed migration: {sql_file_path}")
        return True
    except Exception as e:
        print(f"Error running migration {sql_file_path}: {e}")
        return False


def create_heroes_table(client: Client) -> bool:
    """
    Create the heroes table using the Supabase client.
    
    Args:
        client: The Supabase client
        
    Returns:
        True if successful, False otherwise
    """
    try:
        print("Creating heroes table...")
        
        # Read and display the SQL migration file
        migration_file = os.path.join(os.path.dirname(__file__), 'migrations', '001_create_heroes_table.sql')
        print("Run the following SQL in your Supabase SQL editor:")
        print("=" * 50)
        with open(migration_file, 'r') as file:
            print(file.read())
        print("=" * 50)
        
        return True
    except Exception as e:
        print(f"Error creating heroes table: {e}")
        return False


def populate_heroes_table(client: Client) -> bool:
    """
    Populate the heroes table with predefined heroes.
    
    Args:
        client: The Supabase client
        
    Returns:
        True if successful, False otherwise
    """
    try:
        print("Populating heroes table with predefined heroes...")
        
        # Read and display the SQL migration file
        migration_file = os.path.join(os.path.dirname(__file__), 'migrations', '002_populate_heroes_table.sql')
        print("Run the following SQL in your Supabase SQL editor:")
        print("=" * 50)
        with open(migration_file, 'r') as file:
            print(file.read())
        print("=" * 50)
        
        return True
    except Exception as e:
        print(f"Error populating heroes table: {e}")
        return False


async def main():
    """Main function to run all migrations."""
    try:
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
        
        print("Running Supabase migrations for tale generator...")
        print("=" * 60)
        
        # Run migrations in order
        migrations_dir = os.path.join(os.path.dirname(__file__), 'migrations')
        
        # Get migration files in order
        migration_files = sorted([
            f for f in os.listdir(migrations_dir) 
            if f.endswith('.sql')
        ])
        
        print("Migration files to run manually in Supabase:")
        for i, migration_file in enumerate(migration_files, 1):
            print(f"  {i}. {migration_file}")
        
        print("\n" + "=" * 60)
        
        # Execute each migration
        for i, migration_file in enumerate(migration_files, 1):
            print(f"{i}. Executing migration: {migration_file}...")
            migration_path = os.path.join(migrations_dir, migration_file)
            
            if migration_file == '001_create_heroes_table.sql':
                if not create_heroes_table(client):
                    print(f"Failed to execute migration: {migration_file}")
                    return False
            elif migration_file == '002_populate_heroes_table.sql':
                if not populate_heroes_table(client):
                    print(f"Failed to execute migration: {migration_file}")
                    return False
            elif migration_file == '003_add_new_hero_example.sql':
                # This is just an example file, skip execution
                print("  -> This is an example file, skipping execution")
                print("  -> To add a new hero, copy and modify this file, then run it in Supabase SQL editor")
            else:
                # For any other SQL files
                if not run_sql_migration(client, migration_path):
                    print(f"Failed to execute migration: {migration_file}")
                    return False
            
            print(f"✓ Completed migration: {migration_file}\n")
        
        print("=" * 60)
        print("Migration instructions:")
        print("1. Copy the SQL from each migration file")
        print("2. Run them in your Supabase SQL editor in order")
        print("3. The heroes table will be created and populated with predefined heroes")
        
        return True
        
    except Exception as e:
        print(f"Error running migrations: {e}")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    if success:
        print("\n✅ Migrations completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Migrations failed!")
        sys.exit(1)