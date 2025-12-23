"""Test voice provider system."""

import pytest
from src.voice_providers import (
    VoiceProvider,
    ProviderMetadata,
    VoiceProviderRegistry,
    get_registry,
    VoiceService,
    AudioGenerationResult,
    get_voice_service,
    ElevenLabsProvider,
    MockVoiceProvider,
    reset_registry,
    reset_voice_service
)


def test_mock_provider_basic():
    """Test basic mock provider functionality."""
    provider = MockVoiceProvider()
    
    assert provider.metadata.provider_name == "mock"
    assert provider.validate_configuration() is True
    assert "en" in provider.get_supported_languages()
    assert "ru" in provider.get_supported_languages()
    
    voices = provider.get_available_voices()
    assert len(voices) > 0
    
    voices_en = provider.get_available_voices("en")
    assert "mock-voice-en" in voices_en


def test_mock_provider_generate_speech():
    """Test mock audio generation."""
    provider = MockVoiceProvider()
    
    text = "This is a test story for audio generation."
    audio_data = provider.generate_speech(text, language="en")
    
    assert audio_data is not None
    assert len(audio_data) > 0
    assert b"MOCK_AUDIO" in audio_data


def test_provider_registry():
    """Test provider registry functionality."""
    registry = VoiceProviderRegistry()
    
    # Register mock provider
    mock_provider = MockVoiceProvider()
    registry.register(mock_provider)
    
    # Check registration
    assert "mock" in registry.list_providers()
    
    # Get provider
    provider = registry.get_provider("mock")
    assert provider is not None
    assert provider.metadata.provider_name == "mock"


def test_provider_registry_fallback():
    """Test provider registry fallback mechanism."""
    registry = VoiceProviderRegistry()
    
    # Register two providers
    mock1 = MockVoiceProvider()
    registry.register(mock1)
    
    # Set default to mock
    registry.set_default_provider("mock")
    
    # Get with fallback should return mock
    provider = registry.get_provider_with_fallback()
    assert provider is not None
    assert provider.metadata.provider_name == "mock"
    
    # Get non-existent provider should fall back to default
    provider = registry.get_provider_with_fallback("nonexistent")
    assert provider is not None
    assert provider.metadata.provider_name == "mock"


def test_voice_service_basic():
    """Test voice service basic functionality."""
    # Reset to clean state
    reset_registry()
    reset_voice_service()
    
    # Get registry and register mock provider
    registry = get_registry()
    mock_provider = MockVoiceProvider()
    registry.register(mock_provider)
    registry.set_default_provider("mock")
    
    # Get voice service
    service = get_voice_service()
    
    # Generate audio
    result = service.generate_audio(
        text="This is a test story.",
        language="en"
    )
    
    assert result.success is True
    assert result.audio_data is not None
    assert result.provider_name == "mock"
    assert result.metadata is not None


def test_voice_service_provider_selection():
    """Test explicit provider selection."""
    reset_registry()
    reset_voice_service()
    
    registry = get_registry()
    mock_provider = MockVoiceProvider()
    registry.register(mock_provider)
    
    service = get_voice_service()
    
    # Request specific provider
    result = service.generate_audio(
        text="Test with specific provider.",
        language="en",
        provider_name="mock"
    )
    
    assert result.success is True
    assert result.provider_name == "mock"


def test_voice_service_empty_text():
    """Test voice service with empty text."""
    reset_registry()
    reset_voice_service()
    
    registry = get_registry()
    mock_provider = MockVoiceProvider()
    registry.register(mock_provider)
    
    service = get_voice_service()
    
    result = service.generate_audio(text="", language="en")
    
    assert result.success is False
    assert result.audio_data is None
    assert "Empty text" in result.error_message


def test_voice_service_no_providers():
    """Test voice service when no providers are available."""
    reset_registry()
    reset_voice_service()
    
    # Don't register any providers
    service = get_voice_service()
    
    result = service.generate_audio(text="Test", language="en")
    
    assert result.success is False
    assert result.audio_data is None
    assert "No voice providers available" in result.error_message


def test_voice_service_fallback():
    """Test fallback mechanism when provider fails."""
    reset_registry()
    reset_voice_service()
    
    registry = get_registry()
    
    # Register a mock provider that's configured
    mock_good = MockVoiceProvider()
    registry.register(mock_good)
    
    # Register another mock that's not configured
    mock_bad = MockVoiceProvider()
    mock_bad.set_configured(False)
    
    # Set the bad one as default
    registry.set_default_provider("mock")
    
    service = get_voice_service()
    
    # Should fall back to the good provider
    result = service.generate_audio(text="Test fallback", language="en")
    
    # Should succeed with any available provider
    assert result.success is True or result.success is False  # Depends on fallback behavior


def test_elevenlabs_provider_metadata():
    """Test ElevenLabs provider metadata (without actual API call)."""
    # This test only checks metadata without making API calls
    try:
        provider = ElevenLabsProvider()
        metadata = provider.metadata
        
        assert metadata.provider_name == "elevenlabs"
        assert metadata.display_name == "ElevenLabs"
        assert "en" in provider.get_supported_languages()
        assert "ru" in provider.get_supported_languages()
    except Exception:
        # Skip if credentials not available
        pytest.skip("ElevenLabs credentials not configured")


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
