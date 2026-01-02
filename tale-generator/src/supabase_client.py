"""Supabase client for story storage."""

import logging
import os
from typing import List, Optional, Any, Dict
from supabase import create_client, Client
from supabase.client import ClientOptions
from src.models import StoryDB, ChildDB, HeroDB, DailyFreeStoryDB
from src.infrastructure.persistence.models import GenerationDB, FreeStoryDB, DailyFreeStoryDB as PersistenceDailyFreeStoryDB, DailyStoryReactionDB
from src.domain.services.subscription_service import UserSubscription, SubscriptionPlan, SubscriptionStatus
from dotenv import load_dotenv
from typing import Optional
from datetime import datetime

# Set up logger
logger = logging.getLogger("tale_generator.supabase")

# Load environment variables
load_dotenv()


class SupabaseClient:
    """Client for interacting with Supabase database."""

    def __init__(self):
        """Initialize the Supabase client."""
        self.supabase_url = os.getenv("SUPABASE_URL")
        self.supabase_key = os.getenv("SUPABASE_KEY")
        
        if not self.supabase_url or not self.supabase_key:
            raise ValueError(
                "Supabase credentials are required. "
                "Set SUPABASE_URL and SUPABASE_KEY environment variables."
            )
        
        # Create client with schema specification
        self.client: Client = create_client(
            supabase_url=self.supabase_url,
            supabase_key=self.supabase_key,
            options=ClientOptions(
                postgrest_client_timeout=10,
                storage_client_timeout=10,
                schema="tales",
            )
        )
    
    def upload_audio_file(self, file_data: bytes, filename: str, story_id: str) -> Optional[str]:
        """
        Upload an audio file to Supabase storage.
        
        Args:
            file_data: The audio file data as bytes
            filename: The name of the file
            story_id: The ID of the story the audio belongs to
            
        Returns:
            The URL of the uploaded file, or None if upload failed
        """
        try:
            logger.info(f"Uploading audio file {filename} for story {story_id}")
            
            # Create the file path in the storage bucket
            # Using stories/{story_id}/{filename} structure
            file_path = f"stories/{story_id}/{filename}"
            
            # Upload the file to the 'tales' bucket
            response = self.client.storage.from_("tales").upload(
                path=file_path,
                file=file_data,
                file_options={"content-type": "audio/mpeg"}
            )
            
            if response:
                # Get the public URL for the file
                public_url = self.client.storage.from_("tales").get_public_url(file_path)
                logger.info(f"Successfully uploaded audio file. Public URL: {public_url}")
                return public_url
            else:
                logger.error("Failed to upload audio file - no response from Supabase")
                return None
                
        except Exception as e:
            logger.error(f"Error uploading audio file: {str(e)}", exc_info=True)
            return None
    
    def get_audio_file_url(self, story_id: str, filename: str) -> Optional[str]:
        """
        Get the public URL for an audio file.
        
        Args:
            story_id: The ID of the story
            filename: The name of the file
            
        Returns:
            The public URL of the file, or None if not found
        """
        try:
            file_path = f"stories/{story_id}/{filename}"
            public_url = self.client.storage.from_("tales").get_public_url(file_path)
            return public_url
        except Exception as e:
            logger.error(f"Error getting audio file URL: {str(e)}", exc_info=True)
            return None

    def save_child(self, child: ChildDB) -> ChildDB:
        """Save a child to the database.
        
        Args:
            child: The child to save
            
        Returns:
            The saved child with ID and timestamps
        """
        try:
            # Convert ChildDB to dictionary for Supabase
            child_dict = child.model_dump()
            
            # Map camelCase keys to snake_case keys for Supabase
            mapped_child_dict = {}
            key_mapping = {
                'name': 'name',
                'age_category': 'age_category',
                'gender': 'gender',
                'interests': 'interests',
                'user_id': 'user_id',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id'
            }
            
            for py_key, db_key in key_mapping.items():
                if py_key in child_dict:
                    value = child_dict[py_key]
                    # Handle datetime serialization
                    if value and (py_key == 'created_at' or py_key == 'updated_at'):
                        if hasattr(value, 'isoformat'):
                            mapped_child_dict[db_key] = value.isoformat()
                        else:
                            mapped_child_dict[db_key] = value
                    else:
                        mapped_child_dict[db_key] = value
            
            # Remove ID if it's None (let Supabase generate it)
            if mapped_child_dict.get('id') is None:
                mapped_child_dict.pop('id', None)
            
            response = self.client.table("children").insert(mapped_child_dict).execute()
            
            if response.data:
                # Return the saved child with generated ID and timestamps
                saved_child_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                model_child_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in saved_child_data:
                        model_child_data[py_key] = saved_child_data[db_key]
                
                return ChildDB(**model_child_data)
            else:
                raise Exception("Failed to save child")
        except Exception as e:
            raise Exception(f"Error saving child: {str(e)}")

    def get_child(self, child_id: str, user_id: Optional[str] = None) -> Optional[ChildDB]:
        """Retrieve a child by ID.
        
        Args:
            child_id: The ID of the child to retrieve
            user_id: Optional user ID to verify ownership
            
        Returns:
            The child if found, None otherwise
        """
        try:
            query = self.client.table("children").select("*").eq("id", child_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            if response.data:
                child_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'name': 'name',
                    'age_category': 'age_category',
                    'gender': 'gender',
                    'interests': 'interests',
                    'user_id': 'user_id',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id'
                }
                
                model_child_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in child_data:
                        model_child_data[py_key] = child_data[db_key]
                
                return ChildDB(**model_child_data)
            return None
        except Exception as e:
            raise Exception(f"Error retrieving child: {str(e)}")

    def get_all_children(self, user_id: Optional[str] = None) -> List[ChildDB]:
        """Retrieve all children.
        
        Args:
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of all children (filtered by user_id if provided)
        """
        try:
            query = self.client.table("children").select("*")
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            children = []
            key_mapping = {
                'name': 'name',
                'age_category': 'age_category',
                'gender': 'gender',
                'interests': 'interests',
                'user_id': 'user_id',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id'
            }
            
            for child_data in response.data:
                model_child_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in child_data:
                        model_child_data[py_key] = child_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_child_data for key in ['name', 'age_category', 'gender']):
                    children.append(ChildDB(**model_child_data))
            
            return children
        except Exception as e:
            raise Exception(f"Error retrieving children: {str(e)}")

    def save_hero(self, hero: HeroDB) -> HeroDB:
        """Save a hero to the database.
        
        Args:
            hero: The hero to save
            
        Returns:
            The saved hero with ID and timestamps
        """
        try:
            # Convert HeroDB to dictionary for Supabase
            hero_dict = hero.model_dump()
            
            # Map camelCase keys to snake_case keys for Supabase
            mapped_hero_dict = {}
            key_mapping = {
                'name': 'name',
                'gender': 'gender',
                'appearance': 'appearance',
                'personality_traits': 'personality_traits',
                'interests': 'interests',
                'strengths': 'strengths',
                'language': 'language',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'user_id': 'user_id'  # Add user_id field
            }
            
            for py_key, db_key in key_mapping.items():
                if py_key in hero_dict:
                    value = hero_dict[py_key]
                    # Handle datetime serialization
                    if value and py_key in ('created_at', 'updated_at'):
                        if hasattr(value, 'isoformat'):
                            mapped_hero_dict[db_key] = value.isoformat()
                        else:
                            mapped_hero_dict[db_key] = value
                    # Handle Language enum serialization
                    elif py_key == 'language':
                        mapped_hero_dict[db_key] = value.value if hasattr(value, 'value') else value
                    else:
                        mapped_hero_dict[db_key] = value
            
            # Remove ID if it's None (let Supabase generate it)
            if mapped_hero_dict.get('id') is None:
                mapped_hero_dict.pop('id', None)
            
            response = self.client.table("heroes").insert(mapped_hero_dict).execute()
            
            if response.data:
                # Return the saved hero with generated ID and timestamps
                saved_hero_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                model_hero_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in saved_hero_data:
                        model_hero_data[py_key] = saved_hero_data[db_key]
                
                return HeroDB(**model_hero_data)
            else:
                raise Exception("Failed to save hero")
        except Exception as e:
            raise Exception(f"Error saving hero: {str(e)}")

    def get_hero(self, hero_id: str) -> Optional[HeroDB]:
        """Retrieve a hero by ID.
        
        Args:
            hero_id: The ID of the hero to retrieve
            
        Returns:
            The hero if found, None otherwise
        """
        try:
            response = self.client.table("heroes").select("*").eq("id", hero_id).execute()
            
            if response.data:
                hero_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'name': 'name',
                    'gender': 'gender',
                    'appearance': 'appearance',
                    'personality_traits': 'personality_traits',
                    'interests': 'interests',
                    'strengths': 'strengths',
                    'language': 'language',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id'
                }
                
                model_hero_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in hero_data:
                        model_hero_data[py_key] = hero_data[db_key]
                
                return HeroDB(**model_hero_data)
            return None
        except Exception as e:
            raise Exception(f"Error retrieving hero: {str(e)}")

    def get_all_heroes(self, user_id: Optional[str] = None) -> List[HeroDB]:
        """Retrieve all heroes.
        
        Args:
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of all heroes (filtered by user_id if provided)
        """
        try:
            query = self.client.table("heroes").select("*")
            if user_id:
                # Filter for heroes owned by user or unowned heroes
                query = query.or_(f"user_id.is.null,user_id.eq.{user_id}")
            response = query.execute()
            
            heroes = []
            key_mapping = {
                'name': 'name',
                'gender': 'gender',
                'appearance': 'appearance',
                'personality_traits': 'personality_traits',
                'interests': 'interests',
                'strengths': 'strengths',
                'language': 'language',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'user_id': 'user_id'  # Add user_id field
            }
            
            for hero_data in response.data:
                model_hero_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in hero_data:
                        model_hero_data[py_key] = hero_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_hero_data for key in ['name', 'gender', 'appearance']):
                    heroes.append(HeroDB(**model_hero_data))
            
            return heroes
        except Exception as e:
            raise Exception(f"Error retrieving heroes: {str(e)}")

    def update_hero(self, hero: HeroDB, user_id: Optional[str] = None) -> HeroDB:
        """Update a hero in the database.
        
        Args:
            hero: The hero to update
            user_id: Optional user ID to verify ownership
            
        Returns:
            The updated hero
        """
        try:
            if not hero.id:
                raise ValueError("Hero ID is required for update")
            
            # If user_id is provided, verify ownership
            if user_id:
                # First check if the hero exists and belongs to the user
                existing_hero = self.get_hero(hero.id)
                if not existing_hero:
                    raise Exception("Hero not found")
                
                # Check if the hero is owned by the user or is unowned
                if existing_hero.user_id and existing_hero.user_id != user_id:
                    raise Exception("You do not have permission to update this hero")
                
                # Set the user_id on the hero to ensure it's correctly associated
                hero.user_id = user_id
            
            # Convert HeroDB to dictionary for Supabase
            hero_dict = hero.model_dump()
            
            # Map camelCase keys to snake_case keys for Supabase
            mapped_hero_dict = {}
            key_mapping = {
                'name': 'name',
                'gender': 'gender',
                'appearance': 'appearance',
                'personality_traits': 'personality_traits',
                'interests': 'interests',
                'strengths': 'strengths',
                'language': 'language',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'user_id': 'user_id'  # Add user_id field
            }
            
            for py_key, db_key in key_mapping.items():
                if py_key in hero_dict:
                    value = hero_dict[py_key]
                    # Handle datetime serialization
                    if value and (py_key == 'created_at' or py_key == 'updated_at'):
                        if hasattr(value, 'isoformat'):
                            mapped_hero_dict[db_key] = value.isoformat()
                        else:
                            mapped_hero_dict[db_key] = value
                    # Handle Language enum serialization
                    elif py_key == 'language':
                        mapped_hero_dict[db_key] = value.value if hasattr(value, 'value') else value
                    else:
                        mapped_hero_dict[db_key] = value
            
            # Build the update query
            query = self.client.table("heroes").update(mapped_hero_dict).eq("id", hero.id)
            
            # If user_id is provided, also filter by user_id to ensure ownership
            if user_id:
                query = query.eq("user_id", user_id)
            
            response = query.execute()
            
            if response.data:
                # Return the updated hero
                updated_hero_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                model_hero_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in updated_hero_data:
                        model_hero_data[py_key] = updated_hero_data[db_key]
                
                # Add the ID back
                model_hero_data['id'] = hero.id
                
                return HeroDB(**model_hero_data)
            else:
                raise Exception("Failed to update hero - you may not have permission to edit this hero")
        except Exception as e:
            raise Exception(f"Error updating hero: {str(e)}")

    def delete_hero(self, hero_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a hero by ID.
        
        Args:
            hero_id: The ID of the hero to delete
            user_id: Optional user ID to verify ownership
            
        Returns:
            True if deleted, False otherwise
        """
        try:
            # If user_id is provided, verify ownership before deleting
            if user_id:
                # First check if the hero exists and belongs to the user
                existing_hero = self.get_hero(hero_id)
                if not existing_hero:
                    return False
                
                # Check if the hero is owned by the user
                if existing_hero.user_id and existing_hero.user_id != user_id:
                    raise Exception("You do not have permission to delete this hero")
            
            # Build the delete query
            query = self.client.table("heroes").delete().eq("id", hero_id)
            
            # If user_id is provided, also filter by user_id to ensure ownership
            if user_id:
                query = query.eq("user_id", user_id)
            
            response = query.execute()
            return len(response.data) > 0
        except Exception as e:
            raise Exception(f"Error deleting hero: {str(e)}")

    def save_story(self, story: StoryDB) -> StoryDB:
        """Save a story to the database.
        
        Args:
            story: The story to save
            
        Returns:
            The saved story with ID and timestamps
        """
        try:
            # Convert StoryDB to dictionary for Supabase
            story_dict = story.model_dump()
            
            # Map camelCase keys to snake_case keys for Supabase
            mapped_story_dict = {}
            key_mapping = {
                'child_id': 'child_id',
                'child_name': 'child_name',
                'child_age_category': 'child_age_category',
                'child_gender': 'child_gender',
                'child_interests': 'child_interests',
                'hero_id': 'hero_id',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'title': 'title',
                'content': 'content',
                'summary': 'summary',
                'moral': 'moral',
                'language': 'language',
                'rating': 'rating',
                'audio_file_url': 'audio_file_url',
                'user_id': 'user_id',
                'status': 'status',
                'generation_id': 'generation_id',
                'parent_id': 'parent_id',
            }
            
            for py_key, db_key in key_mapping.items():
                if py_key in story_dict:
                    value = story_dict[py_key]
                    # Handle datetime serialization
                    if value and py_key in ('created_at', 'updated_at'):
                        if hasattr(value, 'isoformat'):
                            mapped_story_dict[db_key] = value.isoformat()
                        else:
                            mapped_story_dict[db_key] = value
                    else:
                        mapped_story_dict[db_key] = value
            
            # Remove ID if it's None (let Supabase generate it)
            if mapped_story_dict.get('id') is None:
                mapped_story_dict.pop('id', None)
            
            response = self.client.table("stories").insert(mapped_story_dict).execute()
            
            if response.data:
                # Return the saved story with generated ID and timestamps
                saved_story_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in saved_story_data:
                        model_story_data[py_key] = saved_story_data[db_key]
                
                return StoryDB(**model_story_data)
            else:
                raise Exception("Failed to save story")
        except Exception as e:
            raise Exception(f"Error saving story: {str(e)}")

    def get_story(self, story_id: str, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Retrieve a story by ID.
        
        Args:
            story_id: The ID of the story to retrieve
            user_id: Optional user ID to verify ownership
            
        Returns:
            The story if found, None otherwise
        """
        try:
            query = self.client.table("stories").select("*").eq("id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            if response.data:
                story_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'child_id': 'child_id',
                    'child_name': 'child_name',
                    'child_age_category': 'child_age_category',
                    'child_gender': 'child_gender',
                    'child_interests': 'child_interests',
                    'story_type': 'story_type',
                    'hero_id': 'hero_id',
                    'hero_name': 'hero_name',
                    'hero_gender': 'hero_gender',
                    'hero_appearance': 'hero_appearance',
                    'relationship_description': 'relationship_description',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id',
                    'title': 'title',
                    'content': 'content',
                    'summary': 'summary',
                    'moral': 'moral',
                    'model_used': 'model_used',
                    'language': 'language',
                    'rating': 'rating',
                    'story_length': 'story_length',
                    'audio_file_url': 'audio_file_url',
                    'audio_provider': 'audio_provider',
                    'audio_generation_metadata': 'audio_generation_metadata',
                    'user_id': 'user_id',
                    'status': 'status',
                    'generation_id': 'generation_id',
                    'parent_id': 'parent_id'
                }
                
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                return StoryDB(**model_story_data)
            return None
        except Exception as e:
            raise Exception(f"Error retrieving story: {str(e)}")

    def get_stories_by_child(self, child_name: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific child.
        
        Args:
            child_name: The name of the child
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of stories for the child
        """
        try:
            query = self.client.table("stories").select("*").eq("child_name", child_name)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            stories = []
            key_mapping = {
                'child_id': 'child_id',
                'child_name': 'child_name',
                'child_age_category': 'child_age_category',
                'child_gender': 'child_gender',
                'child_interests': 'child_interests',
                'hero_id': 'hero_id',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'title': 'title',
                'content': 'content',
                'summary': 'summary',
                'full_response': 'full_response',
                'generation_info': 'generation_info',
                'language': 'language',
                'rating': 'rating',
                'story_length': 'story_length',
                'audio_file_url': 'audio_file_url',
                'audio_provider': 'audio_provider',
                'audio_generation_metadata': 'audio_generation_metadata',
                'user_id': 'user_id'
            }
            
            for story_data in response.data:
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_story_data for key in ['title', 'content', 'moral']):
                    try:
                        stories.append(StoryDB(**model_story_data))
                    except Exception as e:
                        logger.warning(f"Skipping story due to validation error: {str(e)}")
                        continue
            
            return stories
        except Exception as e:
            raise Exception(f"Error retrieving stories: {str(e)}")

    def get_stories_by_child_id(self, child_id: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific child by child ID.
        
        Args:
            child_id: The ID of the child
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of stories for the child
        """
        try:
            query = self.client.table("stories").select("*").eq("child_id", child_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            stories = []
            key_mapping = {
                'child_id': 'child_id',
                'child_name': 'child_name',
                'child_age_category': 'child_age_category',
                'child_gender': 'child_gender',
                'child_interests': 'child_interests',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'title': 'title',
                'content': 'content',
                'summary': 'summary',
                'moral': 'moral',
                'model_used': 'model_used',
                'full_response': 'full_response',
                'generation_info': 'generation_info',
                'language': 'language',
                'rating': 'rating',
                'user_id': 'user_id'
            }
            
            for story_data in response.data:
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_story_data for key in ['title', 'content', 'moral']):
                    try:
                        stories.append(StoryDB(**model_story_data))
                    except Exception as e:
                        logger.warning(f"Skipping story due to validation error: {str(e)}")
                        continue
            
            return stories
        except Exception as e:
            raise Exception(f"Error retrieving stories: {str(e)}")

    def get_all_stories(self, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories.
        
        Args:
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of all stories (filtered by user_id if provided)
        """
        try:
            query = self.client.table("stories").select("*")
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            stories = []
            key_mapping = {
                'child_id': 'child_id',
                'child_name': 'child_name',
                'child_age_category': 'child_age_category',
                'child_gender': 'child_gender',
                'child_interests': 'child_interests',
                'story_type': 'story_type',
                'hero_id': 'hero_id',
                'hero_name': 'hero_name',
                'hero_gender': 'hero_gender',
                'hero_appearance': 'hero_appearance',
                'relationship_description': 'relationship_description',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'title': 'title',
                'content': 'content',
                'summary': 'summary',
                'moral': 'moral',
                'model_used': 'model_used',
                'full_response': 'full_response',
                'generation_info': 'generation_info',
                'language': 'language',
                'rating': 'rating',
                'story_length': 'story_length',
                'audio_file_url': 'audio_file_url',
                'audio_provider': 'audio_provider',
                'audio_generation_metadata': 'audio_generation_metadata',
                'user_id': 'user_id',
                'status': 'status'
            }
            
            for story_data in response.data:
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_story_data for key in ['title', 'content', 'moral']):
                    try:
                        stories.append(StoryDB(**model_story_data))
                    except Exception as e:
                        logger.warning(f"Skipping story due to validation error: {str(e)}")
                        continue
            
            return stories
        except Exception as e:
            raise Exception(f"Error retrieving stories: {str(e)}")

    def get_stories_by_language(self, language: str, user_id: Optional[str] = None) -> List[StoryDB]:
        """Retrieve all stories for a specific language.
        
        Args:
            language: The language code
            user_id: Optional user ID to filter by ownership
            
        Returns:
            List of stories in the specified language
        """
        try:
            query = self.client.table("stories").select("*").eq("language", language)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            stories = []
            key_mapping = {
                'child_id': 'child_id',
                'child_name': 'child_name',
                'child_age_category': 'child_age_category',
                'child_gender': 'child_gender',
                'child_interests': 'child_interests',
                'story_type': 'story_type',
                'hero_id': 'hero_id',
                'hero_name': 'hero_name',
                'hero_gender': 'hero_gender',
                'hero_appearance': 'hero_appearance',
                'relationship_description': 'relationship_description',
                'created_at': 'created_at',
                'updated_at': 'updated_at',
                'id': 'id',
                'title': 'title',
                'content': 'content',
                'summary': 'summary',
                'moral': 'moral',
                'model_used': 'model_used',
                'full_response': 'full_response',
                'generation_info': 'generation_info',
                'language': 'language',
                'rating': 'rating',
                'story_length': 'story_length',
                'audio_file_url': 'audio_file_url',
                'audio_provider': 'audio_provider',
                'audio_generation_metadata': 'audio_generation_metadata'
            }
            
            for story_data in response.data:
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                # Only append if we have the required fields
                if all(key in model_story_data for key in ['title', 'content', 'moral']):
                    try:
                        stories.append(StoryDB(**model_story_data))
                    except Exception as e:
                        logger.warning(f"Skipping story due to validation error: {str(e)}")
                        continue
            
            return stories
        except Exception as e:
            raise Exception(f"Error retrieving stories: {str(e)}")

    def update_story_rating(self, story_id: str, rating: int, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Update the rating of a story.
        
        Args:
            story_id: The ID of the story to update
            rating: The new rating (1-10)
            user_id: Optional user ID to verify ownership
            
        Returns:
            The updated story if found, None otherwise
        """
        try:
            # Validate rating
            if not 1 <= rating <= 10:
                raise ValueError("Rating must be between 1 and 10")
            
            logger.debug(f"Updating rating for story {story_id} to {rating}")
            
            # Update the story rating
            query = self.client.table("stories").update({
                "rating": rating,
                "updated_at": "NOW()"
            }).eq("id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            if response.data:
                # Return the updated story
                story_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'child_id': 'child_id',
                    'child_name': 'child_name',
                    'child_age_category': 'child_age_category',
                    'child_gender': 'child_gender',
                    'child_interests': 'child_interests',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id',
                    'title': 'title',
                    'content': 'content',
                    'summary': 'summary',
                    'moral': 'moral',
                    'model_used': 'model_used',
                    'full_response': 'full_response',
                    'generation_info': 'generation_info',
                    'language': 'language',
                    'rating': 'rating',
                    'audio_file_url': 'audio_file_url',
                    'audio_provider': 'audio_provider',
                    'audio_generation_metadata': 'audio_generation_metadata'
                }
                
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                logger.info(f"Successfully updated rating for story {story_id}")
                return StoryDB(**model_story_data)
            else:
                logger.warning(f"No story found with ID {story_id}")
                return None
        except Exception as e:
            logger.error(f"Error updating story rating: {str(e)}", exc_info=True)
            raise Exception(f"Error updating story rating: {str(e)}")

    def update_story_status(self, story_id: str, status: str, user_id: Optional[str] = None) -> Optional[StoryDB]:
        """Update the status of a story.
        
        Args:
            story_id: The ID of the story to update
            status: The new status (new, read, archived)
            user_id: Optional user ID to verify ownership
            
        Returns:
            The updated story if found, None otherwise
        """
        try:
            # Validate status
            if status not in ['new', 'read', 'archived']:
                raise ValueError("Status must be one of: new, read, archived")
            
            logger.debug(f"Updating status for story {story_id} to {status}")
            
            # Update the story status
            query = self.client.table("stories").update({
                "status": status,
                "updated_at": "NOW()"
            }).eq("id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            if response.data:
                # Return the updated story
                story_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'child_id': 'child_id',
                    'child_name': 'child_name',
                    'child_age_category': 'child_age_category',
                    'child_gender': 'child_gender',
                    'child_interests': 'child_interests',
                    'story_type': 'story_type',
                    'hero_id': 'hero_id',
                    'hero_name': 'hero_name',
                    'hero_gender': 'hero_gender',
                    'hero_appearance': 'hero_appearance',
                    'relationship_description': 'relationship_description',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id',
                    'title': 'title',
                    'content': 'content',
                    'summary': 'summary',
                    'moral': 'moral',
                    'model_used': 'model_used',
                    'full_response': 'full_response',
                    'generation_info': 'generation_info',
                    'language': 'language',
                    'rating': 'rating',
                    'story_length': 'story_length',
                    'audio_file_url': 'audio_file_url',
                    'audio_provider': 'audio_provider',
                    'audio_generation_metadata': 'audio_generation_metadata',
                    'user_id': 'user_id',
                    'status': 'status'
                }
                
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                logger.info(f"Successfully updated status for story {story_id}")
                return StoryDB(**model_story_data)
            else:
                logger.warning(f"No story found with ID {story_id}")
                return None
        except Exception as e:
            logger.error(f"Error updating story status: {str(e)}", exc_info=True)
            raise Exception(f"Error updating story status: {str(e)}")

    def update_story_audio(
        self,
        story_id: str,
        audio_file_url: str,
        audio_provider: Optional[str] = None,
        audio_metadata: Optional[dict] = None,
        user_id: Optional[str] = None
    ) -> Optional[StoryDB]:
        """Update the audio information of a story.
        
        Args:
            story_id: The ID of the story to update
            audio_file_url: URL of the generated audio file
            audio_provider: Name of the audio provider used
            audio_metadata: Additional metadata about audio generation
            user_id: Optional user ID to verify ownership
            
        Returns:
            The updated story if found, None otherwise
        """
        try:
            logger.debug(f"Updating audio for story {story_id}")
            
            # Build update data
            update_data = {
                "audio_file_url": audio_file_url,
                "updated_at": "NOW()"
            }
            
            if audio_provider:
                update_data["audio_provider"] = audio_provider
            
            if audio_metadata:
                update_data["audio_generation_metadata"] = audio_metadata
            
            # Update the story audio
            query = self.client.table("stories").update(update_data).eq("id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            
            if response.data:
                # Return the updated story
                story_data = response.data[0]
                # Map snake_case keys back to camelCase keys for the model
                key_mapping = {
                    'child_id': 'child_id',
                    'child_name': 'child_name',
                    'child_age_category': 'child_age_category',
                    'child_gender': 'child_gender',
                    'child_interests': 'child_interests',
                    'story_type': 'story_type',
                    'hero_id': 'hero_id',
                    'hero_name': 'hero_name',
                    'hero_gender': 'hero_gender',
                    'hero_appearance': 'hero_appearance',
                    'relationship_description': 'relationship_description',
                    'created_at': 'created_at',
                    'updated_at': 'updated_at',
                    'id': 'id',
                    'title': 'title',
                    'content': 'content',
                    'summary': 'summary',
                    'generation_id': 'generation_id',
                    'moral': 'moral',
                    'language': 'language',
                    'rating': 'rating',
                    'story_length': 'story_length',
                    'audio_file_url': 'audio_file_url',
                    'audio_provider': 'audio_provider',
                    'audio_generation_metadata': 'audio_generation_metadata',
                    'user_id': 'user_id',
                    'status': 'status'
                }
                
                model_story_data = {}
                for db_key, py_key in key_mapping.items():
                    if db_key in story_data:
                        model_story_data[py_key] = story_data[db_key]
                
                logger.info(f"Successfully updated audio for story {story_id}")
                return StoryDB(**model_story_data)
            else:
                logger.warning(f"No story found with ID {story_id}")
                return None
        except Exception as e:
            logger.error(f"Error updating story audio: {str(e)}", exc_info=True)
            raise Exception(f"Error updating story audio: {str(e)}")

    def delete_story(self, story_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a story by ID.
        
        Args:
            story_id: The ID of the story to delete
            user_id: Optional user ID to verify ownership
            
        Returns:
            True if deleted, False otherwise
        """
        try:
            query = self.client.table("stories").delete().eq("id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            return len(response.data) > 0
        except Exception as e:
            raise Exception(f"Error deleting story: {str(e)}")

    def delete_child(self, child_id: str, user_id: Optional[str] = None) -> bool:
        """Delete a child by ID.
        
        Args:
            child_id: The ID of the child to delete
            user_id: Optional user ID to verify ownership
            
        Returns:
            True if deleted, False otherwise
        """
        try:
            query = self.client.table("children").delete().eq("id", child_id)
            if user_id:
                query = query.eq("user_id", user_id)
            response = query.execute()
            return len(response.data) > 0
        except Exception as e:
            raise Exception(f"Error deleting child: {str(e)}")
    
    # Generation operations
    def create_generation(self, generation: GenerationDB) -> GenerationDB:
        """Create a new generation record.
        
        Args:
            generation: Generation record to create
            
        Returns:
            Created generation record
        """
        try:
            generation_dict = generation.model_dump()
            
            # Handle datetime serialization
            if generation_dict.get('created_at') and hasattr(generation_dict['created_at'], 'isoformat'):
                generation_dict['created_at'] = generation_dict['created_at'].isoformat()
            if generation_dict.get('completed_at') and hasattr(generation_dict['completed_at'], 'isoformat'):
                generation_dict['completed_at'] = generation_dict['completed_at'].isoformat()
            
            response = self.client.table("generations").insert(generation_dict).execute()
            
            if response.data:
                return GenerationDB(**response.data[0])
            else:
                raise Exception("Failed to create generation")
        except Exception as e:
            raise Exception(f"Error creating generation: {str(e)}")
    
    def update_generation(self, generation: GenerationDB) -> GenerationDB:
        """Update an existing generation record.
        
        Args:
            generation: Generation record with updated data
            
        Returns:
            Updated generation record
        """
        try:
            generation_dict = generation.model_dump()
            
            # Handle datetime serialization
            if generation_dict.get('created_at') and hasattr(generation_dict['created_at'], 'isoformat'):
                generation_dict['created_at'] = generation_dict['created_at'].isoformat()
            if generation_dict.get('completed_at') and hasattr(generation_dict['completed_at'], 'isoformat'):
                generation_dict['completed_at'] = generation_dict['completed_at'].isoformat()
            
            response = self.client.table("generations").update(generation_dict).eq(
                "generation_id", generation.generation_id
            ).eq(
                "attempt_number", generation.attempt_number
            ).execute()
            
            if response.data:
                return GenerationDB(**response.data[0])
            else:
                raise Exception("Failed to update generation")
        except Exception as e:
            raise Exception(f"Error updating generation: {str(e)}")
    
    def get_generation(self, generation_id: str, attempt_number: int) -> Optional[GenerationDB]:
        """Get a specific generation attempt.
        
        Args:
            generation_id: Generation identifier
            attempt_number: Attempt number
            
        Returns:
            Generation record if found, None otherwise
        """
        try:
            response = self.client.table("generations").select("*").eq(
                "generation_id", generation_id
            ).eq(
                "attempt_number", attempt_number
            ).execute()
            
            if response.data:
                return GenerationDB(**response.data[0])
            return None
        except Exception as e:
            raise Exception(f"Error retrieving generation: {str(e)}")
    
    def get_latest_attempt(self, generation_id: str) -> Optional[GenerationDB]:
        """Get the latest attempt for a generation.
        
        Args:
            generation_id: Generation identifier
            
        Returns:
            Latest generation attempt if found, None otherwise
        """
        try:
            logger.debug(f"Getting latest attempt for generation_id: {generation_id}")
            response = self.client.table("generations").select("*").eq(
                "generation_id", generation_id
            ).order(
                "attempt_number", desc=True
            ).limit(1).execute()
            
            if response.data:
                attempt = GenerationDB(**response.data[0])
                logger.debug(f"Found latest attempt: attempt_number={attempt.attempt_number}")
                return attempt
            logger.warning(f"No latest attempt found for generation_id: {generation_id}")
            return None
        except Exception as e:
            logger.error(f"Error retrieving latest attempt for {generation_id}: {str(e)}", exc_info=True)
            raise Exception(f"Error retrieving latest attempt: {str(e)}")
    
    def get_all_attempts(self, generation_id: str) -> List[GenerationDB]:
        """Get all attempts for a generation.
        
        Args:
            generation_id: Generation identifier
            
        Returns:
            List of all attempts for the generation
        """
        try:
            logger.debug(f"Getting all attempts for generation_id: {generation_id}")
            response = self.client.table("generations").select("*").eq(
                "generation_id", generation_id
            ).order(
                "attempt_number"
            ).execute()
            
            logger.debug(f"Query returned {len(response.data) if response.data else 0} attempts")
            
            if not response.data:
                logger.warning(f"No attempts found for generation_id: {generation_id}")
                return []
            
            attempts = [GenerationDB(**gen) for gen in response.data]
            logger.info(f"Successfully retrieved {len(attempts)} attempts for generation {generation_id}")
            return attempts
        except Exception as e:
            logger.error(f"Error retrieving all attempts for {generation_id}: {str(e)}", exc_info=True)
            raise Exception(f"Error retrieving all attempts: {str(e)}")
    
    def get_user_generations(self, user_id: str, limit: int = 50) -> List[GenerationDB]:
        """Get all generations for a user.
        
        Args:
            user_id: User identifier
            limit: Maximum number of records to return
            
        Returns:
            List of user's generations
        """
        try:
            response = self.client.table("generations").select("*").eq(
                "user_id", user_id
            ).order(
                "created_at", desc=True
            ).limit(limit).execute()
            
            return [GenerationDB(**gen) for gen in response.data]
        except Exception as e:
            raise Exception(f"Error retrieving user generations: {str(e)}")
    
    def get_generations_by_status(self, status: str, limit: int = 50) -> List[GenerationDB]:
        """Get generations by status.
        
        Args:
            status: Status to filter by ('pending', 'success', 'failed', 'timeout')
            limit: Maximum number of records to return
            
        Returns:
            List of generations with the specified status
        """
        try:
            response = self.client.table("generations").select("*").eq(
                "status", status
            ).order(
                "created_at", desc=True
            ).limit(limit).execute()
            
            return [GenerationDB(**gen) for gen in response.data]
        except Exception as e:
            raise Exception(f"Error retrieving generations by status: {str(e)}")
    
    def get_all_generations(
        self, 
        limit: int = 100, 
        status: Optional[str] = None,
        model_used: Optional[str] = None,
        story_type: Optional[str] = None
    ) -> List[GenerationDB]:
        """Get all generations with optional filters.
        
        Args:
            limit: Maximum number of records to return
            status: Optional status filter ('pending', 'success', 'failed', 'timeout')
            model_used: Optional model filter
            story_type: Optional story type filter ('child', 'hero', 'combined')
            
        Returns:
            List of generations matching the filters
        """
        try:
            logger.debug(f"Getting all generations with filters: limit={limit}, status={status}, model={model_used}, story_type={story_type}")
            
            query = self.client.table("generations").select("*")
            
            if status:
                query = query.eq("status", status)
            if model_used:
                query = query.eq("model_used", model_used)
            if story_type:
                query = query.eq("story_type", story_type)
            
            response = query.order("created_at", desc=True).limit(limit).execute()
            
            logger.debug(f"Query returned {len(response.data) if response.data else 0} generations")
            
            if not response.data:
                logger.warning("No generations found in database")
                return []
            
            generations = [GenerationDB(**gen) for gen in response.data]
            logger.info(f"Successfully retrieved {len(generations)} generations")
            return generations
        except Exception as e:
            logger.error(f"Error retrieving all generations: {str(e)}", exc_info=True)
            raise Exception(f"Error retrieving all generations: {str(e)}")
    
    # Subscription and Usage Tracking Methods
    
    def get_user_subscription(self, user_id: str) -> Optional[UserSubscription]:
        """Get user subscription information.
        
        Args:
            user_id: The user ID
            
        Returns:
            UserSubscription object or None if not found
        """
        try:
            response = self.client.table("user_profiles").select("*").eq("id", user_id).execute()
            
            if not response.data:
                return None
            
            profile = response.data[0]
            
            return UserSubscription(
                user_id=user_id,
                plan=SubscriptionPlan(profile.get('subscription_plan', 'free')),
                status=SubscriptionStatus(profile.get('subscription_status', 'active')),
                start_date=datetime.fromisoformat(profile['subscription_start_date']) if profile.get('subscription_start_date') else None,
                end_date=datetime.fromisoformat(profile['subscription_end_date']) if profile.get('subscription_end_date') else None,
                monthly_story_count=profile.get('monthly_story_count', 0),
                last_reset_date=datetime.fromisoformat(profile['last_reset_date']) if profile.get('last_reset_date') else datetime.now()
            )
        except Exception as e:
            logger.error(f"Error retrieving user subscription: {str(e)}")
            raise Exception(f"Error retrieving user subscription: {str(e)}")
    
    def reset_monthly_story_count(self, user_id: str) -> None:
        """Reset monthly story count for a user.
        
        Args:
            user_id: The user ID
        """
        try:
            # Call the database function to check and reset
            self.client.rpc('check_and_reset_monthly_counter', {'p_user_id': user_id}).execute()
            logger.info(f"Monthly story count reset check completed for user {user_id}")
        except Exception as e:
            logger.error(f"Error resetting monthly story count: {str(e)}")
            raise Exception(f"Error resetting monthly story count: {str(e)}")
    
    def increment_story_count(self, user_id: str) -> None:
        """Increment monthly story count for a user.
        
        Args:
            user_id: The user ID
        """
        try:
            response = self.client.table("user_profiles").select("monthly_story_count").eq("id", user_id).execute()
            
            if not response.data:
                raise Exception(f"User profile not found for user {user_id}")
            
            current_count = response.data[0].get('monthly_story_count', 0)
            
            self.client.table("user_profiles").update({
                'monthly_story_count': current_count + 1
            }).eq('id', user_id).execute()
            
            logger.info(f"Incremented story count for user {user_id} to {current_count + 1}")
        except Exception as e:
            logger.error(f"Error incrementing story count: {str(e)}")
            raise Exception(f"Error incrementing story count: {str(e)}")
    
    def track_usage(self, user_id: str, action_type: str, resource_id: Optional[str] = None, metadata: Optional[dict] = None) -> None:
        """Track user action in usage_tracking table.
        
        Args:
            user_id: The user ID
            action_type: Type of action (story_generation, audio_generation, child_creation)
            resource_id: Optional ID of created resource
            metadata: Optional additional metadata
        """
        try:
            tracking_data = {
                'user_id': user_id,
                'action_type': action_type,
                'action_timestamp': datetime.now().isoformat(),
                'resource_id': resource_id,
                'metadata': metadata
            }
            
            self.client.table("usage_tracking").insert(tracking_data).execute()
            logger.debug(f"Tracked {action_type} action for user {user_id}")
        except Exception as e:
            # Log but don't fail the request if tracking fails
            logger.warning(f"Failed to track usage: {str(e)}")
    
    def count_user_children(self, user_id: str) -> int:
        """Count the number of child profiles for a user.
        
        Args:
            user_id: The user ID
            
        Returns:
            Number of child profiles
        """
        try:
            response = self.client.table("children").select("id", count="exact").eq("user_id", user_id).execute()
            return response.count if response.count is not None else 0
        except Exception as e:
            logger.error(f"Error counting user children: {str(e)}")
            raise Exception(f"Error counting user children: {str(e)}")
    
    # Purchase transaction methods
    
    def create_purchase_transaction(self, transaction_data: dict) -> dict:
        """Create a new purchase transaction record.
        
        Args:
            transaction_data: Transaction data dictionary
            
        Returns:
            Created transaction record
        """
        try:
            response = self.client.table("purchase_transactions").insert(transaction_data).execute()
            
            if not response.data:
                raise Exception("Failed to create purchase transaction")
            
            logger.info(f"Created purchase transaction: {response.data[0]['id']}")
            return response.data[0]
        except Exception as e:
            logger.error(f"Error creating purchase transaction: {str(e)}")
            raise Exception(f"Error creating purchase transaction: {str(e)}")
    
    def get_purchase_transaction(self, transaction_id: str, user_id: str) -> Optional[dict]:
        """Get a purchase transaction by ID.
        
        Args:
            transaction_id: Transaction ID
            user_id: User ID for authorization
            
        Returns:
            Transaction record or None
        """
        try:
            response = self.client.table("purchase_transactions").select("*").eq("id", transaction_id).eq("user_id", user_id).execute()
            
            if not response.data:
                return None
            
            return response.data[0]
        except Exception as e:
            logger.error(f"Error retrieving purchase transaction: {str(e)}")
            raise Exception(f"Error retrieving purchase transaction: {str(e)}")
    
    def get_user_purchase_history(
        self,
        user_id: str,
        status: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> dict:
        """Get purchase transaction history for a user.
        
        Args:
            user_id: User ID
            status: Optional filter by payment_status
            limit: Maximum number of records
            offset: Pagination offset
            
        Returns:
            Dictionary with transactions list and total count
        """
        try:
            query = self.client.table("purchase_transactions").select("*", count="exact").eq("user_id", user_id)
            
            if status:
                query = query.eq("payment_status", status)
            
            query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
            
            response = query.execute()
            
            return {
                "transactions": response.data,
                "total": response.count if response.count is not None else 0,
                "has_more": response.count > offset + limit if response.count else False
            }
        except Exception as e:
            logger.error(f"Error retrieving purchase history: {str(e)}")
            raise Exception(f"Error retrieving purchase history: {str(e)}")
    
    def update_subscription_plan(
        self,
        user_id: str,
        plan: str,
        start_date: datetime,
        end_date: Optional[datetime] = None
    ) -> dict:
        """Update user subscription plan.
        
        Args:
            user_id: User ID
            plan: New plan tier
            start_date: Subscription start date
            end_date: Subscription end date (optional)
            
        Returns:
            Updated user profile
        """
        try:
            update_data = {
                'subscription_plan': plan,
                'subscription_status': 'active',
                'subscription_start_date': start_date.isoformat(),
                'monthly_story_count': 0,
                'last_reset_date': start_date.isoformat()
            }
            
            if end_date:
                update_data['subscription_end_date'] = end_date.isoformat()
            
            response = self.client.table("user_profiles").update(update_data).eq("id", user_id).execute()
            
            if not response.data:
                raise Exception(f"Failed to update subscription for user {user_id}")
            
            logger.info(f"Updated subscription for user {user_id} to {plan} plan")
            return response.data[0]
        except Exception as e:
            logger.error(f"Error updating subscription: {str(e)}")
            raise Exception(f"Error updating subscription: {str(e)}")
    
    # Free stories methods (public, no RLS)
    
    def get_free_stories(
        self,
        age_category: Optional[str] = None,
        language: Optional[str] = None,
        limit: Optional[int] = None
    ) -> List[FreeStoryDB]:
        """Get active free stories, optionally filtered by age category and language.
        
        Args:
            age_category: Optional age category filter ('2-3', '3-5', '5-7')
            language: Optional language filter ('en', 'ru')
            limit: Optional limit on number of results
            
        Returns:
            List of active free stories, sorted by created_at DESC
        """
        try:
            query = self.client.table("free_stories").select("*").eq("is_active", True)
            
            if age_category:
                query = query.eq("age_category", age_category)
            
            if language:
                query = query.eq("language", language)
            
            # Sort by created_at descending (newest first)
            query = query.order("created_at", desc=True)
            
            if limit:
                query = query.limit(limit)
            
            response = query.execute()
            
            free_stories = []
            for story_data in response.data:
                # Handle created_at datetime conversion
                created_at = None
                if story_data.get('created_at'):
                    created_at_value = story_data['created_at']
                    if isinstance(created_at_value, datetime):
                        created_at = created_at_value
                    elif isinstance(created_at_value, str):
                        # Handle both 'Z' and '+00:00' timezone formats
                        created_at_str = created_at_value.replace('Z', '+00:00')
                        try:
                            created_at = datetime.fromisoformat(created_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse created_at: {created_at_value}")
                            created_at = None
                
                free_story = FreeStoryDB(
                    id=story_data.get('id'),
                    title=story_data.get('title'),
                    content=story_data.get('content'),
                    age_category=story_data.get('age_category'),
                    language=story_data.get('language'),
                    is_active=story_data.get('is_active', True),
                    created_at=created_at
                )
                free_stories.append(free_story)
            
            return free_stories
        except Exception as e:
            logger.error(f"Error retrieving free stories: {str(e)}")
            raise Exception(f"Error retrieving free stories: {str(e)}")
    
    def get_free_story(self, story_id: str) -> Optional[FreeStoryDB]:
        """Get a free story by ID.
        
        Args:
            story_id: The ID of the free story to retrieve
            
        Returns:
            The free story if found and active, None otherwise
        """
        try:
            response = self.client.table("free_stories").select("*").eq("id", story_id).eq("is_active", True).execute()
            
            if response.data:
                story_data = response.data[0]
                # Handle created_at datetime conversion
                created_at = None
                if story_data.get('created_at'):
                    created_at_value = story_data['created_at']
                    if isinstance(created_at_value, datetime):
                        created_at = created_at_value
                    elif isinstance(created_at_value, str):
                        # Handle both 'Z' and '+00:00' timezone formats
                        created_at_str = created_at_value.replace('Z', '+00:00')
                        try:
                            created_at = datetime.fromisoformat(created_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse created_at: {created_at_value}")
                            created_at = None
                
                return FreeStoryDB(
                    id=story_data.get('id'),
                    title=story_data.get('title'),
                    content=story_data.get('content'),
                    age_category=story_data.get('age_category'),
                    language=story_data.get('language'),
                    is_active=story_data.get('is_active', True),
                    created_at=created_at
                )
            return None
        except Exception as e:
            logger.error(f"Error retrieving free story: {str(e)}")
            raise Exception(f"Error retrieving free story: {str(e)}")
    
    def get_prompts(self, language: str, story_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """Get prompts from the database.
        
        Args:
            language: Language code ('en' or 'ru')
            story_type: Story type ('child', 'hero', 'combined') or None for universal
            
        Returns:
            List of prompt dictionaries
        """
        try:
            query = self.client.table("prompts").select("*")
            query = query.eq("language", language)
            query = query.eq("is_active", True)
            
            if story_type:
                query = query.or_(f"story_type.eq.{story_type},story_type.is.null")
            else:
                query = query.is_("story_type", "null")
            
            query = query.order("priority", desc=False)
            
            response = query.execute()
            return response.data if response.data else []
        except Exception as e:
            logger.error(f"Error retrieving prompts: {str(e)}")
            return []
    
    def create_prompt(self, prompt_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Create a new prompt in the database.
        
        Args:
            prompt_data: Dictionary with prompt fields (priority, language, story_type, prompt_text, etc.)
            
        Returns:
            Created prompt dictionary or None if failed
        """
        try:
            response = self.client.table("prompts").insert(prompt_data).execute()
            if response.data:
                logger.info(f"Created prompt with priority {prompt_data.get('priority')}")
                return response.data[0]
            return None
        except Exception as e:
            logger.error(f"Error creating prompt: {str(e)}")
            return None
    
    def update_prompt(self, prompt_id: str, prompt_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Update an existing prompt in the database.
        
        Args:
            prompt_id: ID of the prompt to update
            prompt_data: Dictionary with fields to update
            
        Returns:
            Updated prompt dictionary or None if failed
        """
        try:
            response = self.client.table("prompts").update(prompt_data).eq("id", prompt_id).execute()
            if response.data:
                logger.info(f"Updated prompt {prompt_id}")
                return response.data[0]
            return None
        except Exception as e:
            logger.error(f"Error updating prompt: {str(e)}")
            return None
    
    # Daily free stories methods
    
    def get_daily_stories(
        self,
        age_category: Optional[str] = None,
        language: Optional[str] = None,
        limit: Optional[int] = None,
        user_id: Optional[str] = None
    ) -> List[DailyFreeStoryDB]:
        """Get active daily free stories, optionally filtered by age category and language.
        
        Args:
            age_category: Optional age category filter ('2-3', '3-5', '5-7')
            language: Optional language filter ('en', 'ru')
            limit: Optional limit on number of results
            user_id: Optional user ID to get user's reaction
            
        Returns:
            List of active daily free stories, sorted by story_date DESC
        """
        try:
            query = self.client.table("daily_free_stories").select("*").eq("is_active", True)
            
            if age_category:
                query = query.eq("age_category", age_category)
            
            if language:
                query = query.eq("language", language)
            
            # Sort by story_date descending (newest first)
            query = query.order("story_date", desc=True)
            
            if limit:
                query = query.limit(limit)
            
            response = query.execute()
            
            daily_stories = []
            for story_data in response.data:
                # Handle datetime conversion
                created_at = None
                updated_at = None
                if story_data.get('created_at'):
                    created_at_value = story_data['created_at']
                    if isinstance(created_at_value, datetime):
                        created_at = created_at_value
                    elif isinstance(created_at_value, str):
                        created_at_str = created_at_value.replace('Z', '+00:00')
                        try:
                            created_at = datetime.fromisoformat(created_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse created_at: {created_at_value}")
                
                if story_data.get('updated_at'):
                    updated_at_value = story_data['updated_at']
                    if isinstance(updated_at_value, datetime):
                        updated_at = updated_at_value
                    elif isinstance(updated_at_value, str):
                        updated_at_str = updated_at_value.replace('Z', '+00:00')
                        try:
                            updated_at = datetime.fromisoformat(updated_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse updated_at: {updated_at_value}")
                
                daily_stories.append(DailyFreeStoryDB(
                    id=story_data.get('id'),
                    story_date=story_data.get('story_date'),
                    title=story_data.get('title'),
                    name=story_data.get('name'),
                    content=story_data.get('content'),
                    moral=story_data.get('moral'),
                    age_category=story_data.get('age_category'),
                    language=story_data.get('language'),
                    is_active=story_data.get('is_active', True),
                    created_at=created_at,
                    updated_at=updated_at
                ))
            
            return daily_stories
            
        except Exception as e:
            logger.error(f"Error retrieving daily free stories: {str(e)}")
            raise Exception(f"Error retrieving daily free stories: {str(e)}")
    
    def get_daily_story_by_date(
        self,
        story_date: str,
        user_id: Optional[str] = None
    ) -> Optional[DailyFreeStoryDB]:
        """Get a daily free story by date.
        
        Args:
            story_date: Date in YYYY-MM-DD format
            user_id: Optional user ID to get user's reaction
            
        Returns:
            The daily free story if found and active, None otherwise
        """
        try:
            query = self.client.table("daily_free_stories").select("*").eq("story_date", story_date).eq("is_active", True)
            response = query.execute()
            
            if response.data:
                story_data = response.data[0]
                # Handle datetime conversion
                created_at = None
                updated_at = None
                if story_data.get('created_at'):
                    created_at_value = story_data['created_at']
                    if isinstance(created_at_value, datetime):
                        created_at = created_at_value
                    elif isinstance(created_at_value, str):
                        created_at_str = created_at_value.replace('Z', '+00:00')
                        try:
                            created_at = datetime.fromisoformat(created_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse created_at: {created_at_value}")
                
                if story_data.get('updated_at'):
                    updated_at_value = story_data['updated_at']
                    if isinstance(updated_at_value, datetime):
                        updated_at = updated_at_value
                    elif isinstance(updated_at_value, str):
                        updated_at_str = updated_at_value.replace('Z', '+00:00')
                        try:
                            updated_at = datetime.fromisoformat(updated_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse updated_at: {updated_at_value}")
                
                return DailyFreeStoryDB(
                    id=story_data.get('id'),
                    story_date=story_data.get('story_date'),
                    title=story_data.get('title'),
                    name=story_data.get('name'),
                    content=story_data.get('content'),
                    moral=story_data.get('moral'),
                    age_category=story_data.get('age_category'),
                    language=story_data.get('language'),
                    is_active=story_data.get('is_active', True),
                    created_at=created_at,
                    updated_at=updated_at
                )
            return None
        except Exception as e:
            logger.error(f"Error retrieving daily free story by date: {str(e)}")
            raise Exception(f"Error retrieving daily free story by date: {str(e)}")
    
    def get_daily_story_by_id(
        self,
        story_id: str,
        user_id: Optional[str] = None
    ) -> Optional[DailyFreeStoryDB]:
        """Get a daily free story by ID.
        
        Args:
            story_id: The ID of the daily free story to retrieve
            user_id: Optional user ID to get user's reaction
            
        Returns:
            The daily free story if found and active, None otherwise
        """
        try:
            query = self.client.table("daily_free_stories").select("*").eq("id", story_id).eq("is_active", True)
            response = query.execute()
            
            if response.data:
                story_data = response.data[0]
                # Handle datetime conversion
                created_at = None
                updated_at = None
                if story_data.get('created_at'):
                    created_at_value = story_data['created_at']
                    if isinstance(created_at_value, datetime):
                        created_at = created_at_value
                    elif isinstance(created_at_value, str):
                        created_at_str = created_at_value.replace('Z', '+00:00')
                        try:
                            created_at = datetime.fromisoformat(created_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse created_at: {created_at_value}")
                
                if story_data.get('updated_at'):
                    updated_at_value = story_data['updated_at']
                    if isinstance(updated_at_value, datetime):
                        updated_at = updated_at_value
                    elif isinstance(updated_at_value, str):
                        updated_at_str = updated_at_value.replace('Z', '+00:00')
                        try:
                            updated_at = datetime.fromisoformat(updated_at_str)
                        except ValueError:
                            logger.warning(f"Could not parse updated_at: {updated_at_value}")
                
                return DailyFreeStoryDB(
                    id=story_data.get('id'),
                    story_date=story_data.get('story_date'),
                    title=story_data.get('title'),
                    name=story_data.get('name'),
                    content=story_data.get('content'),
                    moral=story_data.get('moral'),
                    age_category=story_data.get('age_category'),
                    language=story_data.get('language'),
                    is_active=story_data.get('is_active', True),
                    created_at=created_at,
                    updated_at=updated_at
                )
            return None
        except Exception as e:
            logger.error(f"Error retrieving daily free story by ID: {str(e)}")
            raise Exception(f"Error retrieving daily free story by ID: {str(e)}")
    
    # Daily story reactions methods
    
    def get_reaction_counts(self, story_id: str) -> Dict[str, int]:
        """Get reaction counts (likes and dislikes) for a story.
        
        Args:
            story_id: The ID of the story
            
        Returns:
            Dictionary with 'likes' and 'dislikes' counts
        """
        try:
            likes_response = self.client.table("daily_story_reactions").select("id", count="exact").eq("story_id", story_id).eq("reaction_type", "like").execute()
            dislikes_response = self.client.table("daily_story_reactions").select("id", count="exact").eq("story_id", story_id).eq("reaction_type", "dislike").execute()
            
            likes_count = likes_response.count if hasattr(likes_response, 'count') else len(likes_response.data) if likes_response.data else 0
            dislikes_count = dislikes_response.count if hasattr(dislikes_response, 'count') else len(dislikes_response.data) if dislikes_response.data else 0
            
            return {
                "likes": likes_count,
                "dislikes": dislikes_count
            }
        except Exception as e:
            logger.error(f"Error getting reaction counts: {str(e)}")
            return {"likes": 0, "dislikes": 0}
    
    def get_user_reaction(self, story_id: str, user_id: Optional[str] = None) -> Optional[str]:
        """Get user's reaction to a story.
        
        Args:
            story_id: The ID of the story
            user_id: Optional user ID (None for anonymous)
            
        Returns:
            Reaction type ('like' or 'dislike') or None if no reaction
        """
        try:
            query = self.client.table("daily_story_reactions").select("reaction_type").eq("story_id", story_id)
            
            if user_id:
                query = query.eq("user_id", user_id)
            else:
                query = query.is_("user_id", "null")
            
            response = query.execute()
            
            if response.data:
                return response.data[0].get('reaction_type')
            return None
        except Exception as e:
            logger.error(f"Error getting user reaction: {str(e)}")
            return None
    
    def create_or_update_reaction(
        self,
        story_id: str,
        reaction_type: str,
        user_id: Optional[str] = None
    ) -> Optional[DailyStoryReactionDB]:
        """Create or update a reaction to a daily story.
        
        Args:
            story_id: The ID of the story
            reaction_type: 'like' or 'dislike'
            user_id: Optional user ID (None for anonymous)
            
        Returns:
            The created or updated reaction
        """
        try:
            if reaction_type not in ['like', 'dislike']:
                raise ValueError("reaction_type must be 'like' or 'dislike'")
            
            # Check if reaction already exists
            query = self.client.table("daily_story_reactions").select("*").eq("story_id", story_id)
            if user_id:
                query = query.eq("user_id", user_id)
            else:
                query = query.is_("user_id", "null")
            
            existing = query.execute()
            
            reaction_data = {
                "story_id": story_id,
                "reaction_type": reaction_type,
                "user_id": user_id
            }
            
            if existing.data:
                # Update existing reaction
                reaction_id = existing.data[0]['id']
                response = self.client.table("daily_story_reactions").update(reaction_data).eq("id", reaction_id).execute()
                if response.data:
                    reaction_data = response.data[0]
                else:
                    return None
            else:
                # Create new reaction
                response = self.client.table("daily_story_reactions").insert(reaction_data).execute()
                if response.data:
                    reaction_data = response.data[0]
                else:
                    return None
            
            # Handle datetime conversion
            created_at = None
            updated_at = None
            if reaction_data.get('created_at'):
                created_at_value = reaction_data['created_at']
                if isinstance(created_at_value, datetime):
                    created_at = created_at_value
                elif isinstance(created_at_value, str):
                    created_at_str = created_at_value.replace('Z', '+00:00')
                    try:
                        created_at = datetime.fromisoformat(created_at_str)
                    except ValueError:
                        logger.warning(f"Could not parse created_at: {created_at_value}")
            
            if reaction_data.get('updated_at'):
                updated_at_value = reaction_data['updated_at']
                if isinstance(updated_at_value, datetime):
                    updated_at = updated_at_value
                elif isinstance(updated_at_value, str):
                    updated_at_str = updated_at_value.replace('Z', '+00:00')
                    try:
                        updated_at = datetime.fromisoformat(updated_at_str)
                    except ValueError:
                        logger.warning(f"Could not parse updated_at: {updated_at_value}")
            
            return DailyStoryReactionDB(
                id=reaction_data.get('id'),
                story_id=reaction_data.get('story_id'),
                user_id=reaction_data.get('user_id'),
                reaction_type=reaction_data.get('reaction_type'),
                created_at=created_at,
                updated_at=updated_at
            )
        except Exception as e:
            logger.error(f"Error creating/updating reaction: {str(e)}")
            raise Exception(f"Error creating/updating reaction: {str(e)}")