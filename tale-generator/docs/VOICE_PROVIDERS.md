# Voice Provider System

## Overview

The tale-generator now supports multiple voice-over providers through a flexible, extensible architecture. This allows you to easily switch between different text-to-speech services or add new providers without modifying the core application logic.

## Architecture

### Components

1. **VoiceProvider (Base Interface)**: Abstract base class that all providers must implement
2. **VoiceProviderRegistry**: Manages registered providers and handles provider discovery
3. **VoiceService**: Facade that orchestrates provider selection, audio generation, and fallback logic
4. **Provider Implementations**: Concrete implementations for specific services (ElevenLabs, Mock, etc.)

### Current Providers

- **ElevenLabs**: Production-ready provider using ElevenLabs API
- **Mock**: Testing provider that generates fake audio without API costs

## Configuration

### Environment Variables

```bash
# Default provider to use (optional, defaults to "elevenlabs")
DEFAULT_VOICE_PROVIDER=elevenlabs

# Comma-separated list of fallback providers (optional)
VOICE_PROVIDER_FALLBACK=mock

# Provider-specific credentials
ELEVENLABS_API_KEY=your-api-key-here
```

## Usage

### Basic API Request

Generate a story with audio using the default provider:

```json
POST /generate-story
{
  "child": {
    "name": "Emma",
    "age": 5,
    "gender": "female",
    "interests": ["unicorns", "rainbows"]
  },
  "moral": "kindness",
  "language": "en",
  "generate_audio": true
}
```

### Specify Provider

Choose a specific voice provider:

```json
POST /generate-story
{
  "child": {
    "name": "Emma",
    "age": 5,
    "gender": "female",
    "interests": ["unicorns", "rainbows"]
  },
  "moral": "kindness",
  "language": "en",
  "generate_audio": true,
  "voice_provider": "elevenlabs"
}
```

### Provider-Specific Options

Pass custom options to the provider:

```json
POST /generate-story
{
  "child": {
    "name": "Emma",
    "age": 5,
    "gender": "female",
    "interests": ["unicorns", "rainbows"]
  },
  "moral": "kindness",
  "language": "en",
  "generate_audio": true,
  "voice_provider": "elevenlabs",
  "voice_options": {
    "voice_id": "21m00Tcm4TlvDq8ikWAM",
    "model_id": "eleven_multilingual_v2"
  }
}
```

## Adding a New Provider

### Step 1: Create Provider Class

Create a new file `src/voice_providers/your_provider.py`:

```python
from typing import Optional, List, Dict, Any
from .base_provider import VoiceProvider, ProviderMetadata

class YourProvider(VoiceProvider):
    def __init__(self):
        self._metadata = ProviderMetadata(
            provider_name="yourprovider",
            display_name="Your Provider Name",
            supports_streaming=False,
            max_text_length=5000,
            supported_formats=["mp3"]
        )
        # Initialize your provider
    
    @property
    def metadata(self) -> ProviderMetadata:
        return self._metadata
    
    def validate_configuration(self) -> bool:
        # Check if API keys and config are valid
        return True
    
    def get_supported_languages(self) -> List[str]:
        return ["en", "ru", "es"]  # Your supported languages
    
    def get_available_voices(self, language: Optional[str] = None) -> List[str]:
        # Return list of voice IDs
        return ["voice-1", "voice-2"]
    
    def generate_speech(
        self,
        text: str,
        language: str = "en",
        voice_options: Optional[Dict[str, Any]] = None
    ) -> Optional[bytes]:
        # Call your provider's API
        # Return audio bytes or None
        pass
```

### Step 2: Register Provider

In `src/api/routes.py`, register your provider:

```python
from src.voice_providers import YourProvider

# In the initialization section
try:
    your_provider = YourProvider()
    voice_registry.register(your_provider)
    logger.info("Your provider registered successfully")
except Exception as e:
    logger.warning(f"Your provider registration failed: {e}")
```

### Step 3: Export Provider

Add to `src/voice_providers/__init__.py`:

```python
from .your_provider import YourProvider

__all__ = [
    # ... existing exports
    "YourProvider",
]
```

## Programmatic Usage

### Using the Voice Service Directly

```python
from src.voice_providers import get_voice_service

service = get_voice_service()

# Generate audio with default provider
result = service.generate_audio(
    text="Once upon a time...",
    language="en"
)

if result.success:
    audio_data = result.audio_data
    provider_name = result.provider_name
    print(f"Generated {len(audio_data)} bytes with {provider_name}")
else:
    print(f"Error: {result.error_message}")
```

### Using a Specific Provider

```python
result = service.generate_audio(
    text="Once upon a time...",
    language="en",
    provider_name="elevenlabs",
    voice_options={"voice_id": "custom-voice-id"}
)
```

### Working with the Registry

```python
from src.voice_providers import get_registry, MockVoiceProvider

registry = get_registry()

# Register a provider
mock = MockVoiceProvider()
registry.register(mock)

# List available providers
providers = registry.list_available_providers()
print(f"Available: {providers}")

# Get a specific provider
provider = registry.get_provider("mock")
```

## Fallback Mechanism

The system automatically tries fallback providers when the primary provider fails:

1. Use explicitly requested provider (if specified)
2. Fall back to configured default provider
3. Try fallback providers from `VOICE_PROVIDER_FALLBACK`
4. Use any available configured provider
5. Return error if all providers fail

This ensures maximum reliability for audio generation.

## Database Tracking

The system tracks which provider generated each audio file:

- `audio_provider`: Name of the provider used (e.g., "elevenlabs", "mock")
- `audio_generation_metadata`: JSON object with provider-specific details

This enables:
- Cost analysis per provider
- Quality comparison
- Debugging audio generation issues
- Usage analytics

## Testing

### Using the Mock Provider

The mock provider generates fake audio for testing:

```python
from src.voice_providers import MockVoiceProvider, get_registry

# Register mock provider
registry = get_registry()
mock = MockVoiceProvider()
registry.register(mock)
registry.set_default_provider("mock")

# Now all audio generation will use mock provider
# No API costs, instant response
```

### Running Tests

```bash
uv run python test_voice_providers.py
```

## Migration

### Database Migration

Apply the migration to add audio provider tracking:

```bash
uv run python -c "
from src.supabase_client import SupabaseClient
client = SupabaseClient()
# Execute migration 008_add_audio_provider_tracking.sql
"
```

Or apply via Supabase CLI:

```bash
supabase db push --include-all
```

## Troubleshooting

### No providers available

**Problem**: Getting "No voice providers available" error

**Solution**: 
- Check that at least one provider is registered
- Verify provider credentials are configured
- Check provider validation (run `provider.validate_configuration()`)

### Provider configuration invalid

**Problem**: Provider validation fails

**Solution**:
- Verify API keys are set in environment variables
- Check that the provider's external service is accessible
- Review provider-specific documentation

### Audio generation fails silently

**Problem**: Audio not generated but no error

**Solution**:
- Check logs for provider-specific errors
- Verify text is not empty
- Ensure child_id is available (required for storage)
- Check Supabase storage bucket permissions

## Future Enhancements

Potential providers to add:
- Google Cloud Text-to-Speech
- Amazon Polly
- Azure Speech Service
- OpenAI TTS
- Coqui TTS (self-hosted)

## Related Files

- `src/voice_providers/base_provider.py` - Base interface
- `src/voice_providers/provider_registry.py` - Provider registry
- `src/voice_providers/voice_service.py` - Voice service facade
- `src/voice_providers/elevenlabs_provider.py` - ElevenLabs implementation
- `src/voice_providers/mock_provider.py` - Mock provider
- `src/api/routes.py` - API integration
- `supabase/migrations/008_add_audio_provider_tracking.sql` - Database migration
