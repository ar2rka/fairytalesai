# Story Generation Endpoint - Implementation Summary

## Overview

A new REST API endpoint has been implemented at `/api/v1/stories/generate` that supports generating three types of children's bedtime stories:
- **Child stories**: Stories featuring only the child as the protagonist
- **Hero stories**: Stories featuring only a hero character as the protagonist
- **Combined stories**: Stories featuring both a child and a hero working together

## Endpoint Details

### URL
```
POST /api/v1/stories/generate
```

### Request Body

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| language | string | Yes | - | Story language ("en" or "ru") |
| child_id | string (UUID) | Yes | - | Reference to existing child profile |
| story_type | string | No | "child" | Story type: "child", "hero", or "combined" |
| hero_id | string (UUID) | Conditional | - | Required when story_type is "hero" or "combined" |
| story_length | integer | No | 5 | Story length in minutes (1-30) |
| moral | string | No | - | Predefined moral value |
| custom_moral | string | No | - | Custom moral value |
| generate_audio | boolean | No | false | Whether to generate audio narration |
| voice_provider | string | No | - | Voice provider name (e.g., "elevenlabs") |
| voice_options | object | No | - | Provider-specific voice configuration |

### Response (200 OK)

```json
{
  "id": "uuid",
  "title": "Story Title",
  "content": "Story narrative...",
  "moral": "kindness",
  "language": "en",
  "story_type": "combined",
  "story_length": 5,
  "child": {
    "id": "uuid",
    "name": "Emma",
    "age": 7,
    "gender": "female",
    "interests": ["unicorns", "fairies"]
  },
  "hero": {
    "id": "uuid",
    "name": "Captain Wonder",
    "gender": "male",
    "appearance": "A brave captain with a golden compass"
  },
  "relationship_description": "Emma meets the legendary Captain Wonder",
  "audio_file_url": "https://...",
  "created_at": "2024-12-01T..."
}
```

## Example Requests

### 1. Child Story (Simple)

```bash
curl -X POST "http://localhost:8000/api/v1/stories/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "en",
    "child_id": "123e4567-e89b-12d3-a456-426614174000",
    "story_type": "child",
    "moral": "kindness",
    "story_length": 5
  }'
```

### 2. Hero Story

```bash
curl -X POST "http://localhost:8000/api/v1/stories/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "ru",
    "child_id": "123e4567-e89b-12d3-a456-426614174000",
    "story_type": "hero",
    "hero_id": "987fcdeb-51a2-43f7-b123-9876543210ab",
    "moral": "bravery",
    "story_length": 7
  }'
```

### 3. Combined Story with Audio

```bash
curl -X POST "http://localhost:8000/api/v1/stories/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "language": "en",
    "child_id": "123e4567-e89b-12d3-a456-426614174000",
    "story_type": "combined",
    "hero_id": "987fcdeb-51a2-43f7-b123-9876543210ab",
    "custom_moral": "overcoming challenges together",
    "story_length": 10,
    "generate_audio": true,
    "voice_provider": "elevenlabs"
  }'
```

## Error Responses

| HTTP Status | Error Code | Description |
|-------------|------------|-------------|
| 400 | Bad Request | Invalid language, story type, missing hero_id, or hero language mismatch |
| 404 | Not Found | Child or hero not found with provided ID |
| 500 | Internal Server Error | Story generation or database failure |

### Error Response Format

```json
{
  "detail": "Error message describing the issue"
}
```

## Validation Rules

1. **Language**: Must be "en" or "ru"
2. **Story Type**: Must be "child", "hero", or "combined"
3. **Hero ID**: Required when story_type is "hero" or "combined"
4. **Child ID**: Must reference an existing child in the database
5. **Hero ID**: Must reference an existing hero in the database
6. **Hero Language**: Must match the requested story language
7. **Story Length**: Must be between 1 and 30 minutes
8. **Moral**: Use either `moral` or `custom_moral`, not both

## Implementation Details

### Modified Files

1. **src/domain/services/prompt_service.py**
   - Added `generate_combined_prompt()` method
   - Implements combined story prompt generation for English and Russian

2. **src/domain/entities.py**
   - Updated `Story` entity with hero fields and `story_type`

3. **src/application/dto.py**
   - Added `GenerateStoryRequestDTO` for request validation
   - Added `GenerateStoryResponseDTO` for structured responses
   - Added `ChildInfoDTO` and `HeroInfoDTO` for nested information

4. **src/api/routes.py**
   - Implemented new `/stories/generate` endpoint
   - Comprehensive validation logic
   - Support for all three story types
   - Audio generation integration
   - Database persistence

### Key Features

- **Multi-language Support**: English and Russian prompts with culturally appropriate content
- **Type Safety**: Pydantic models ensure request/response validation
- **Error Handling**: Clear, actionable error messages
- **Audio Generation**: Optional audio narration with provider selection
- **Database Integration**: Full persistence with Supabase
- **Relationship Descriptions**: Automatic generation for combined stories

## Testing

A comprehensive test suite is provided in `test_generate_story_endpoint.py`:

```bash
# Start the server
uv run uvicorn main:app --reload

# In another terminal, run tests
uv run python test_generate_story_endpoint.py
```

The test suite covers:
- Endpoint registration and documentation
- Validation error handling
- Child story generation
- Request/response structure

## API Documentation

The endpoint is automatically documented in the FastAPI Swagger UI:

```
http://localhost:8000/docs
```

Search for "POST /api/v1/stories/generate" to see:
- Request schema with examples
- Response schema
- Try-it-out functionality

## Next Steps

1. **Test with Real Data**: Create children and heroes in the database
2. **Hero Stories**: Test hero-only story generation
3. **Combined Stories**: Test child + hero combined stories
4. **Audio Generation**: Configure voice provider and test audio generation
5. **Language Support**: Test both English and Russian story generation

## Notes

- The endpoint defaults to `story_type="child"` if not specified
- Moral value defaults to "kindness" if not provided
- Audio generation is optional and fails gracefully if provider is not configured
- Combined stories automatically generate relationship descriptions in the appropriate language
- All stories are persisted in Supabase with full metadata
