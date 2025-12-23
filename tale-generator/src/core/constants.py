"""Application constants."""

from typing import Final

# Application metadata
APP_NAME: Final[str] = "Tale Generator"
APP_VERSION: Final[str] = "0.1.0"
APP_DESCRIPTION: Final[str] = "API for generating bedtime stories for children"

# Reading speed constants (words per minute)
READING_SPEED_WPM: Final[int] = 150

# Rating validation
MIN_RATING: Final[int] = 1
MAX_RATING: Final[int] = 10

# Database schema
DEFAULT_SCHEMA: Final[str] = "tales"

# Storage
STORAGE_BUCKET: Final[str] = "tales"

# Request defaults
DEFAULT_STORY_LENGTH_MINUTES: Final[int] = 5
DEFAULT_MAX_TOKENS: Final[int] = 1000
DEFAULT_TEMPERATURE: Final[float] = 0.7

# Retry configuration
DEFAULT_MAX_RETRIES: Final[int] = 3
DEFAULT_RETRY_DELAY: Final[float] = 1.0

# Logging
DEFAULT_LOG_LEVEL: Final[str] = "INFO"
LOG_FORMAT: Final[str] = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"

# HTTP
CORS_ALLOW_ORIGINS: Final[list] = ["*"]
