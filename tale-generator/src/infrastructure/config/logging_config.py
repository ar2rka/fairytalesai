"""Logging configuration integration with settings."""

from src.core.logging import setup_logging
from src.infrastructure.config.settings import get_settings


def configure_logging():
    """Configure logging from settings."""
    settings = get_settings()
    return setup_logging(
        level=settings.logging.level,
        log_file=settings.logging.file,
        format_string=settings.logging.format,
        json_format=settings.logging.json_format
    )
