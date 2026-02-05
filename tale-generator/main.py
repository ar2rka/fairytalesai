"""Main entry point for the tale generator API service."""

import logging
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBasic, HTTPBasicCredentials
import os
import secrets
from src.api.routes import router, openrouter_client
from src.logging_config import setup_logging

# Set up logging
logger = setup_logging()

# Basic auth for OpenAPI docs and admin panel
security = HTTPBasic()

def verify_admin_credentials(credentials: HTTPBasicCredentials = Depends(security)):
    """Verify basic authentication credentials for admin endpoints.
    
    Uses OPENAPI_USERNAME and OPENAPI_PASSWORD environment variables
    (same credentials as OpenAPI documentation).
    
    Args:
        credentials: HTTP Basic credentials
        
    Returns:
        Username if credentials are valid
        
    Raises:
        HTTPException: If credentials are invalid
    """
    correct_username = os.getenv("OPENAPI_USERNAME", "admin")
    correct_password = os.getenv("OPENAPI_PASSWORD", "")
    
    # If password is not set, allow access without auth (for development)
    if not correct_password:
        logger.warning("OPENAPI_PASSWORD not set - Admin endpoints are accessible without authentication")
        return credentials.username
    
    is_correct_username = secrets.compare_digest(credentials.username, correct_username)
    is_correct_password = secrets.compare_digest(credentials.password, correct_password)
    
    if not (is_correct_username and is_correct_password):
        logger.warning(f"Failed admin authentication attempt for user: {credentials.username}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    
    logger.debug(f"Admin access granted to user: {credentials.username}")
    return credentials.username

# Alias for backward compatibility with OpenAPI endpoints
verify_openapi_credentials = verify_admin_credentials


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Async lifespan context manager for startup and shutdown events."""
    # Startup
    logger.info("Starting up Tale Generator API")
    
    # Validate and log configuration
    from src.infrastructure.config.settings import get_settings
    settings = get_settings()
    
    # Check that generation model is configured
    generation_model = (
        settings.langgraph_workflow.generation_model 
        or settings.ai_service.default_model
    )
    
    if not generation_model or generation_model.strip() == "":
        error_msg = (
            "Generation model is not configured. "
            "Please set either LANGGRAPH_GENERATION_MODEL or OPENROUTER_DEFAULT_MODEL environment variable."
        )
        logger.error(error_msg)
        raise ValueError(error_msg)
    
    # Log which model will be used
    if settings.langgraph_workflow.generation_model:
        logger.info(f"✓ Generation model configured via LANGGRAPH_GENERATION_MODEL: {settings.langgraph_workflow.generation_model}")
    else:
        logger.info(f"✓ Generation model using default from OPENROUTER_DEFAULT_MODEL: {settings.ai_service.default_model}")
        logger.info(f"  (To set custom model, use LANGGRAPH_GENERATION_MODEL environment variable)")
    
    yield
    # Shutdown
    logger.info("Shutting down Tale Generator API")
    # Close async HTTP client if exists
    if openrouter_client is not None:
        await openrouter_client.close()
        logger.info("Closed OpenRouter async HTTP client")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    # Disable automatic docs endpoints - we'll add protected versions
    app = FastAPI(
        title="Tale Generator API",
        description="API for generating bedtime stories for children",
        version="0.1.0",
        lifespan=lifespan,
        docs_url=None,  # Disable automatic /docs endpoint
        redoc_url=None,  # Disable automatic /redoc endpoint
        openapi_url=None  # Disable automatic /openapi.json endpoint
    )
    
    # Add protected OpenAPI documentation endpoints with basic auth
    @app.get("/docs", dependencies=[Depends(verify_openapi_credentials)])
    async def get_documentation():
        """Swagger UI documentation (protected with basic auth)."""
        from fastapi.openapi.docs import get_swagger_ui_html
        return get_swagger_ui_html(
            openapi_url="/openapi.json",
            title=app.title + " - Swagger UI"
        )
    
    @app.get("/openapi.json", dependencies=[Depends(verify_openapi_credentials)])
    async def get_openapi():
        """OpenAPI schema (protected with basic auth)."""
        # Generate OpenAPI schema manually since openapi_url is None
        from fastapi.openapi.utils import get_openapi
        if not app.openapi_schema:
            app.openapi_schema = get_openapi(
                title=app.title,
                version=app.version,
                description=app.description,
                routes=app.routes,
            )
        return app.openapi_schema
    
    # ReDoc endpoint (if needed)
    @app.get("/redoc", dependencies=[Depends(verify_openapi_credentials)])
    async def get_redoc_documentation():
        """ReDoc documentation (protected with basic auth)."""
        from fastapi.openapi.docs import get_redoc_html
        return get_redoc_html(
            openapi_url="/openapi.json",
            title=app.title + " - ReDoc"
        )
    
    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Include the API router
    app.include_router(router, prefix="/api/v1")
    
    # Mount static files for admin interface (moved to /adminui/)
    admin_static_path = os.path.join(os.path.dirname(__file__), "src", "admin", "static")
    if os.path.exists(admin_static_path):
        app.mount("/adminui/static", StaticFiles(directory=admin_static_path), name="admin_static")
    
    @app.get("/")
    async def root():
        logger.info("Root endpoint accessed")
        return {"message": "Welcome to the Tale Generator API"}
    
    @app.get("/health")
    async def health_check():
        logger.debug("Health check endpoint accessed")
        return {"status": "healthy"}
    
    def _read_admin_page():
        """Read the main admin page (generations)."""
        path = os.path.join(os.path.dirname(__file__), "src", "admin", "templates", "generations.html")
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return f.read()
        return "<h1>Admin not found</h1><p>generations.html is missing.</p>"

    @app.get("/adminui", response_class=HTMLResponse, dependencies=[Depends(verify_admin_credentials)])
    async def admin_panel():
        """Serve the admin panel (generations view) at /adminui."""
        return _read_admin_page()

    @app.get("/adminui/generations", response_class=HTMLResponse, dependencies=[Depends(verify_admin_credentials)])
    async def generations_view():
        """Serve the same admin panel at /adminui/generations (e.g. back-link from detail)."""
        return _read_admin_page()
    
    @app.get("/adminui/generations/{generation_id}", response_class=HTMLResponse, dependencies=[Depends(verify_admin_credentials)])
    async def generation_detail_view(generation_id: str):
        """Serve the generation detail view HTML (protected with basic auth)."""
        generation_detail_template_path = os.path.join(os.path.dirname(__file__), "src", "admin", "templates", "generation_detail.html")
        if os.path.exists(generation_detail_template_path):
            with open(generation_detail_template_path, "r", encoding="utf-8") as f:
                return f.read()
        else:
            return "<h1>Generation detail view not found</h1><p>The generation detail view files are missing.</p>"
    
    return app


# Create app instance for uvicorn
app = create_app()


def run():
    """Run the FastAPI application."""
    logger.info("Starting Tale Generator API service")
    # Get log level from environment or default to info
    log_level = os.getenv("LOG_LEVEL", "info").lower()
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level=log_level,
        reload=False  # Set to True for auto-reload on code changes
    )


if __name__ == "__main__":
    run()