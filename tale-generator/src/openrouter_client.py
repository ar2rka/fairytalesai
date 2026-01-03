"""OpenRouter API client for story generation."""

import os
import asyncio
import logging
import time
import uuid
from enum import StrEnum
from typing import Optional, Dict, Any, List, Type, TypeVar
from pydantic import BaseModel, Field
import httpx
from openai import AsyncOpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Note: LangGraph workflow imports are done lazily inside generate_story()
# to avoid circular import issues with workflow_nodes.py

# Set up logger
logger = logging.getLogger("tale_generator.openrouter")

# Type variable for structured output models
T = TypeVar('T', bound=BaseModel)


def escape_quotes_in_json_strings(json_str: str) -> str:
    """Escape unescaped quotes inside JSON string values.
    
    This function finds all JSON string values and escapes any unescaped quotes
    inside them using regex pattern matching.
    
    Args:
        json_str: JSON string that may contain unescaped quotes in string values
        
    Returns:
        JSON string with properly escaped quotes
    """
    import re
    
    # Pattern to match JSON string values: "key": "value"
    # This pattern matches: "..." where ... can contain escaped characters
    # We'll use a more sophisticated approach: find all string values and fix them
    
    def fix_string_value(match):
        """Fix a single JSON string value by escaping unescaped quotes."""
        full_match = match.group(0)  # The full match including quotes
        content = match.group(1)  # Content inside quotes
        
        # Process content character by character to escape unescaped quotes
        result = []
        i = 0
        while i < len(content):
            if content[i] == '\\' and i + 1 < len(content):
                # This is an escape sequence, preserve it
                result.append(content[i])
                result.append(content[i + 1])
                i += 2
            elif content[i] == '"':
                # This is an unescaped quote inside the string, escape it
                result.append('\\"')
                i += 1
            else:
                result.append(content[i])
                i += 1
        
        return f'"{"".join(result)}"'
    
    # Pattern to match JSON string values
    # This matches: "key" or "value" where value can be any string
    # We need to be careful to only match string values, not keys
    # A simple approach: match all "..." patterns and fix them
    # But we need to distinguish between keys and values
    # Actually, let's just fix all string values - it's safer
    
    # Match all string patterns: "content"
    # But we need to handle the case where quotes might be unescaped
    # Use a greedy approach: find all "..." and fix the content
    
    # First, let's try a simpler approach: use state machine to find strings
    result = []
    i = 0
    in_string = False
    string_start = None
    
    while i < len(json_str):
        char = json_str[i]
        
        if not in_string:
            # We're not in a string
            result.append(char)
            if char == '"':
                # Start of a string
                in_string = True
                string_start = len(result) - 1
            i += 1
        else:
            # We're inside a string
            if char == '\\' and i + 1 < len(json_str):
                # Escape sequence
                result.append(char)
                result.append(json_str[i + 1])
                i += 2
            elif char == '"':
                # Check if this is the end of the string
                # Look ahead (skip whitespace and newlines) to see what comes next
                j = i + 1
                while j < len(json_str) and json_str[j] in ' \n\r\t':
                    j += 1
                
                if j >= len(json_str):
                    # End of input, this must be the closing quote
                    result.append(char)
                    in_string = False
                    string_start = None
                    i += 1
                elif json_str[j] in [':', ',', '}', ']']:
                    # This is the end of the string (followed by JSON structure)
                    result.append(char)
                    in_string = False
                    string_start = None
                    i += 1
                elif json_str[j] == '"':
                    # Two quotes in a row - this might be an empty string or error
                    # Check what comes after the second quote
                    k = j + 1
                    while k < len(json_str) and json_str[k] in ' \n\r\t':
                        k += 1
                    if k < len(json_str) and json_str[k] in [':', ',', '}', ']']:
                        # Empty string, close it
                        result.append(char)
                        in_string = False
                        string_start = None
                        i += 1
                    else:
                        # This is an unescaped quote inside the string
                        result.append('\\"')
                        i += 1
                else:
                    # This is an unescaped quote inside the string
                    result.append('\\"')
                    i += 1
            else:
                result.append(char)
                i += 1
    
    return ''.join(result)


def clean_json_string(json_str: str) -> str:
    """Clean JSON string from control characters and escape quotes.
    
    This function:
    - Escapes unescaped quotes in string values
    - Removes control characters from string values (inside quotes)
    - Preserves JSON structure (braces, brackets, commas, colons)
    - Handles escaped characters properly
    
    Args:
        json_str: Raw JSON string that may contain control characters and unescaped quotes
        
    Returns:
        Cleaned JSON string without control characters and with properly escaped quotes
    """
    import re
    
    # First, escape unescaped quotes in string values
    json_str = escape_quotes_in_json_strings(json_str)
    
    # Use a more sophisticated approach: find all string values and clean them
    # Pattern to match JSON string values, handling escaped quotes and backslashes
    # This pattern matches: "..." where ... can contain escaped characters
    string_pattern = r'"((?:[^"\\]|\\.)*)"'
    
    def clean_string_content(match):
        """Clean control characters from a JSON string value."""
        # Get the content inside quotes (group 1)
        content = match.group(1)
        
        # Remove control characters from content
        # Control characters are \x00-\x1f except \n (0x0a), \r (0x0d), \t (0x09)
        # But we need to be careful with escape sequences
        cleaned_content = []
        i = 0
        while i < len(content):
            char = content[i]
            # Check if this is part of an escape sequence
            if char == '\\' and i + 1 < len(content):
                # This is an escape sequence, preserve it
                cleaned_content.append(char)
                cleaned_content.append(content[i + 1])
                i += 2
            else:
                # Check if it's a control character (but not \n, \r, \t)
                char_code = ord(char)
                if char_code < 0x20 and char_code not in [0x09, 0x0a, 0x0d]:
                    # Skip this control character
                    i += 1
                else:
                    cleaned_content.append(char)
                    i += 1
        
        return f'"{"".join(cleaned_content)}"'
    
    # Replace all string values in JSON
    cleaned = re.sub(string_pattern, clean_string_content, json_str)
    
    # Also remove any control characters that might be outside of strings
    # (in JSON structure itself, which shouldn't happen but just in case)
    cleaned = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', cleaned)
    
    return cleaned


class StoryOutput(BaseModel):
    """Structured output model for story generation.
    
    This model ensures that the AI returns only the title and content
    without any introductory text or metadata.
    """
    title: str = Field(..., description="The title of the story (should NOT be included in content)")
    content: str = Field(..., description="The full story content WITHOUT the title. Only the story text itself, no title, no introductory text, no metadata.")


class OpenRouterModel(StrEnum):
    """Available OpenRouter models for story generation."""
    GPT_4O = "openai/gpt-4o"
    GPT_4O_MINI = "openai/gpt-4o-mini"
    CLAUDE_3_5_SONNET = "anthropic/claude-3.5-sonnet"
    CLAUDE_3_HAIKU = "anthropic/claude-3-haiku"
    CLAUDE_4_5_HAIKU = "anthropic/claude-haiku-4.5"
    LLAMA_3_1_405B = "meta-llama/llama-3.1-405b-instruct"
    LLAMA_3_1_70B = "meta-llama/llama-3.1-70b-instruct"
    LLAMA_3_1_8B = "meta-llama/llama-3.1-8b-instruct"
    GEMMA_2_27B = "google/gemma-2-27b-it"
    MIXTRAL_8X22B = "mistralai/mixtral-8x22b-instruct"
    GEMINI_20_FREE = "google/gemini-2.0-flash-exp:free"
    GROK_41_FREE = "x-ai/grok-4.1-fast:free"
    GPT_OSS_120B = "openai/gpt-oss-120b:exacto"
    MISTRAL_CREATIVE="mistralai/mistral-small-creative"
    MISTRAL_MEDIUM="mistralai/magistral-medium-2506"


# Default fallback models for rate limit retries (used if not configured via env)
DEFAULT_FALLBACK_MODELS = [
    OpenRouterModel.GPT_4O_MINI,
    OpenRouterModel.CLAUDE_3_HAIKU,
    OpenRouterModel.LLAMA_3_1_8B
]


class StoryGenerationResult:
    """Result of story generation including model info and full response."""
    
    def __init__(self, content: str, model: OpenRouterModel, full_response: Dict[str, Any], generation_info: Optional[Dict[str, Any]] = None, title: Optional[str] = None):
        self.content = content
        self.model = model
        self.full_response = full_response
        self.generation_info = generation_info
        self.title = title


class OpenRouterClient:
    """Client for interacting with OpenRouter API."""

    def __init__(self, api_key: Optional[str] = None):
        """Initialize the OpenRouter client.
        
        Args:
            api_key: OpenRouter API key. If not provided, will be loaded from 
                    OPENROUTER_API_KEY environment variable.
        """
        self.api_key = api_key or os.getenv("OPENROUTER_API_KEY")
        if not self.api_key:
            raise ValueError(
                "OpenRouter API key is required. "
                "Set OPENROUTER_API_KEY environment variable."
            )
        
        self.client = AsyncOpenAI(
            base_url="https://openrouter.ai/api/v1",
            api_key=self.api_key
        )
        self._http_client: Optional[httpx.AsyncClient] = None
        self._fallback_models: Optional[List[OpenRouterModel]] = None
    
    def _get_fallback_models(self) -> List[OpenRouterModel]:
        """Get fallback models from settings or use defaults.
        
        Returns:
            List of fallback models to try
        """
        if self._fallback_models is not None:
            return self._fallback_models
        
        # Try to load from settings
        try:
            from src.infrastructure.config.settings import get_settings
            settings = get_settings()
            fallback_model_str = settings.ai_service.fallback_model
            
            if fallback_model_str:
                # Try to convert string to OpenRouterModel
                try:
                    fallback_model = OpenRouterModel(fallback_model_str)
                    self._fallback_models = [fallback_model]
                    logger.info(f"Using configured fallback model: {fallback_model.value}")
                    return self._fallback_models
                except ValueError:
                    # Try to find by value
                    for model in OpenRouterModel:
                        if model.value == fallback_model_str:
                            self._fallback_models = [model]
                            logger.info(f"Using configured fallback model: {model.value}")
                            return self._fallback_models
                    logger.warning(
                        f"Configured fallback model '{fallback_model_str}' not found in OpenRouterModel enum, "
                        "using default fallback chain"
                    )
        except Exception as e:
            logger.debug(f"Could not load fallback model from settings: {e}, using defaults")
        
        # Use default fallback chain
        self._fallback_models = DEFAULT_FALLBACK_MODELS
        return self._fallback_models

    async def _get_http_client(self) -> httpx.AsyncClient:
        """Get or create async HTTP client with connection pooling."""
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(
                limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
                timeout=60.0
            )
        return self._http_client
    
    async def close(self):
        """Close the async HTTP client."""
        if self._http_client is not None:
            await self._http_client.aclose()
            self._http_client = None
    
    async def fetch_generation_info(self, generation_id: str) -> Optional[Dict[str, Any]]:
        """Fetch generation info from OpenRouter API.
        
        Args:
            generation_id: The ID of the generation to fetch info for
            
        Returns:
            Generation info dictionary or None if failed
        """
        try:
            logger.info(f"Fetching generation info for ID: {generation_id}")
            headers = {
                "Authorization": f"Bearer {self.api_key}",
            }
            
            generation_url = f"https://openrouter.ai/api/v1/generation?id={generation_id}"
            http_client = await self._get_http_client()
            response = await http_client.get(
                generation_url,
                headers=headers,
                timeout=30.0
            )
            
            if response.status_code == 200:
                generation_info = response.json()
                logger.info(f"Successfully fetched generation info for ID: {generation_id}")
                return generation_info
            else:
                logger.warning(f"Failed to fetch generation info ({generation_url}). Status code: {response.status_code}")
                return None
        except Exception as e:
            logger.error(f"Error fetching generation info: {str(e)}", exc_info=True)
            return None

    async def generate_structured_output(
        self,
        prompt: str,
        output_model: Type[T],
        model: OpenRouterModel = OpenRouterModel.CLAUDE_3_HAIKU,
        system_message: Optional[str] = None,
        max_tokens: int = 10000,
        temperature: float = 0.7,
        max_retries: int = 3,
        retry_delay: float = 1.0
    ) -> T:
        """Generate structured output using OpenRouter API with Pydantic model validation.
        
        This method uses OpenAI's structured output feature to automatically parse and validate
        the LLM response according to the provided Pydantic model schema. No manual JSON parsing needed.
        
        Example:
            >>> from pydantic import BaseModel
            >>> from typing import List
            >>>
            >>> class Assessment(BaseModel):
            ...     score: int
            ...     feedback: str
            ...     suggestions: List[str]
            >>>
            >>> result = await client.generate_structured_output(
            ...     prompt="Assess this story...",
            ...     output_model=Assessment,
            ...     model=OpenRouterModel.GPT_4O_MINI
            ... )
            >>> print(result.score)  # Access validated fields directly
        
        Args:
            prompt: The prompt to send to the model
            output_model: Pydantic BaseModel class that defines the expected output structure
            model: The model to use for generation
            system_message: Optional system message. If not provided, uses default.
            max_tokens: Maximum number of tokens to generate
            temperature: Sampling temperature (0.0 to 2.0)
            max_retries: Maximum number of retry attempts
            retry_delay: Initial delay between retries in seconds
            
        Returns:
            Instance of output_model with validated and parsed data
            
        Raises:
            Exception: If all retry attempts fail
        """
        default_system = "You are a helpful assistant. Always respond with valid JSON that matches the requested schema."
        system_msg = system_message or default_system
        
        # Use fallback models for rate limit retries
        fallback_models = self._get_fallback_models()
        models_to_try = [model] + fallback_models
        
        last_exception = None
        current_retry_delay = retry_delay
        
        # Try each model in the list
        for model_idx, current_model in enumerate(models_to_try):
            if model_idx > 0:
                logger.info(f"Trying fallback model {current_model.value} due to previous failure")
            
            # Attempt to generate with current model
            for attempt in range(max_retries + 1):
                response = None
                try:
                    logger.debug(
                        f"Attempting structured output with model {current_model.value} "
                        f"(attempt {attempt + 1}/{max_retries + 1})"
                    )
                    
                    # Use regular chat.completions.create with response_format instead of parse()
                    # This gives us more control over error handling
                    try:
                        response = await self.client.chat.completions.create(
                            model=current_model.value,
                            messages=[
                                {"role": "system", "content": system_msg},
                                {"role": "user", "content": prompt}
                            ],
                            response_format={"type": "json_object"},
                            max_tokens=max_tokens,
                            temperature=temperature,
                            top_p=0.88,
                            presence_penalty=1.2,
                            frequency_penalty=0.3
                        )
                    except Exception as api_error:
                        # If structured output API fails, try parse() as fallback
                        error_str = str(api_error)
                        if "control character" in error_str.lower() or "json_invalid" in error_str.lower():
                            # Try parse() method as it might handle it better
                            try:
                                response = await self.client.beta.chat.completions.parse(
                                    model=current_model.value,
                                    messages=[
                                        {"role": "system", "content": system_msg},
                                        {"role": "user", "content": prompt}
                                    ],
                                    response_format=output_model,
                                    max_tokens=max_tokens,
                                    temperature=temperature
                                )
                            except:
                                # If both fail, we'll handle it in the outer exception handler
                                raise api_error
                        else:
                            raise api_error
                    
                    # Extract message content
                    if not response or not response.choices:
                        raise ValueError("Empty response from API")
                    
                    message = response.choices[0].message
                    raw_content = message.content
                    
                    if not raw_content:
                        refusal_reason = getattr(message, 'refusal', None) or "Unknown reason"
                        raise ValueError(f"Empty content in response. Model refusal: {refusal_reason}")
                    
                    # Try to get parsed data if using parse() method
                    parsed_data = None
                    if hasattr(message, 'parsed') and message.parsed is not None:
                        parsed_data = message.parsed
                    else:
                        # Extract and parse JSON manually
                        import json
                        import re
                        
                        # Extract JSON from response
                        if "```json" in raw_content:
                            json_start = raw_content.find("```json") + 7
                            json_end = raw_content.find("```", json_start)
                            json_str = raw_content[json_start:json_end].strip()
                        elif "```" in raw_content:
                            json_start = raw_content.find("```") + 3
                            json_end = raw_content.find("```", json_start)
                            json_str = raw_content[json_start:json_end].strip()
                        elif "{" in raw_content and "}" in raw_content:
                            json_start = raw_content.find("{")
                            json_end = raw_content.rfind("}") + 1
                            json_str = raw_content[json_start:json_end]
                            # Ensure we have a closing brace
                            if not json_str.endswith("}"):
                                # Try to find the last closing brace more carefully
                                brace_count = 0
                                for i in range(json_start, len(raw_content)):
                                    if raw_content[i] == '{':
                                        brace_count += 1
                                    elif raw_content[i] == '}':
                                        brace_count -= 1
                                        if brace_count == 0:
                                            json_str = raw_content[json_start:i+1]
                                            break
                                # If still no closing brace, add one
                                if not json_str.endswith("}"):
                                    json_str += "}"
                        else:
                            json_str = raw_content
                        
                        # Clean control characters from JSON string using smart cleaning
                        # First pass: clean string values
                        json_str = clean_json_string(json_str)
                        
                        # Second pass: remove ALL control characters from entire JSON
                        # This is more aggressive but ensures no control characters remain
                        json_str = re.sub(r'[\x00-\x1f]', '', json_str)
                        if not json_str.endswith("}"):
                            json_str += "}"
                        
                        # Parse JSON with error recovery
                        data = None
                        try:
                            logger.warning(f"JSON string: {json_str}")
                            data = json.loads(json_str)
                        except json.JSONDecodeError as json_error:
                            logger.warning(f"JSON parse error: {str(json_error)}. Attempting regex extraction...")
                            
                            # Skip aggressive cleaning since we already did it
                            json_str_aggressive = json_str
                            
                            try:
                                data = json.loads(json_str_aggressive)
                                logger.info("Successfully parsed JSON after aggressive cleaning")
                            except json.JSONDecodeError:
                                # Last resort: try to extract fields using regex
                                logger.warning("Standard JSON parsing failed, trying regex extraction...")
                                try:
                                    # Extract title and content using regex as fallback
                                    # Use non-greedy matching and handle escaped characters
                                    title_match = re.search(r'"title"\s*:\s*"((?:[^"\\]|\\.)*)"', json_str_aggressive, re.DOTALL)
                                    content_match = re.search(r'"content"\s*:\s*"((?:[^"\\]|\\.)*)"', json_str_aggressive, re.DOTALL)
                                    
                                    if title_match and content_match:
                                        # Unescape JSON string values
                                        def unescape_json_string(s):
                                            """Unescape a JSON string value."""
                                            return (s
                                                .replace('\\"', '"')
                                                .replace('\\n', '\n')
                                                .replace('\\r', '\r')
                                                .replace('\\t', '\t')
                                                .replace('\\\\', '\\'))
                                        
                                        data = {
                                            "title": unescape_json_string(title_match.group(1)),
                                            "content": unescape_json_string(content_match.group(1))
                                        }
                                        logger.info("Successfully extracted JSON fields using regex fallback")
                                    else:
                                        raise json_error
                                except Exception as regex_error:
                                    logger.error(f"Regex extraction also failed: {str(regex_error)}")
                                    raise json_error
                        
                        # Clean string fields in data
                        if isinstance(data, dict):
                            for key, value in data.items():
                                if isinstance(value, str):
                                    # Remove control characters from string values
                                    data[key] = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', value)
                        
                        # Create model instance from parsed data
                        parsed_data = output_model(**data)
                    
                    # Clean content fields from control characters
                    if hasattr(parsed_data, 'content'):
                        import re
                        # Remove control characters (except \n, \r, \t)
                        parsed_data.content = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', parsed_data.content)
                    if hasattr(parsed_data, 'title'):
                        import re
                        parsed_data.title = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', parsed_data.title).strip()
                    
                    logger.info(f"Successfully generated structured output with model {current_model.value}")
                    return parsed_data
                    
                except Exception as e:
                    last_exception = e
                    error_str = str(e)
                    
                    # Check if this is a JSON parsing error with control characters
                    if ("control character" in error_str.lower() or "json_invalid" in error_str.lower()) and response:
                        logger.warning(
                            f"JSON parsing error with control characters detected. "
                            f"Attempting to extract and clean JSON from response..."
                        )
                        
                        try:
                            # Try to get raw content and parse it manually
                            if response and response.choices:
                                message = response.choices[0].message
                                raw_content = message.content
                                
                                if raw_content:
                                    import json
                                    import re
                                    
                                    # Extract JSON from response
                                    if "```json" in raw_content:
                                        json_start = raw_content.find("```json") + 7
                                        json_end = raw_content.find("```", json_start)
                                        json_str = raw_content[json_start:json_end].strip()
                                    elif "```" in raw_content:
                                        json_start = raw_content.find("```") + 3
                                        json_end = raw_content.find("```", json_start)
                                        json_str = raw_content[json_start:json_end].strip()
                                    elif "{" in raw_content and "}" in raw_content:
                                        json_start = raw_content.find("{")
                                        json_end = raw_content.rfind("}") + 1
                                        json_str = raw_content[json_start:json_end]
                                    else:
                                        json_str = raw_content
                                    
                                    # Clean control characters from JSON string
                                    # Remove all control characters
                                    json_str = re.sub(r'[\x00-\x1f]', '', json_str)
                                    
                                    # Parse JSON
                                    data = json.loads(json_str)
                                    
                                    # Clean string fields in data
                                    if isinstance(data, dict):
                                        for key, value in data.items():
                                            if isinstance(value, str):
                                                # Remove control characters from string values
                                                data[key] = re.sub(r'[\x00-\x1f]', '', value)
                                    
                                    # Create model instance from parsed data
                                    parsed_data = output_model(**data)
                                    
                                    # Clean content fields from control characters
                                    if hasattr(parsed_data, 'content'):
                                        parsed_data.content = re.sub(r'[\x00-\x1f]', '', parsed_data.content)
                                    if hasattr(parsed_data, 'title'):
                                        parsed_data.title = re.sub(r'[\x00-\x1f]', '', parsed_data.title).strip()
                                    
                                    logger.info(f"Successfully recovered structured output after cleaning control characters")
                                    return parsed_data
                        except Exception as recovery_error:
                            logger.warning(f"Failed to recover from JSON parsing error: {str(recovery_error)}")
                            # Continue with normal error handling
                    
                    # If this is a rate limit error (429), try the next model immediately
                    if "429" in error_str or "rate limit" in error_str.lower():
                        logger.warning(
                            f"Rate limit hit with model {current_model.value}. "
                            "Trying next fallback model..."
                        )
                        break  # Break inner loop to try next model
                    
                    # For other errors, retry with exponential backoff
                    if attempt < max_retries:
                        logger.warning(
                            f"Attempt {attempt + 1} failed: {error_str}. "
                            f"Retrying in {current_retry_delay} seconds..."
                        )
                        await asyncio.sleep(current_retry_delay)
                        # Exponential backoff
                        current_retry_delay *= 2
                    else:
                        logger.error(
                            f"All {max_retries + 1} attempts failed for model {current_model.value}. "
                            f"Last error: {error_str}"
                        )
            
            # Reset retry delay for next model
            current_retry_delay = retry_delay
        
        raise Exception(
            f"Error generating structured output after trying all fallback models. "
            f"Last error: {str(last_exception)}"
        )

    async def generate_story(
        self,
        prompt: str,
        model: OpenRouterModel = OpenRouterModel.CLAUDE_3_HAIKU,
        max_tokens: int = 10000,
        max_retries: int = 3,
        retry_delay: float = 1.0,
        temperature: float = 0.7,
        use_langgraph: bool = True,
        # Optional parameters for full workflow
        child_name: Optional[str] = None,
        child_gender: Optional[str] = None,
        child_interests: Optional[List[str]] = None,
        moral: Optional[str] = None,
        language: Optional[str] = "en",
        story_length_minutes: Optional[int] = 5,
        user_id: str = "",
        quality_threshold: Optional[int] = None,
        max_generation_attempts: Optional[int] = None
    ) -> StoryGenerationResult:
        """Generate a story using OpenRouter API with full LangGraph workflow (validation + quality assessment).
        
        Args:
            prompt: The prompt to send to the model
            model: The model to use for generation
            max_tokens: Maximum number of tokens to generate
            max_retries: Maximum number of retry attempts (for API calls)
            retry_delay: Delay between retries in seconds
            use_langgraph: Whether to use full LangGraph workflow with validation and quality assessment (default: True)
            child_name: Optional child name for workflow context (default: "Child")
            child_gender: Optional child gender for workflow context (default: "other")
            child_interests: Optional child interests for workflow context (default: ["stories"])
            moral: Optional moral value for the story (default: "kindness")
            language: Story language "en" or "ru" (default: "en")
            story_length_minutes: Story length in minutes (default: 5)
            user_id: Optional user ID for tracking
            quality_threshold: Minimum quality score to accept (default: from settings)
            max_generation_attempts: Maximum generation attempts in workflow (default: from settings)
            
        Returns:
            StoryGenerationResult containing the content, model used, full response, and generation info
        """
        if use_langgraph:
            # Use full LangGraph workflow with validation and quality assessment
            # Import workflow dependencies lazily to avoid circular imports
            from src.domain.services.langgraph.story_generation_workflow import create_workflow
            from src.domain.services.langgraph.workflow_state import (
                WorkflowStatus,
                create_initial_state
            )
            from src.domain.services.prompt_service import PromptService
            from src.domain.entities import Child
            from src.domain.value_objects import Language, Gender, StoryLength
            from src.infrastructure.config.settings import get_settings
            from src.core.constants import READING_SPEED_WPM
            
            logger.debug("Using full LangGraph workflow for story generation (with validation and quality assessment)")
            
            # Get settings for workflow configuration
            settings = get_settings()
            workflow_settings = settings.langgraph_workflow
            
            # Create default values for workflow context if not provided
            # But only use defaults if values are truly None/empty, not if they're explicitly passed
            if child_name is None or child_name == "":
                child_name = "Child"
                logger.warning("child_name was None or empty, using default 'Child'")
            if child_gender is None or child_gender == "":
                child_gender = "other"
            if child_interests is None or len(child_interests) == 0:
                child_interests = ["stories"]
            if moral is None or moral == "":
                moral = "kindness"
            if language is None or language == "":
                language = "en"
            if story_length_minutes is None or story_length_minutes == 0:
                story_length_minutes = 5
            
            # Default age_category if not provided
            child_age_category = "3-5"  # Default age category
            
            logger.debug(f"Using child_name={child_name}, child_age_category={child_age_category} for workflow")
            
            # Create child entity for workflow
            try:
                child = Child(
                    name=child_name,
                    age_category=child_age_category,
                    gender=Gender(child_gender),
                    interests=child_interests
                )
            except Exception as e:
                logger.warning(f"Failed to create child entity: {e}, using defaults")
                child = Child(
                    name="Child",
                    age_category="3-5",
                    gender=Gender.OTHER,
                    interests=["stories"]
                )
            
            # Create workflow state
            language_enum = Language.ENGLISH if language == "en" else Language.RUSSIAN
            story_length = StoryLength(minutes=story_length_minutes)
            expected_word_count = story_length_minutes * READING_SPEED_WPM
            
            # Generate unique generation_id for tracking
            generation_id = str(uuid.uuid4())
            
            initial_state = create_initial_state(
                original_prompt=prompt,
                child_id="",
                child_name=child.name,
                child_age_category=child.age_category,
                child_gender=child.gender.value,
                child_interests=child.interests or [],
                story_type="child",
                language=language,
                moral=moral,
                story_length=story_length_minutes,
                expected_word_count=expected_word_count,
                user_id=user_id,
                generation_id=generation_id,
                hero_id=None,
                hero_name=None,
                hero_description=None
            )
            
            # Create prompt service (needed for workflow)
            prompt_service = PromptService()
            
            # Create workflow with configuration
            workflow = create_workflow(
                openrouter_client=self,
                prompt_service=prompt_service,
                quality_threshold=quality_threshold or workflow_settings.quality_threshold,
                max_generation_attempts=max_generation_attempts or workflow_settings.max_generation_attempts,
                validation_model=workflow_settings.validation_model,
                assessment_model=workflow_settings.assessment_model,
                generation_model=model.value if model else workflow_settings.generation_model,
                first_attempt_temperature=workflow_settings.first_attempt_temperature,
                second_attempt_temperature=workflow_settings.second_attempt_temperature,
                third_attempt_temperature=workflow_settings.third_attempt_temperature
            )
            
            # Execute workflow
            logger.info("Executing full LangGraph workflow with validation and quality assessment...")
            final_state = await workflow.execute(initial_state)
            
            # Process workflow result
            workflow_status = final_state.get("workflow_status")
            
            if workflow_status == WorkflowStatus.REJECTED.value:
                validation_result = final_state.get("validation_result", {})
                reasoning = validation_result.get("reasoning", "Prompt validation failed")
                raise Exception(f"Prompt validation rejected: {reasoning}")
            
            if workflow_status == WorkflowStatus.FAILED.value:
                error_messages = final_state.get("error_messages", [])
                fatal_error = final_state.get("fatal_error", "Unknown error")
                error_msg = fatal_error if fatal_error else "; ".join(error_messages) if error_messages else "Workflow failed"
                raise Exception(f"Workflow execution failed: {error_msg}")
            
            if workflow_status != WorkflowStatus.SUCCESS.value:
                raise Exception(f"Workflow completed with unexpected status: {workflow_status}")
            
            # Extract best story from workflow result
            best_story = final_state.get("best_story")
            if not best_story:
                raise Exception("Workflow succeeded but no story was generated")
            
            story_content = best_story.get("content", "")
            story_title = best_story.get("title", "")
            
            if not story_content:
                raise Exception("Workflow succeeded but story content is empty")
            
            # Create response dict from workflow metadata
            generation_attempts = final_state.get("generation_attempts", [])
            first_attempt = generation_attempts[0] if generation_attempts else {}
            model_used_str = first_attempt.get("model_used", model.value)
            
            # Find which model was actually used
            fallback_models = self._get_fallback_models()
            model_used = model
            for m in [model] + fallback_models:
                if m.value == model_used_str:
                    model_used = m
                    break
            
            # Build full_response dict from workflow metadata
            full_response: Dict[str, Any] = {
                "workflow_status": workflow_status,
                "quality_score": final_state.get("best_story", {}).get("quality_assessment", {}).get("overall_score"),
                "selected_attempt": final_state.get("selected_attempt_number"),
                "total_attempts": len(generation_attempts),
                "validation_result": final_state.get("validation_result"),
                "workflow_metadata": {
                    "total_duration": final_state.get("total_duration"),
                    "validation_duration": final_state.get("validation_duration"),
                    "generation_duration": final_state.get("generation_duration"),
                    "assessment_duration": final_state.get("assessment_duration"),
                }
            }
            
            generation_info = None
            
            logger.info(f"Successfully generated story using LangGraph workflow. Quality score: {full_response.get('quality_score', 'N/A')}/10")
            
            return StoryGenerationResult(
                content=story_content,
                model=model_used,
                full_response=full_response,
                generation_info=generation_info,
                title=story_title
            )
        else:
            # Legacy direct API call (fallback)
            logger.debug("Using direct API call for story generation")
            
            # Normalize model to enum if it's a string
            if isinstance(model, str):
                try:
                    model = OpenRouterModel(model)
                except ValueError:
                    # If string doesn't match any enum, try to find by value
                    for m in OpenRouterModel:
                        if m.value == model:
                            model = m
                            break
                    else:
                        # Default to LLAMA_3_1_8B if not found
                        logger.warning(f"Unknown model string '{model}', using default LLAMA_3_1_8B")
                        model = OpenRouterModel.LLAMA_3_1_8B
            
            # Use fallback models for rate limit retries
            fallback_models = self._get_fallback_models()
            models_to_try = [model] + fallback_models
            
            last_exception = None
            current_retry_delay = retry_delay
            
            # Try each model in the list
            for model_idx, current_model in enumerate(models_to_try):
                # Get model string value (handle both enum and string)
                model_value = current_model.value if hasattr(current_model, 'value') else str(current_model)
                
                if model_idx > 0:
                    logger.info(f"Trying fallback model {model_value} due to previous failure")
                
                # Attempt to generate story with current model
                for attempt in range(max_retries + 1):
                    try:
                        logger.debug(f"Attempting to generate story with model {model_value} (attempt {attempt + 1}/{max_retries + 1})")
                        response = await self.client.chat.completions.create(
                            model=model_value,
                            messages=[
                                {"role": "system", "content": "You are a helpful assistant that creates bedtime stories for children."},
                                {"role": "user", "content": prompt}
                            ],
                            max_tokens=max_tokens,
                            temperature=temperature
                        )
                        
                        # Convert response to dict for storage
                        response_dict = response.model_dump()
                        
                        # Extract generation ID if available
                        generation_info = None
                        if response_dict.get('id'):
                            generation_id = response_dict['id']
                            #generation_info = await self.fetch_generation_info(generation_id)
                        
                        logger.info(f"Successfully generated story with model {model_value}")
                        # Ensure we return an enum, not a string
                        if isinstance(current_model, OpenRouterModel):
                            result_model = current_model
                        elif isinstance(model, OpenRouterModel):
                            result_model = model
                        else:
                            # Both are strings, use the one that was actually used
                            result_model = current_model  # This will be normalized below
                            # Normalize to enum
                            if isinstance(result_model, str):
                                try:
                                    result_model = OpenRouterModel(result_model)
                                except ValueError:
                                    # Try to find by value
                                    for m in OpenRouterModel:
                                        if m.value == result_model:
                                            result_model = m
                                            break
                                    else:
                                        # Default fallback
                                        result_model = OpenRouterModel.LLAMA_3_1_8B
                        
                        return StoryGenerationResult(
                            content=response.choices[0].message.content,
                            model=result_model,
                            full_response=response_dict,
                            generation_info=generation_info
                        )
                    except Exception as e:
                        last_exception = e
                        # If this is a rate limit error (429), try the next model immediately
                        if "429" in str(e) or "rate limit" in str(e).lower():
                            logger.warning(f"Rate limit hit with model {model_value}. Trying next fallback model...")
                            break  # Break inner loop to try next model
                        
                        # For other errors, retry with exponential backoff
                        if attempt < max_retries:
                            logger.warning(f"Attempt {attempt + 1} failed: {str(e)}. Retrying in {current_retry_delay} seconds...")
                            await asyncio.sleep(current_retry_delay)
                            # Exponential backoff
                            current_retry_delay *= 2
                        else:
                            logger.error(f"All {max_retries + 1} attempts failed for model {model_value}. Last error: {str(last_exception)}")
                
                # Reset retry delay for next model
                current_retry_delay = retry_delay
            
            raise Exception(f"Error generating story after trying all fallback models. Last error: {str(last_exception)}")