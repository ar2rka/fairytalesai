"""Main entry point for the tale generator API service."""

import logging
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from src.api.routes import router, openrouter_client
from src.logging_config import setup_logging

# Set up logging
logger = setup_logging()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Async lifespan context manager for startup and shutdown events."""
    # Startup
    logger.info("Starting up Tale Generator API")
    yield
    # Shutdown
    logger.info("Shutting down Tale Generator API")
    # Close async HTTP client if exists
    if openrouter_client is not None:
        await openrouter_client.close()
        logger.info("Closed OpenRouter async HTTP client")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Tale Generator API",
        description="API for generating bedtime stories for children",
        version="0.1.0",
        lifespan=lifespan
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
    
    # Mount static files for admin interface
    admin_static_path = os.path.join(os.path.dirname(__file__), "src", "admin", "static")
    if os.path.exists(admin_static_path):
        app.mount("/admin/static", StaticFiles(directory=admin_static_path), name="admin_static")
    
    @app.get("/")
    async def root():
        logger.info("Root endpoint accessed")
        return {"message": "Welcome to the Tale Generator API"}
    
    @app.get("/health")
    async def health_check():
        logger.debug("Health check endpoint accessed")
        return {"status": "healthy"}
    
    @app.get("/admin", response_class=HTMLResponse)
    async def admin_panel():
        """Serve the admin panel HTML."""
        admin_template_path = os.path.join(os.path.dirname(__file__), "src", "admin", "templates", "admin.html")
        if os.path.exists(admin_template_path):
            with open(admin_template_path, "r", encoding="utf-8") as f:
                return f.read()
        else:
            return "<h1>Admin panel not found</h1><p>The admin panel files are missing.</p>"
    
    @app.get("/admin/generations", response_class=HTMLResponse)
    async def generations_view():
        """Serve the generations view HTML."""
        generations_template_path = os.path.join(os.path.dirname(__file__), "src", "admin", "templates", "generations.html")
        if os.path.exists(generations_template_path):
            with open(generations_template_path, "r", encoding="utf-8") as f:
                return f.read()
        else:
            return "<h1>Generations view not found</h1><p>The generations view files are missing.</p>"
    
    @app.get("/admin/generations/{generation_id}", response_class=HTMLResponse)
    async def generation_detail_view(generation_id: str):
        """Serve the generation detail view HTML."""
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