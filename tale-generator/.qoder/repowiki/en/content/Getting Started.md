# Getting Started

<cite>
**Referenced Files in This Document**
- [README.md](file://README.md)
- [pyproject.toml](file://pyproject.toml)
- [Dockerfile](file://Dockerfile)
- [docker-compose.yml](file://docker-compose.yml)
- [main.py](file://main.py)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)
- [apply_migration.py](file://apply_migration.py)
- [src/run_migrations.py](file://src/run_migrations.py)
- [manage_stories.py](file://manage_stories.py)
- [src/migrations/README.md](file://src/migrations/README.md)
- [supabase/README.md](file://supabase/README.md)
- [src/migrations/001_create_heroes_table.sql](file://src/migrations/001_create_heroes_table.sql)
- [supabase/migrations/001_create_stories_table.sql](file://supabase/migrations/001_create_stories_table.sql)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Quick Setup](#quick-setup)
4. [Step-by-Step Installation](#step-by-step-installation)
5. [Environment Configuration](#environment-configuration)
6. [Database Setup](#database-setup)
7. [Running the Application](#running-the-application)
8. [Usage Examples](#usage-examples)
9. [Docker Deployment](#docker-deployment)
10. [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
11. [Next Steps](#next-steps)

## Introduction

The Tale Generator API is a FastAPI service that creates personalized children's bedtime stories using AI. This guide will help you set up and run the application locally, configure all necessary dependencies, and start generating stories within minutes.

The application features:
- Personalized story generation with AI
- Multi-language support (English, Russian)
- Story rating system (1-10 scale)
- Admin interface for story management
- Docker support for easy deployment
- Supabase database integration

## Prerequisites

Before starting, ensure you have the following installed:

### Required Software
- **Python 3.12+** - The application requires Python 3.12 or higher as specified in the project configuration
- **UV Package Manager** - Used for efficient dependency management (installation instructions below)
- **Git** - For cloning the repository
- **Docker** (Optional) - For containerized deployment

### Required Accounts
- **Supabase Account** - For database storage and management
- **OpenRouter API Key** - For AI-powered story generation

### Hardware Requirements
- Minimum 2GB RAM
- Stable internet connection for API calls
- SSD storage for optimal performance

**Section sources**
- [README.md](file://README.md#L15-L21)
- [pyproject.toml](file://pyproject.toml#L6)

## Quick Setup

For developers who want to get started quickly, here's the condensed setup process:

```bash
# 1. Clone the repository
git clone <repository-url>
cd tale-generator

# 2. Install UV and dependencies
curl -Ls "https://astral.sh/uv/install.sh" | sh
uv sync

# 3. Configure environment
cp .env.example .env
# Edit .env with your API keys and Supabase credentials

# 4. Run migrations
uv run src/run_migrations.py

# 5. Start the application
uv run main.py
```

## Step-by-Step Installation

### 1. Clone the Repository

First, clone the Tale Generator repository to your local machine:

```bash
git clone <repository-url>
cd tale-generator
```

Verify you're in the correct directory by checking the project structure:

```bash
ls -la
```

### 2. Install UV Package Manager

UV is the recommended package manager for this project, providing fast dependency resolution and installation:

```bash
# Install UV using the official installer
curl -Ls "https://astral.sh/uv/install.sh" | sh

# Add UV to your PATH (if needed)
export PATH="$HOME/.cargo/bin:$PATH"

# Verify installation
uv --version
```

### 3. Install Dependencies

Use UV to install all project dependencies:

```bash
uv sync
```

This command reads the `pyproject.toml` file and installs all required packages efficiently.

**Section sources**
- [README.md](file://README.md#L24-L33)
- [pyproject.toml](file://pyproject.toml#L1-L26)

## Environment Configuration

### Create Environment File

Copy the example environment configuration file:

```bash
cp .env.example .env
```

### Configure Required Variables

Edit the `.env` file with your actual credentials:

```bash
# OpenRouter API Configuration
OPENROUTER_API_KEY=your_openrouter_api_key_here

# Supabase Configuration
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key

# Optional: ElevenLabs API for voice generation
ELEVENLABS_API_KEY=your_elevenlabs_api_key_optional

# Logging Configuration
LOG_LEVEL=INFO
```

### Environment Variable Details

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `OPENROUTER_API_KEY` | Your OpenRouter API key for AI generation | Yes | `sk-or-v1-...` |
| `SUPABASE_URL` | Supabase project URL | Yes | `https://your-project.supabase.co` |
| `SUPABASE_KEY` | Supabase anonymous/public key | Yes | `eyJhbGciOiJIUzI1NiIs...` |
| `ELEVENLABS_API_KEY` | ElevenLabs API key (optional) | No | `your-api-key` |
| `LOG_LEVEL` | Application logging level | No | `INFO` |

### Validation

Verify your environment configuration:

```bash
# Test Supabase connection
uv run python -c "
import os
from supabase import create_client
url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_KEY')
client = create_client(url, key)
print('✓ Supabase connection successful')
"

# Test OpenRouter API
uv run python -c "
import os
from openai import OpenAI
client = OpenAI(api_key=os.getenv('OPENROUTER_API_KEY'))
try:
    models = client.models.list()
    print('✓ OpenRouter API connection successful')
except Exception as e:
    print(f'✗ OpenRouter API error: {e}')
"
```

**Section sources**
- [README.md](file://README.md#L35-L42)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py#L16-L62)

## Database Setup

The application uses Supabase for database management. You need to set up the database schema and populate initial data.

### Method 1: Using the Migration Script

Run the automated migration script:

```bash
uv run src/run_migrations.py
```

This script will display the SQL commands that need to be executed in your Supabase SQL editor.

### Method 2: Manual Setup via Supabase Dashboard

#### Step 1: Create Supabase Project

1. Go to [Supabase](https://supabase.com/) and create a new account
2. Create a new project and note down your project URL and keys
3. Access the SQL Editor in your Supabase dashboard

#### Step 2: Run Migrations in Order

Execute the following migrations in numerical order:

##### 1. Stories Table Migration

Go to your Supabase SQL Editor and run the stories table creation:

```sql
-- supabase/migrations/001_create_stories_table.sql
CREATE SCHEMA IF NOT EXISTS tales;
CREATE TABLE IF NOT EXISTS tales.stories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    moral TEXT NOT NULL,
    child_name TEXT NOT NULL,
    child_age INTEGER NOT NULL,
    child_gender TEXT NOT NULL,
    child_interests TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_stories_child_name ON tales.stories(child_name);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON tales.stories(created_at);
CREATE INDEX IF NOT EXISTS idx_stories_moral ON tales.stories(moral);

-- Enable Row Level Security (RLS)
ALTER TABLE tales.stories ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Enable read access for all users" ON "tales"."stories"
AS PERMISSIVE FOR SELECT
TO public
USING (true);

CREATE POLICY "Enable insert access for all users" ON "tales"."stories"
AS PERMISSIVE FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON "tales"."stories"
AS PERMISSIVE FOR UPDATE
TO public
USING (true);

CREATE POLICY "Enable delete access for all users" ON "tales"."stories"
AS PERMISSIVE FOR DELETE
TO public
USING (true);
```

##### 2. Model Info Migration

Add model information to stories:

```sql
-- supabase/migrations/002_add_model_info_to_stories.sql
ALTER TABLE tales.stories ADD COLUMN model_used TEXT;
ALTER TABLE tales.stories ADD COLUMN full_response JSONB;
```

##### 3. Language Migration

Add language support:

```sql
-- supabase/migrations/004_add_language_to_stories.sql
ALTER TABLE tales.stories ADD COLUMN language TEXT DEFAULT 'en';
```

##### 4. Children Table Migration

Create the children table:

```sql
-- supabase/migrations/005_create_children_table.sql
CREATE TABLE IF NOT EXISTS tales.children (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL,
    interests TEXT[] NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_children_name ON tales.children(name);
CREATE INDEX IF NOT EXISTS idx_children_age ON tales.children(age);
CREATE INDEX IF NOT EXISTS idx_children_gender ON tales.children(gender);
```

##### 5. Rating Migration

Add rating functionality:

```sql
-- supabase/migrations/006_add_rating_to_stories.sql
ALTER TABLE tales.stories ADD COLUMN rating INTEGER;
```

##### 6. Generation Info Migration

Add generation tracking:

```sql
-- supabase/migrations/007_add_generation_info_to_stories.sql
ALTER TABLE tales.stories ADD COLUMN generation_info JSONB;
```

##### 7. Audio Provider Tracking

Track audio providers:

```sql
-- supabase/migrations/008_add_audio_provider_tracking.sql
ALTER TABLE tales.stories ADD COLUMN audio_provider TEXT;
ALTER TABLE tales.stories ADD COLUMN audio_url TEXT;
```

### Method 3: Using Supabase CLI (Recommended)

Install the Supabase CLI:

```bash
npm install -g supabase
```

Link your project and apply migrations:

```bash
# Link your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push
```

### Verify Setup

Test your database connection:

```bash
# Test heroes table creation
uv run python -c "
from src.supabase_client import SupabaseClient
client = SupabaseClient()
heroes = client.supabase.table('heroes').select('*').execute()
print(f'Heroes table contains {len(heroes.data)} records')
"
```

**Section sources**
- [README.md](file://README.md#L44-L71)
- [src/run_migrations.py](file://src/run_migrations.py#L1-L194)
- [supabase/README.md](file://supabase/README.md#L1-L102)
- [src/migrations/README.md](file://src/migrations/README.md#L1-L50)

## Running the Application

### Local Development

Start the FastAPI application:

```bash
uv run main.py
```

The application will start on `http://localhost:8000` with the following endpoints:

- **API Root**: `http://localhost:8000/`
- **Health Check**: `http://localhost:8000/health`
- **Admin Interface**: `http://localhost:8000/admin`

### Application Features

- **Story Generation**: Generate personalized bedtime stories
- **Story Management**: CRUD operations for stories and children
- **Rating System**: Rate stories from 1-10
- **Multi-language Support**: English and Russian languages
- **Admin Panel**: Web interface for story management

### Testing the Application

Verify the application is running:

```bash
# Check health endpoint
curl http://localhost:8000/health

# Expected response:
# {"status": "healthy"}

# Check root endpoint
curl http://localhost:8000/

# Expected response:
# {"message": "Welcome to the Tale Generator API"}
```

**Section sources**
- [README.md](file://README.md#L73-L76)
- [main.py](file://main.py#L1-L77)

## Usage Examples

### Generate a Story

Use the `/generate-story` endpoint to create a personalized bedtime story:

```bash
curl -X POST "http://localhost:8000/generate-story" \
  -H "Content-Type: application/json" \
  -d '{
    "child": {
      "name": "Emma",
      "age": 7,
      "gender": "female",
      "interests": ["unicorns", "fairies", "princesses"]
    },
    "moral": "kindness",
    "language": "en"
  }'
```

### Rate a Story

Rate a generated story using the `/stories/{story_id}/rating` endpoint:

```bash
curl -X PUT "http://localhost:8000/stories/{story_id}/rating" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 8
  }'
```

### Story Management Commands

Use the CLI utility for story management:

```bash
# List all stories
python manage_stories.py list-all

# List stories for a specific child
python manage_stories.py list-child "Emma"

# List stories in a specific language
python manage_stories.py list-language "en"

# Rate a story
python manage_stories.py rate-story "story_id" 8

# Delete a story
python manage_stories.py delete-story "story_id"

# List all children
python manage_stories.py list-children

# Delete a child
python manage_stories.py delete-child "child_id"
```

### Admin Interface

Access the web-based admin panel at `http://localhost:8000/admin` to:
- View all generated stories
- Filter by child or language
- Sort stories by various criteria
- View detailed story information
- See statistics about total stories, children, and average ratings

**Section sources**
- [README.md](file://README.md#L111-L163)

## Docker Deployment

### Development Environment

Build and run the application using Docker Compose:

```bash
# Build and start the containers
docker-compose up --build

# Run in detached mode
docker-compose up --build -d
```

The application will be available at `http://localhost:8000`.

### Production Environment

For production deployment, use the production configuration:

```bash
# Build and start production containers
docker-compose -f docker-compose.prod.yml up --build

# Run in detached mode
docker-compose -f docker-compose.prod.yml up --build -d
```

### Docker Configuration

The Docker setup includes:
- **Python 3.12** base image
- **UV** package manager installation
- **Non-root user** security
- **Port exposure** on 8000
- **Volume mounting** for development

### Docker Commands

```bash
# Stop and remove containers
docker-compose down

# View container logs
docker-compose logs tale-generator

# Rebuild and restart
docker-compose up --build --force-recreate

# Scale the service
docker-compose up --scale tale-generator=3
```

**Section sources**
- [README.md](file://README.md#L172-L182)
- [Dockerfile](file://Dockerfile#L1-L28)
- [docker-compose.yml](file://docker-compose.yml#L1-L41)

## Common Issues and Troubleshooting

### Missing Environment Variables

**Problem**: Application fails to start with configuration errors.

**Solution**:
1. Verify `.env` file exists and contains all required variables
2. Check variable names match exactly (case-sensitive)
3. Ensure no trailing spaces in values
4. Restart the application after changes

```bash
# Check environment variables
cat .env

# Validate required variables
grep -E "(OPENROUTER_API_KEY|SUPABASE_URL|SUPABASE_KEY)" .env
```

### Database Connection Issues

**Problem**: Cannot connect to Supabase database.

**Solution**:
1. Verify Supabase credentials are correct
2. Check network connectivity
3. Ensure database is running
4. Verify schema permissions

```bash
# Test database connection
uv run python -c "
import os
from supabase import create_client
url = os.getenv('SUPABASE_URL')
key = os.getenv('SUPABASE_KEY')
client = create_client(url, key)
print('✓ Database connection successful')
"
```

### Migration Failures

**Problem**: Database migrations fail to execute.

**Solution**:
1. Manually execute SQL migrations in Supabase SQL Editor
2. Check for syntax errors in migration files
3. Verify table doesn't already exist
4. Ensure proper ordering of migrations

```bash
# Run specific migration manually
psql -h your-db-host -U your-user -d your-db < migration-file.sql
```

### API Key Issues

**Problem**: OpenRouter API requests fail.

**Solution**:
1. Verify API key is valid and active
2. Check API key permissions
3. Ensure sufficient credits/balance
4. Review rate limits

```bash
# Test API key
uv run python -c "
import os
from openai import OpenAI
client = OpenAI(api_key=os.getenv('OPENROUTER_API_KEY'))
try:
    models = client.models.list()
    print(f'✓ API key valid, {len(models.data)} models available')
except Exception as e:
    print(f'✗ API key error: {e}')
"
```

### Port Conflicts

**Problem**: Port 8000 is already in use.

**Solution**:
1. Change the port in `docker-compose.yml` or `main.py`
2. Stop conflicting applications
3. Use a different port

```yaml
# Change port in docker-compose.yml
ports:
  - "8080:8000"  # Map host port 8080 to container port 8000
```

### Permission Issues

**Problem**: Application cannot write to files or directories.

**Solution**:
1. Check file permissions
2. Run with appropriate user privileges
3. Verify volume mounts in Docker

```bash
# Fix permissions
chmod 644 .env
chown -R $USER:$USER .
```

### Memory Issues

**Problem**: Application runs out of memory during story generation.

**Solution**:
1. Increase available memory
2. Reduce concurrent requests
3. Optimize AI model parameters
4. Monitor resource usage

```bash
# Monitor memory usage
htop
# or
docker stats
```

**Section sources**
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py#L16-L62)

## Next Steps

### Explore Advanced Features

1. **Voice Generation**: Configure ElevenLabs API for audio stories
2. **Custom Heroes**: Add new hero profiles to the database
3. **Multi-language**: Explore additional language support
4. **Analytics**: Implement story performance tracking

### Development Workflow

1. **Testing**: Run the test suite
```bash
uv run pytest
```

2. **Development**: Use hot reloading for development
```bash
uv run uvicorn main:app --reload --port 8000
```

3. **Documentation**: Generate API documentation
```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --docs-url /docs
```

### Production Considerations

1. **Security**: Implement proper authentication
2. **Monitoring**: Set up application monitoring
3. **Backup**: Configure database backups
4. **Scaling**: Plan for increased load

### Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** your changes
4. **Submit** a pull request

### Additional Resources

- **API Documentation**: Available at `/docs` when running locally
- **Admin Interface**: Accessible at `/admin`
- **Issue Tracker**: Report bugs and request features
- **Community**: Join discussions and share feedback