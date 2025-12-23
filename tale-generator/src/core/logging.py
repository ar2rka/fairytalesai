"""Enhanced logging system with context support."""

import logging
import json
import uuid
from typing import Optional, Dict, Any
from contextvars import ContextVar
from datetime import datetime

# Context variable for request ID
request_id_ctx: ContextVar[Optional[str]] = ContextVar('request_id', default=None)


class ContextFilter(logging.Filter):
    """Add contextual information to log records."""
    
    def filter(self, record: logging.LogRecord) -> bool:
        """Add context to the log record.
        
        Args:
            record: Log record to filter
            
        Returns:
            Always True (we're adding, not filtering)
        """
        # Add request ID if available
        record.request_id = request_id_ctx.get() or 'N/A'
        return True


class JSONFormatter(logging.Formatter):
    """Format log records as JSON."""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format the log record as JSON.
        
        Args:
            record: Log record to format
            
        Returns:
            JSON-formatted log string
        """
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'request_id': getattr(record, 'request_id', 'N/A'),
        }
        
        # Add exception info if present
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        # Add extra fields
        if hasattr(record, 'extra'):
            log_data.update(record.extra)
        
        return json.dumps(log_data)


def setup_logging(
    level: Optional[str] = None,
    log_file: Optional[str] = None,
    format_string: Optional[str] = None,
    json_format: bool = False
) -> logging.Logger:
    """Set up logging configuration for the application.
    
    Args:
        level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Path to log file (if None, logs to console only)
        format_string: Custom format string for log messages
        json_format: Use JSON format for logs
        
    Returns:
        Logger instance
    """
    # Set default values
    level = level or "INFO"
    format_string = format_string or "%(asctime)s - %(name)s - %(levelname)s - [%(request_id)s] - %(message)s"
    
    # Convert level string to logging constant
    numeric_level = getattr(logging, level.upper(), logging.INFO)
    
    # Create formatter
    if json_format:
        formatter = JSONFormatter()
    else:
        formatter = logging.Formatter(format_string)
    
    # Create logger
    logger = logging.getLogger("tale_generator")
    logger.setLevel(numeric_level)
    
    # Clear any existing handlers
    logger.handlers.clear()
    
    # Add context filter
    context_filter = ContextFilter()
    
    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(numeric_level)
    console_handler.setFormatter(formatter)
    console_handler.addFilter(context_filter)
    logger.addHandler(console_handler)
    
    # Create file handler if log_file is specified
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(numeric_level)
        file_handler.setFormatter(formatter)
        file_handler.addFilter(context_filter)
        logger.addHandler(file_handler)
    
    # Prevent propagation to root logger
    logger.propagate = False
    
    return logger


def get_logger(name: str) -> logging.Logger:
    """Get a logger with the specified name.
    
    Args:
        name: Logger name
        
    Returns:
        Logger instance
    """
    return logging.getLogger(f"tale_generator.{name}")


def set_request_id(request_id: Optional[str] = None) -> str:
    """Set the request ID for the current context.
    
    Args:
        request_id: Request ID to set (generates one if None)
        
    Returns:
        The request ID that was set
    """
    if request_id is None:
        request_id = str(uuid.uuid4())
    request_id_ctx.set(request_id)
    return request_id


def get_request_id() -> Optional[str]:
    """Get the current request ID.
    
    Returns:
        Current request ID or None
    """
    return request_id_ctx.get()


def clear_request_id() -> None:
    """Clear the request ID from the current context."""
    request_id_ctx.set(None)


def log_with_context(
    logger: logging.Logger,
    level: int,
    message: str,
    **context: Any
) -> None:
    """Log a message with additional context.
    
    Args:
        logger: Logger instance
        level: Log level
        message: Log message
        **context: Additional context to include
    """
    extra = {'extra': context}
    logger.log(level, message, extra=extra)
