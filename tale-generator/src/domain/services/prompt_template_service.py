"""Service for rendering prompt templates using Jinja2."""

from typing import Optional, Dict, Any, Protocol
from jinja2 import Environment, Template
from jinja2.sandbox import SandboxedEnvironment
from src.domain.value_objects import Language
from src.prompts.character_types.base import BaseCharacter
from src.infrastructure.persistence.models import StoryDB, PromptDB
from src.utils.jinja_helpers import register_jinja_filters
from src.core.logging import get_logger
from src.core.constants import READING_SPEED_WPM

logger = get_logger("domain.prompt_template_service")


class PromptLoader(Protocol):
    """Protocol for loading prompt parts (file or DB)."""

    def get_prompts(
        self, language: Language, story_type: Optional[str] = None
    ) -> list:
        ...


class PromptTemplateService:
    """Service for rendering prompt templates using Jinja2 (from files or DB)."""

    def __init__(self, prompt_loader: PromptLoader):
        """Initialize prompt template service.

        Args:
            prompt_loader: Loader with get_prompts(language, story_type) -> List[PromptDB]
        """
        self._loader = prompt_loader
        # Use SandboxedEnvironment for security
        self._jinja_env = SandboxedEnvironment(
            autoescape=False,  # We're not rendering HTML
            trim_blocks=True,
            lstrip_blocks=True
        )
        # Register custom filters
        register_jinja_filters(self._jinja_env)
        logger.info("PromptTemplateService initialized")

    def render_prompt(
        self,
        character: BaseCharacter,
        moral: str,
        language: Language,
        story_length: int,
        story_type: str,
        parent_story: Optional[StoryDB] = None,
        theme: Optional[str] = None,
        plot: Optional[str] = None
    ) -> str:
        """Render complete prompt from templates.
        
        Loads all prompt parts for the given language and story_type,
        renders each part with Jinja, and combines them by priority.
        
        Args:
            character: Character object (ChildCharacter, HeroCharacter, or CombinedCharacter)
            moral: Moral value for the story
            language: Target language
            story_length: Story length in minutes
            story_type: Story type ('child', 'hero', 'combined')
            parent_story: Optional parent story for continuation narratives
            theme: Optional story theme / type (e.g. adventure, space, fantasy)
            
        Returns:
            Complete rendered prompt string
        """
        # Load prompt parts from loader (files or DB)
        logger.info(f"Loading prompts: language={language.value}, story_type={story_type}")
        prompt_parts = self._loader.get_prompts(language, story_type)

        if not prompt_parts:
            raise ValueError(
                f"No prompts found for language={language.value}, story_type={story_type}. "
                f"Add template e.g. src/prompts/templates/{story_type}_{language.value}.md"
            )
        
        # Calculate word count
        word_count = story_length * READING_SPEED_WPM
        
        # Prepare context for Jinja templates
        context = self._build_context(
            character=character,
            moral=moral,
            language=language,
            story_length=story_length,
            word_count=word_count,
            story_type=story_type,
            parent_story=parent_story,
            theme=theme,
            plot=plot
        )
        
        # Render each prompt part
        rendered_parts = []
        for prompt_part in prompt_parts:
            try:
                template = self._jinja_env.from_string(prompt_part.prompt_text)
                rendered = template.render(**context)
                
                # Only add non-empty rendered parts
                if rendered and rendered.strip():
                    rendered_parts.append(rendered.strip())
            except Exception as e:
                logger.error(
                    f"Error rendering prompt part (priority={prompt_part.priority}): {str(e)}",
                    exc_info=True
                )
                # Continue with other parts even if one fails
                continue
        
        # Combine parts with double newline
        final_prompt = "\n\n".join(rendered_parts).strip()
        
        logger.debug(
            f"Rendered prompt with {len(rendered_parts)} parts "
            f"for language={language.value}, story_type={story_type}"
        )
        
        return final_prompt
    
    def _build_context(
        self,
        character: BaseCharacter,
        moral: str,
        language: Language,
        story_length: int,
        word_count: int,
        story_type: str,
        parent_story: Optional[StoryDB],
        theme: Optional[str] = None,
        plot: Optional[str] = None
    ) -> Dict[str, Any]:
        """Build context dictionary for Jinja templates.
        
        Args:
            character: Character object
            moral: Moral value
            language: Target language
            story_length: Story length in minutes
            word_count: Word count
            story_type: Story type
            parent_story: Optional parent story
            theme: Optional story theme (e.g. adventure, space)
            
        Returns:
            Context dictionary for Jinja rendering
        """
        context = {
            "moral": moral,
            "language": language,
            "story_length": story_length,
            "word_count": word_count,
            "story_type": story_type,
            "parent_story": parent_story,
            "theme": theme or "adventure",  # API sends English; templates use translate_theme(language)
            "plot": plot,
        }
        
        # Add character data based on type
        char_data = character.get_description_data()
        char_type = char_data.get("character_type")
        
        if char_type == "child":
            context["child"] = character
            # Also add direct access to child properties for convenience
            context["child_name"] = char_data.get("name")
            context["age_category"] = char_data.get("age_category")
            context["child_gender"] = char_data.get("gender")
            context["child_interests"] = char_data.get("interests", [])
            context["child_description"] = char_data.get("description")
        elif char_type == "hero":
            context["hero"] = character
            context["hero_name"] = char_data.get("name")
            context["hero_age"] = char_data.get("age")
            context["hero_gender"] = char_data.get("gender")
            context["hero_appearance"] = char_data.get("appearance")
            context["hero_personality_traits"] = char_data.get("personality_traits", [])
            context["hero_strengths"] = char_data.get("strengths", [])
            context["hero_interests"] = char_data.get("interests", [])
            context["hero_description"] = char_data.get("description")
        elif char_type == "combined":
            context["child"] = character.child
            context["hero"] = character.hero
            child_data = char_data.get("child", {})
            hero_data = char_data.get("hero", {})
            context["child_name"] = child_data.get("name")
            context["age_category"] = child_data.get("age_category")
            context["child_gender"] = child_data.get("gender")
            context["child_interests"] = child_data.get("interests", [])
            context["hero_name"] = hero_data.get("name")
            context["hero_age"] = hero_data.get("age")
            context["hero_gender"] = hero_data.get("gender")
            context["hero_appearance"] = hero_data.get("appearance")
            context["hero_personality_traits"] = hero_data.get("personality_traits", [])
            context["hero_strengths"] = hero_data.get("strengths", [])
            context["hero_interests"] = hero_data.get("interests", [])
            context["relationship"] = char_data.get("relationship")
            context["merged_interests"] = char_data.get("merged_interests", [])
        
        return context

