"""Provider registry for managing multiple voice-over providers."""

import os
import logging
from typing import Dict, Optional, List
from .base_provider import VoiceProvider

# Set up logger
logger = logging.getLogger("tale_generator.voice_provider.registry")


class VoiceProviderRegistry:
    """Registry for managing voice-over providers."""
    
    def __init__(self):
        """Initialize the provider registry."""
        self._providers: Dict[str, VoiceProvider] = {}
        self._default_provider: Optional[str] = None
        self._fallback_providers: List[str] = []
        
        # Load configuration from environment
        self._load_configuration()
    
    def _load_configuration(self):
        """Load provider configuration from environment variables."""
        # Get default provider from environment
        self._default_provider = os.getenv("DEFAULT_VOICE_PROVIDER", "elevenlabs")
        
        # Get fallback providers
        fallback_str = os.getenv("VOICE_PROVIDER_FALLBACK", "")
        if fallback_str:
            self._fallback_providers = [p.strip() for p in fallback_str.split(",") if p.strip()]
        
        logger.info(f"Voice provider configuration loaded: default={self._default_provider}, fallback={self._fallback_providers}")
    
    def register(self, provider: VoiceProvider) -> None:
        """Register a voice provider.
        
        Args:
            provider: The provider instance to register
            
        Raises:
            ValueError: If a provider with the same name is already registered
        """
        provider_name = provider.metadata.provider_name
        
        if provider_name in self._providers:
            logger.warning(f"Provider {provider_name} is already registered, replacing with new instance")
        
        # Validate provider configuration
        if not provider.validate_configuration():
            logger.warning(f"Provider {provider_name} configuration is invalid, but registering anyway")
        
        self._providers[provider_name] = provider
        logger.info(f"Registered voice provider: {provider.metadata.display_name} ({provider_name})")
    
    def unregister(self, provider_name: str) -> bool:
        """Unregister a voice provider.
        
        Args:
            provider_name: The name of the provider to unregister
            
        Returns:
            True if provider was unregistered, False if not found
        """
        if provider_name in self._providers:
            del self._providers[provider_name]
            logger.info(f"Unregistered voice provider: {provider_name}")
            return True
        return False
    
    def get_provider(self, provider_name: Optional[str] = None) -> Optional[VoiceProvider]:
        """Get a specific provider or the default provider.
        
        Args:
            provider_name: Name of the provider to retrieve, or None for default
            
        Returns:
            The requested provider, or None if not found
        """
        # If no provider specified, use default
        if provider_name is None:
            provider_name = self._default_provider
        
        # Try to get the requested provider
        provider = self._providers.get(provider_name)
        
        if provider:
            # Validate that the provider is ready
            if provider.validate_configuration():
                logger.debug(f"Retrieved provider: {provider_name}")
                return provider
            else:
                logger.warning(f"Provider {provider_name} configuration is invalid")
                return None
        else:
            logger.warning(f"Provider {provider_name} not found in registry")
            return None
    
    def get_provider_with_fallback(self, provider_name: Optional[str] = None) -> Optional[VoiceProvider]:
        """Get a provider with automatic fallback to alternatives.
        
        Args:
            provider_name: Name of the preferred provider, or None for default
            
        Returns:
            A valid provider instance, or None if no providers are available
        """
        # Try the requested provider first
        provider = self.get_provider(provider_name)
        if provider:
            logger.info(f"Using voice provider: {provider.metadata.display_name}")
            return provider
        
        # If requested provider failed, try default (if different)
        if provider_name and provider_name != self._default_provider:
            logger.info(f"Requested provider {provider_name} unavailable, trying default: {self._default_provider}")
            provider = self.get_provider(self._default_provider)
            if provider:
                logger.info(f"Using default voice provider: {provider.metadata.display_name}")
                return provider
        
        # Try fallback providers in order
        for fallback_name in self._fallback_providers:
            if fallback_name != provider_name and fallback_name != self._default_provider:
                logger.info(f"Trying fallback provider: {fallback_name}")
                provider = self.get_provider(fallback_name)
                if provider:
                    logger.info(f"Using fallback voice provider: {provider.metadata.display_name}")
                    return provider
        
        # If all else fails, try any available provider
        for available_name, available_provider in self._providers.items():
            if available_provider.validate_configuration():
                logger.warning(f"All configured providers failed, using first available: {available_name}")
                return available_provider
        
        # No providers available
        logger.error("No voice providers available")
        return None
    
    def list_providers(self) -> List[str]:
        """Get list of all registered provider names.
        
        Returns:
            List of provider names
        """
        return list(self._providers.keys())
    
    def list_available_providers(self) -> List[str]:
        """Get list of providers that are properly configured.
        
        Returns:
            List of provider names that pass validation
        """
        return [
            name for name, provider in self._providers.items()
            if provider.validate_configuration()
        ]
    
    def get_default_provider_name(self) -> Optional[str]:
        """Get the name of the default provider.
        
        Returns:
            Default provider name
        """
        return self._default_provider
    
    def set_default_provider(self, provider_name: str) -> bool:
        """Set the default provider.
        
        Args:
            provider_name: Name of the provider to set as default
            
        Returns:
            True if successful, False if provider not found
        """
        if provider_name in self._providers:
            self._default_provider = provider_name
            logger.info(f"Default provider set to: {provider_name}")
            return True
        else:
            logger.warning(f"Cannot set default provider to {provider_name}: not found")
            return False
    
    def clear(self) -> None:
        """Clear all registered providers."""
        self._providers.clear()
        logger.info("All providers cleared from registry")


# Global registry instance
_global_registry: Optional[VoiceProviderRegistry] = None


def get_registry() -> VoiceProviderRegistry:
    """Get the global provider registry instance.
    
    Returns:
        The global registry instance
    """
    global _global_registry
    if _global_registry is None:
        _global_registry = VoiceProviderRegistry()
    return _global_registry


def reset_registry() -> None:
    """Reset the global registry (mainly for testing)."""
    global _global_registry
    _global_registry = None
