"""Test script to verify retry functionality."""

from src.openrouter_client import OpenRouterClient, OpenRouterModel
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_retry_functionality():
    """Test the retry functionality of the OpenRouter client."""
    try:
        # Check if API key is available
        api_key = os.getenv("OPENROUTER_API_KEY")
        if not api_key:
            print("Skipping test - OPENROUTER_API_KEY not set")
            return
            
        # Initialize client
        client = OpenRouterClient()
        
        # Test with a simple prompt
        prompt = "Write a very short children's story (2-3 sentences) about a brave rabbit."
        
        print("Testing retry functionality...")
        print(f"Using model: {OpenRouterModel.GPT_4O_MINI.value}")
        print(f"Prompt: {prompt}")
        print()
        
        # Generate story with retry functionality
        result = client.generate_story(
            prompt,
            model=OpenRouterModel.GPT_4O_MINI,
            max_tokens=100,
            max_retries=3,
            retry_delay=1.0
        )
        
        print("✓ Story generated successfully!")
        print(f"Model used: {result.model.value}")
        print(f"Content length: {len(result.content)} characters")
        print()
        print("Generated story:")
        print("-" * 40)
        print(result.content)
        print("-" * 40)
        
    except Exception as e:
        print(f"Error in retry functionality test: {e}")

if __name__ == "__main__":
    test_retry_functionality()