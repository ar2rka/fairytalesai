# Use Python 3.12 slim image as base
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install UV package manager
COPY --from=ghcr.io/astral-sh/uv:0.2.25 /uv /bin/uv

# Copy project files
COPY pyproject.toml uv.lock ./

# Install dependencies using UV
RUN uv sync --locked

# Copy application code
COPY . .

# Expose port
EXPOSE 8000

# Create non-root user
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Run the application
CMD ["uv", "run", "main.py"]