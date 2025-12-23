# Tale Generator API

A FastAPI service for generating personalized children's bedtime stories with AI.

## Features

- Generate customized bedtime stories for children using AI
- Save stories to Supabase database
- Multi-language support (English, Russian)
- Story rating functionality (1-10 scale)
- Store OpenRouter generation info for detailed analytics
- Simple admin interface for viewing stories
- Docker support for easy deployment

## Prerequisites

- Python 3.12+
- [UV](https://github.com/astral-sh/uv) for package management
- Supabase account for database storage
- OpenRouter API key for AI generation

## Setup

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd tale-generator
   ```

2. Install dependencies using UV:
   ```bash
   uv sync
   ```

3. Copy the example environment file and configure your settings:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` to add your:
   - `OPENROUTER_API_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_KEY`

4. Apply database migrations:
   
   First, apply the initial migrations:
   ```bash
   # Apply the stories table migration
   # Copy the SQL from supabase/migrations/001_create_stories_table.sql
   # and run it in your Supabase SQL Editor
   
   # Apply the model info migration
   # Copy the SQL from supabase/migrations/002_add_model_info_to_stories.sql
   # and run it in your Supabase SQL Editor
   
   # Apply the language migration
   # Copy the SQL from supabase/migrations/004_add_language_to_stories.sql
   # and run it in your Supabase SQL Editor
   
   # Apply the children table migration
   # Copy the SQL from supabase/migrations/005_create_children_table.sql
   # and run it in your Supabase SQL Editor
   
   # Apply the rating column migration
   # Copy the SQL from supabase/migrations/006_add_rating_to_stories.sql
   # and run it in your Supabase SQL Editor
   
   # Apply the generation info migration
   # Copy the SQL from supabase/migrations/007_add_generation_info_to_stories.sql
   # and run it in your Supabase SQL Editor
   ```

5. Run the application:
   ```bash
   uv run main.py
   ```

## API Endpoints

### Story Generation
- `POST /generate-story` - Generate a new bedtime story

### Story Management
- `GET /stories` - Retrieve all stories
- `GET /stories/{story_id}` - Retrieve a specific story
- `PUT /stories/{story_id}/rating` - Rate a story (1-10)
- `GET /stories/child/{child_name}` - Retrieve stories for a specific child
- `GET /stories/child-id/{child_id}` - Retrieve stories for a specific child by ID
- `GET /stories/language/{language}` - Retrieve stories in a specific language
- `DELETE /stories/{story_id}` - Delete a story
- `POST /save-story` - Save a story to the database

### Child Management
- `GET /children` - Retrieve all children
- `GET /children/{child_id}` - Retrieve a specific child
- `GET /children/name/{name}` - Retrieve children with a specific name
- `POST /children` - Create a new child profile
- `DELETE /children/{child_id}` - Delete a child

## Admin Interface

Access the admin interface at `http://localhost:8000/admin` to view and manage generated stories.

Features:
- View all generated stories in a grid layout
- Filter stories by child or language
- Sort stories by various criteria
- View detailed story information in a modal
- See statistics about total stories, children, and average ratings

## Usage Examples

### Generate a Story
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
```bash
curl -X PUT "http://localhost:8000/stories/{story_id}/rating" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 8
  }'
```

### Manage Stories with CLI
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

# List children by name
python manage_stories.py list-children-by-name "Emma"

# Delete a child
python manage_stories.py delete-child "child_id"
```

## Development

### Running Tests
```bash
uv run pytest
```

### Docker Deployment

#### Development
```bash
docker-compose up --build
```

#### Production
```bash
docker-compose -f docker-compose.prod.yml up --build
```

## License

MIT