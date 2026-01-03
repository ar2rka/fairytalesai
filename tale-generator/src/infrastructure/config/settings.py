"""Application configuration using Pydantic Settings."""

from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from src.core.constants import (
    DEFAULT_SCHEMA,
    DEFAULT_LOG_LEVEL,
    DEFAULT_MAX_RETRIES,
    DEFAULT_RETRY_DELAY,
    DEFAULT_MAX_TOKENS,
    DEFAULT_TEMPERATURE
)


class DatabaseSettings(BaseSettings):
    """Database configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="SUPABASE_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    url: str = Field(..., description="Supabase project URL")
    key: str = Field(..., description="Supabase API key")
    schema_name: str = Field(default=DEFAULT_SCHEMA, description="Database schema name")
    timeout: int = Field(default=10, description="Database timeout in seconds")


class AIServiceSettings(BaseSettings):
    """AI service configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="OPENROUTER_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    api_key: str = Field(..., description="OpenRouter API key")
    default_model: str = Field(
        default="openai/gpt-4o-mini",
        description="Default AI model to use"
    )
    fallback_model: Optional[str] = Field(
        default=None,
        description="Fallback AI model to use when primary model fails (None = use default fallback chain)"
    )
    max_tokens: int = Field(
        default=DEFAULT_MAX_TOKENS,
        description="Maximum tokens for generation"
    )
    temperature: float = Field(
        default=DEFAULT_TEMPERATURE,
        description="Temperature for text generation"
    )
    max_retries: int = Field(
        default=DEFAULT_MAX_RETRIES,
        description="Maximum retry attempts"
    )
    retry_delay: float = Field(
        default=DEFAULT_RETRY_DELAY,
        description="Delay between retries in seconds"
    )


class VoiceServiceSettings(BaseSettings):
    """Voice service configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="ELEVENLABS_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    api_key: Optional[str] = Field(default=None, description="ElevenLabs API key")
    enabled: bool = Field(default=True, description="Whether voice generation is enabled")


class ApplicationSettings(BaseSettings):
    """Application configuration settings."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    environment: str = Field(default="development", description="Application environment")
    host: str = Field(default="0.0.0.0", description="Server host")
    port: int = Field(default=8000, description="Server port")
    debug: bool = Field(default=False, description="Debug mode")
    cors_origins: list[str] = Field(
        default=["*"],
        description="Allowed CORS origins"
    )


class LoggingSettings(BaseSettings):
    """Logging configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="LOG_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    level: str = Field(default=DEFAULT_LOG_LEVEL, description="Logging level")
    format: str = Field(
        default="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        description="Log format string"
    )
    file: Optional[str] = Field(default=None, description="Log file path")
    json_format: bool = Field(default=False, description="Use JSON format for logs")


class CacheSettings(BaseSettings):
    """Cache configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="REDIS_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    url: str = Field(default="redis://localhost:6379/0", description="Redis connection string")
    password: Optional[str] = Field(default=None, description="Redis authentication password")
    db: int = Field(default=0, description="Redis database number")
    max_connections: int = Field(default=10, description="Connection pool size")
    socket_timeout: int = Field(default=5, description="Socket timeout in seconds")
    enabled: bool = Field(default=True, description="Global cache enable/disable flag")
    default_ttl: int = Field(default=3600, description="Default TTL for cached entries")
    hero_ttl: int = Field(default=3600, description="TTL for hero entities")
    child_ttl: int = Field(default=1800, description="TTL for child entities")
    story_ttl: int = Field(default=600, description="TTL for story entities")


class LangGraphWorkflowSettings(BaseSettings):
    """LangGraph workflow configuration settings."""
    
    model_config = SettingsConfigDict(
        env_prefix="LANGGRAPH_",
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    # Feature flag
    enabled: bool = Field(
        default=False,
        description="Enable LangGraph workflow for story generation"
    )
    
    # Quality settings
    quality_threshold: int = Field(
        default=7,
        ge=1,
        le=10,
        description="Minimum quality score to accept (1-10)"
    )
    max_generation_attempts: int = Field(
        default=3,
        ge=1,
        le=5,
        description="Maximum generation attempts before selecting best"
    )
    
    # Model configuration
    validation_model: str = Field(
        default="anthropic/claude-3-haiku",
        description="Model for prompt validation (can be set via LANGGRAPH_VALIDATION_MODEL env var)"
    )
    assessment_model: str = Field(
        default="anthropic/claude-3-haiku",
        description="Model for quality assessment"
    )
    generation_model: Optional[str] = Field(
        default=None,
        description="Primary model for story generation (can be set via LANGGRAPH_GENERATION_MODEL env var, None = use default from AIServiceSettings)"
    )
    
    # Temperature settings for different attempts
    first_attempt_temperature: float = Field(
        default=0.7,
        ge=0.0,
        le=2.0,
        description="Temperature for first generation attempt"
    )
    second_attempt_temperature: float = Field(
        default=0.8,
        ge=0.0,
        le=2.0,
        description="Temperature for second generation attempt"
    )
    third_attempt_temperature: float = Field(
        default=0.6,
        ge=0.0,
        le=2.0,
        description="Temperature for third generation attempt (more conservative)"
    )


class Settings(BaseSettings):
    """Main application settings."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )
    
    # Nested settings
    database: DatabaseSettings = Field(default_factory=DatabaseSettings)
    ai_service: AIServiceSettings = Field(default_factory=AIServiceSettings)
    voice_service: VoiceServiceSettings = Field(default_factory=VoiceServiceSettings)
    application: ApplicationSettings = Field(default_factory=ApplicationSettings)
    logging: LoggingSettings = Field(default_factory=LoggingSettings)
    cache: CacheSettings = Field(default_factory=CacheSettings)
    langgraph_workflow: LangGraphWorkflowSettings = Field(default_factory=LangGraphWorkflowSettings)
    
    def __init__(self, **kwargs):
        """Initialize settings with validation."""
        super().__init__(**kwargs)
        # Initialize nested settings
        if 'database' not in kwargs:
            self.database = DatabaseSettings()
        if 'ai_service' not in kwargs:
            self.ai_service = AIServiceSettings()
        if 'voice_service' not in kwargs:
            self.voice_service = VoiceServiceSettings()
        if 'application' not in kwargs:
            self.application = ApplicationSettings()
        if 'logging' not in kwargs:
            self.logging = LoggingSettings()
        if 'cache' not in kwargs:
            self.cache = CacheSettings()
        if 'langgraph_workflow' not in kwargs:
            self.langgraph_workflow = LangGraphWorkflowSettings()


# Global settings instance
_settings: Optional[Settings] = None


def get_settings() -> Settings:
    """Get the application settings singleton.
    
    Returns:
        Settings instance
    """
    global _settings
    if _settings is None:
        _settings = Settings()
    return _settings


def reset_settings() -> None:
    """Reset settings singleton (useful for testing)."""
    global _settings
    _settings = None
