"""Custom exception hierarchy for the tale generator application."""

from typing import Optional, Dict, Any


class TaleGeneratorException(Exception):
    """Base exception for all tale generator errors."""
    
    def __init__(
        self,
        message: str,
        error_code: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize the exception.
        
        Args:
            message: User-friendly error message
            error_code: Machine-readable error code
            details: Additional context about the error
        """
        super().__init__(message)
        self.message = message
        self.error_code = error_code or self.__class__.__name__
        self.details = details or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert exception to dictionary for API responses."""
        return {
            "error": self.error_code,
            "message": self.message,
            "details": self.details
        }


class DomainException(TaleGeneratorException):
    """Base exception for domain-level errors."""
    pass


class ValidationError(DomainException):
    """Raised when input validation fails."""
    
    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize validation error.
        
        Args:
            message: Validation error message
            field: Field that failed validation
            details: Additional validation details
        """
        if field and details is None:
            details = {"field": field}
        elif field and details:
            details["field"] = field
        
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            details=details
        )


class NotFoundError(DomainException):
    """Raised when a requested resource is not found."""
    
    def __init__(
        self,
        resource_type: str,
        resource_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize not found error.
        
        Args:
            resource_type: Type of resource that was not found
            resource_id: ID of the resource (if applicable)
            details: Additional context
        """
        message = f"{resource_type} not found"
        if resource_id:
            message = f"{resource_type} with ID '{resource_id}' not found"
        
        error_details = details or {}
        error_details["resource_type"] = resource_type
        if resource_id:
            error_details["resource_id"] = resource_id
        
        super().__init__(
            message=message,
            error_code="NOT_FOUND",
            details=error_details
        )


class ConflictError(DomainException):
    """Raised when a resource conflict occurs."""
    
    def __init__(
        self,
        message: str,
        resource_type: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize conflict error.
        
        Args:
            message: Description of the conflict
            resource_type: Type of resource in conflict
            details: Additional context
        """
        error_details = details or {}
        if resource_type:
            error_details["resource_type"] = resource_type
        
        super().__init__(
            message=message,
            error_code="CONFLICT",
            details=error_details
        )


class ExternalServiceError(TaleGeneratorException):
    """Raised when an external service call fails."""
    
    def __init__(
        self,
        service_name: str,
        message: str,
        status_code: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize external service error.
        
        Args:
            service_name: Name of the external service
            message: Error message
            status_code: HTTP status code (if applicable)
            details: Additional error details
        """
        error_details = details or {}
        error_details["service"] = service_name
        if status_code:
            error_details["status_code"] = status_code
        
        super().__init__(
            message=f"{service_name} error: {message}",
            error_code="EXTERNAL_SERVICE_ERROR",
            details=error_details
        )


class DatabaseError(TaleGeneratorException):
    """Raised when a database operation fails."""
    
    def __init__(
        self,
        message: str,
        operation: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize database error.
        
        Args:
            message: Error message
            operation: Database operation that failed
            details: Additional error details
        """
        error_details = details or {}
        if operation:
            error_details["operation"] = operation
        
        super().__init__(
            message=f"Database error: {message}",
            error_code="DATABASE_ERROR",
            details=error_details
        )


class AuthorizationError(TaleGeneratorException):
    """Raised when authorization fails."""
    
    def __init__(
        self,
        message: str = "Access denied",
        required_permission: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize authorization error.
        
        Args:
            message: Authorization error message
            required_permission: Permission that was required
            details: Additional context
        """
        error_details = details or {}
        if required_permission:
            error_details["required_permission"] = required_permission
        
        super().__init__(
            message=message,
            error_code="AUTHORIZATION_ERROR",
            details=error_details
        )


class ConfigurationError(TaleGeneratorException):
    """Raised when application configuration is invalid."""
    
    def __init__(
        self,
        message: str,
        config_key: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None
    ):
        """Initialize configuration error.
        
        Args:
            message: Configuration error message
            config_key: Configuration key that is invalid
            details: Additional context
        """
        error_details = details or {}
        if config_key:
            error_details["config_key"] = config_key
        
        super().__init__(
            message=f"Configuration error: {message}",
            error_code="CONFIGURATION_ERROR",
            details=error_details
        )
