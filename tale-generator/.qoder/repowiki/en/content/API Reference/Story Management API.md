# Story Management API

<cite>
**Referenced Files in This Document**
- [routes.py](file://src/api/routes.py)
- [dto.py](file://src/application/dto.py)
- [exceptions.py](file://src/core/exceptions.py)
- [models.py](file://src/models.py)
- [supabase_client.py](file://src/supabase_client.py)
- [manage_stories.py](file://manage_stories.py)
- [test_rating.py](file://test_rating.py)
- [README.md](file://README.md)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [API Overview](#api-overview)
3. [Authentication](#authentication)
4. [Error Handling](#error-handling)
5. [Story Retrieval Endpoints](#story-retrieval-endpoints)
6. [Story Rating Endpoint](#story-rating-endpoint)
7. [Story Deletion Endpoint](#story-deletion-endpoint)
8. [Data Models](#data-models)
9. [Curl Examples](#curl-examples)
10. [Implementation Details](#implementation-details)

## Introduction

The Story Management API provides comprehensive endpoints for managing bedtime stories in the Tale Generator application. This API allows clients to retrieve stories by various criteria, rate stories on a 1-10 scale, and delete stories when necessary. The API is built using FastAPI and integrates with Supabase for persistent storage.

## API Overview

The Story Management API consists of six primary endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/stories` | GET | Retrieve all stories |
| `/stories/{story_id}` | GET | Retrieve a specific story |
| `/stories/{story_id}/rating` | PUT | Rate a story (1-10) |
| `/stories/child/{child_name}` | GET | Retrieve stories for a specific child by name |
| `/stories/child-id/{child_id}` | GET | Retrieve stories for a specific child by ID |
| `/stories/language/{language}` | GET | Retrieve stories in a specific language |
| `/stories/{story_id}` | DELETE | Delete a story |

## Authentication

This API does not require authentication for basic story management operations. However, all endpoints assume proper Supabase configuration for database operations.

## Error Handling

The API uses HTTP status codes and structured error responses for error handling. Common error scenarios include:

### 404 Not Found
- Story not found when retrieving, rating, or deleting
- Child not found when retrieving stories by child ID
- Invalid language parameter (not "en" or "ru")

### 400 Bad Request
- Unsupported language parameter (only "en" and "ru" supported)
- Invalid rating value (outside 1-10 range)

### 500 Internal Server Error
- Database connectivity issues
- Supabase configuration problems
- Unexpected runtime errors

**Section sources**
- [exceptions.py](file://src/core/exceptions.py#L69-L98)
- [routes.py](file://src/api/routes.py#L263-L268)
- [routes.py](file://src/api/routes.py#L365-L369)

## Story Retrieval Endpoints

### GET /stories

Retrieve all stories stored in the database.

**Response Schema**: [`StoryDBResponseDTO`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
[
  {
    "id": "story-uuid-1",
    "title": "The Brave Little Mouse",
    "content": "Once upon a time in the forest...",
    "moral": "bravery",
    "language": "en",
    "child_id": "child-uuid-1",
    "child_name": "Emma",
    "child_age": 7,
    "child_gender": "female",
    "child_interests": ["unicorns", "fairies"],
    "story_length": 5,
    "rating": 8,
    "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
    "audio_provider": "elevenlabs",
    "model_used": "openrouter-gpt-4",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:35:00Z"
  }
]
```

**Error Cases**:
- **500**: Database connection failure
- **500**: Supabase configuration missing

### GET /stories/{story_id}

Retrieve a specific story by its unique identifier.

**Path Parameters**:
- `story_id` (string): UUID of the story to retrieve

**Response Schema**: [`StoryDBResponseDTO`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
{
  "id": "story-uuid-1",
  "title": "The Brave Little Mouse",
  "content": "Once upon a time in the forest...",
  "moral": "bravery",
  "language": "en",
  "child_id": "child-uuid-1",
  "child_name": "Emma",
  "child_age": 7,
  "child_gender": "female",
  "child_interests": ["unicorns", "fairies"],
  "story_length": 5,
  "rating": 8,
  "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
  "audio_provider": "elevenlabs",
  "model_used": "openrouter-gpt-4",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Error Cases**:
- **404**: Story not found
- **500**: Database connection failure
- **500**: Supabase configuration missing

### GET /stories/child/{child_name}

Retrieve all stories associated with a specific child by name.

**Path Parameters**:
- `child_name` (string): Name of the child

**Response Schema**: [`List[StoryDBResponseDTO]`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
[
  {
    "id": "story-uuid-1",
    "title": "The Brave Little Mouse",
    "content": "Once upon a time in the forest...",
    "moral": "bravery",
    "language": "en",
    "child_id": "child-uuid-1",
    "child_name": "Emma",
    "child_age": 7,
    "child_gender": "female",
    "child_interests": ["unicorns", "fairies"],
    "story_length": 5,
    "rating": 8,
    "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
    "audio_provider": "elevenlabs",
    "model_used": "openrouter-gpt-4",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:35:00Z"
  }
]
```

**Error Cases**:
- **500**: Database connection failure
- **500**: Supabase configuration missing

### GET /stories/child-id/{child_id}

Retrieve all stories associated with a specific child by ID.

**Path Parameters**:
- `child_id` (string): UUID of the child

**Response Schema**: [`List[StoryDBResponseDTO]`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
[
  {
    "id": "story-uuid-1",
    "title": "The Brave Little Mouse",
    "content": "Once upon a time in the forest...",
    "moral": "bravery",
    "language": "en",
    "child_id": "child-uuid-1",
    "child_name": "Emma",
    "child_age": 7,
    "child_gender": "female",
    "child_interests": ["unicorns", "fairies"],
    "story_length": 5,
    "rating": 8,
    "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
    "audio_provider": "elevenlabs",
    "model_used": "openrouter-gpt-4",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:35:00Z"
  }
]
```

**Error Cases**:
- **500**: Database connection failure
- **500**: Supabase configuration missing

### GET /stories/language/{language}

Retrieve all stories in a specific language.

**Path Parameters**:
- `language` (string): Language code ("en" for English, "ru" for Russian)

**Response Schema**: [`List[StoryDBResponseDTO]`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
[
  {
    "id": "story-uuid-1",
    "title": "The Brave Little Mouse",
    "content": "Once upon a time in the forest...",
    "moral": "bravery",
    "language": "en",
    "child_id": "child-uuid-1",
    "child_name": "Emma",
    "child_age": 7,
    "child_gender": "female",
    "child_interests": ["unicorns", "fairies"],
    "story_length": 5,
    "rating": 8,
    "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
    "audio_provider": "elevenlabs",
    "model_used": "openrouter-gpt-4",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:35:00Z"
  }
]
```

**Error Cases**:
- **400**: Unsupported language (must be "en" or "ru")
- **500**: Database connection failure
- **500**: Supabase configuration missing

**Section sources**
- [routes.py](file://src/api/routes.py#L250-L434)
- [supabase_client.py](file://src/supabase_client.py#L680-L821)

## Story Rating Endpoint

### PUT /stories/{story_id}/rating

Rate a story with a score from 1 to 10.

**Path Parameters**:
- `story_id` (string): UUID of the story to rate

**Request Body**: [`StoryRatingRequestDTO`](file://src/application/dto.py#L47-L50)

```json
{
  "rating": 8
}
```

**Response Schema**: [`StoryDBResponseDTO`](file://src/application/dto.py#L96-L116)

**Success Response**:
```json
{
  "id": "story-uuid-1",
  "title": "The Brave Little Mouse",
  "content": "Once upon a time in the forest...",
  "moral": "bravery",
  "language": "en",
  "child_id": "child-uuid-1",
  "child_name": "Emma",
  "child_age": 7,
  "child_gender": "female",
  "child_interests": ["unicorns", "fairies"],
  "story_length": 5,
  "rating": 8,
  "audio_file_url": "https://storage.googleapis.com/audio/story-1.mp3",
  "audio_provider": "elevenlabs",
  "model_used": "openrouter-gpt-4",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:35:00Z"
}
```

**Validation Rules**:
- Rating must be an integer between 1 and 10 (inclusive)
- Rating is validated using Pydantic model with `ge=1` and `le=10` constraints

**Error Cases**:
- **400**: Invalid rating value (not 1-10)
- **404**: Story not found
- **500**: Database connection failure
- **500**: Supabase configuration missing

**Section sources**
- [routes.py](file://src/api/routes.py#L279-L305)
- [dto.py](file://src/application/dto.py#L47-L50)
- [supabase_client.py](file://src/supabase_client.py#L823-L884)

## Story Deletion Endpoint

### DELETE /stories/{story_id}

Delete a story by its unique identifier.

**Path Parameters**:
- `story_id` (string): UUID of the story to delete

**Response**:
```json
{
  "message": "Story deleted successfully"
}
```

**Error Cases**:
- **404**: Story not found
- **500**: Database connection failure
- **500**: Supabase configuration missing

**Section sources**
- [routes.py](file://src/api/routes.py#L408-L434)
- [supabase_client.py](file://src/supabase_client.py#L886-L898)

## Data Models

### StoryDBResponseDTO

The primary response model for story data, containing all story attributes.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique story identifier |
| `title` | string | Story title |
| `content` | string | Complete story content |
| `moral` | string | Moral value of the story |
| `language` | string | Language code ("en" or "ru") |
| `child_id` | string \| null | Associated child identifier |
| `child_name` | string \| null | Child's name |
| `child_age` | integer \| null | Child's age |
| `child_gender` | string \| null | Child's gender |
| `child_interests` | array[string] \| null | Child's interests |
| `story_length` | integer \| null | Story length in minutes |
| `rating` | integer \| null | Story rating (1-10) |
| `audio_file_url` | string \| null | URL to audio narration |
| `audio_provider` | string \| null | Audio provider name |
| `audio_generation_metadata` | object \| null | Audio generation details |
| `model_used` | string \| null | AI model used for generation |
| `created_at` | string \| null | ISO 8601 timestamp |
| `updated_at` | string \| null | ISO 8601 timestamp |

### StoryRatingRequestDTO

Request model for story rating operations.

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `rating` | integer | Rating value | Must be between 1 and 10 |

**Section sources**
- [dto.py](file://src/application/dto.py#L96-L116)
- [dto.py](file://src/application/dto.py#L47-L50)

## Curl Examples

### Retrieve All Stories
```bash
curl -X GET "http://localhost:8000/stories" \
  -H "Content-Type: application/json"
```

### Retrieve Specific Story
```bash
curl -X GET "http://localhost:8000/stories/123e4567-e89b-12d3-a456-426614174000" \
  -H "Content-Type: application/json"
```

### Rate a Story
```bash
curl -X PUT "http://localhost:8000/stories/123e4567-e89b-12d3-a456-426614174000/rating" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 8
  }'
```

### Retrieve Stories by Child Name
```bash
curl -X GET "http://localhost:8000/stories/child/Emma" \
  -H "Content-Type: application/json"
```

### Retrieve Stories by Child ID
```bash
curl -X GET "http://localhost:8000/stories/child-id/123e4567-e89b-12d3-a456-426614174000" \
  -H "Content-Type: application/json"
```

### Retrieve Stories by Language
```bash
curl -X GET "http://localhost:8000/stories/language/en" \
  -H "Content-Type: application/json"
```

### Delete a Story
```bash
curl -X DELETE "http://localhost:8000/stories/123e4567-e89b-12d3-a456-426614174000" \
  -H "Content-Type: application/json"
```

**Section sources**
- [README.md](file://README.md#L129-L136)
- [README.md](file://README.md#L140-L154)

## Implementation Details

### Database Operations

The API integrates with Supabase for all database operations. The [`SupabaseClient`](file://src/supabase_client.py) handles all CRUD operations for stories, including:

- **Retrieval**: Filtering by story ID, child name, child ID, or language
- **Updates**: Rating updates with validation
- **Deletion**: Story removal with cascade effects

### Error Handling Strategy

The API implements a layered error handling approach:

1. **HTTP Exceptions**: FastAPI's built-in exception handling for common scenarios
2. **Custom Exceptions**: Application-specific exceptions for domain logic
3. **Logging**: Comprehensive logging for debugging and monitoring
4. **Graceful Degradation**: Fallback responses when database operations fail

### Validation Pipeline

All incoming requests undergo multiple validation stages:

1. **Pydantic Validation**: Automatic validation using DTO models
2. **Business Logic Validation**: Custom validation for business rules
3. **Database Constraints**: Database-level constraints for data integrity

### Performance Considerations

- **Indexing**: Database indexes on frequently queried fields (language, child_id)
- **Pagination**: Not implemented for simplicity, but could be added for large datasets
- **Caching**: Not implemented, but could be added for frequently accessed stories

### Filtering Mechanisms

Stories can be filtered using several criteria:

- **By Child**: Filter by child name or child ID for personalized story retrieval
- **By Language**: Restrict results to English ("en") or Russian ("ru") stories
- **All Stories**: Retrieve complete story catalog without filtering

**Section sources**
- [supabase_client.py](file://src/supabase_client.py#L680-L821)
- [routes.py](file://src/api/routes.py#L250-L434)
- [exceptions.py](file://src/core/exceptions.py#L69-L98)