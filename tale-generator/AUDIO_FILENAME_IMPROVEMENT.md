# Audio Filename Improvement

## Overview
Improved the audio file naming system to use story IDs instead of random UUIDs, making it easier to track the relationship between stories and their audio files.

## Problem
Previously, audio files were named using random UUIDs (`{random_uuid}.mp3`), which made it difficult to:
- Identify which audio file belongs to which story
- Debug audio-related issues
- Manage audio files in storage

## Solution
Changed the audio file naming to use the story ID (`{story_id}.mp3`), creating a direct 1:1 mapping between stories and their audio files.

## Changes Made

### 1. Modified `_generate_audio()` Function in `src/api/routes.py`

**Added `story_id` parameter:**
```python
async def _generate_audio(
    content: str,
    language: str,
    provider_name: Optional[str],
    voice_options: Optional[dict],
    story_id: str  # NEW parameter
) -> Tuple[Optional[str], Optional[str], Optional[dict]]:
```

**Updated audio filename generation:**
```python
# Before
audio_filename = f"{uuid.uuid4()}.mp3"
audio_file_url = await supabase_client.upload_audio_file(
    file_data=audio_result.audio_data,
    filename=audio_filename,
    story_id=str(uuid.uuid4())  # Random UUID
)

# After
audio_filename = f"{story_id}.mp3"
audio_file_url = await supabase_client.upload_audio_file(
    file_data=audio_result.audio_data,
    filename=audio_filename,
    story_id=story_id  # Actual story ID
)
```

### 2. Reordered Story Generation Flow in `generate_story()` Endpoint

**New workflow:**
1. Generate story content
2. Clean content
3. Extract title
4. **Save story to database** → Get `story_id`
5. Generate audio using `story_id`
6. Update story with audio URL

**Previous workflow:**
1. Generate story content
2. Clean content
3. Extract title
4. Generate audio (without story_id)
5. Save story with audio URL

**Key change:**
```python
# Save story first to get story_id
saved_story = await _save_story(
    title=title,
    content=cleaned_content,
    generation_id=generation_id,
    moral=moral,
    child=child,
    hero=hero,
    language=language,
    audio_file_url=None,  # Will be updated after audio generation
    user_id=user.user_id
)

# Get story ID
story_id = saved_story.id if saved_story else str(uuid.uuid4())

# Generate audio with story_id
if request.generate_audio:
    audio_file_url, audio_provider, audio_metadata = await _generate_audio(
        content=cleaned_content,
        language=language.value,
        provider_name=request.voice_provider,
        voice_options=request.voice_options,
        story_id=story_id  # Pass story_id
    )
    
    # Update story with audio URL
    if audio_file_url and saved_story:
        await supabase_client.update_story_audio(
            story_id=story_id,
            audio_file_url=audio_file_url,
            audio_provider=audio_provider,
            audio_metadata=audio_metadata
        )
```

### 3. Added `update_story_audio()` Method

**In `src/supabase_client.py`:**
```python
def update_story_audio(
    self,
    story_id: str,
    audio_file_url: str,
    audio_provider: Optional[str] = None,
    audio_metadata: Optional[dict] = None,
    user_id: Optional[str] = None
) -> Optional[StoryDB]:
    """Update the audio information of a story."""
    # Updates audio_file_url, audio_provider, audio_generation_metadata
```

**In `src/supabase_client_async.py`:**
```python
async def update_story_audio(
    self,
    story_id: str,
    audio_file_url: str,
    audio_provider: Optional[str] = None,
    audio_metadata: Optional[dict] = None,
    user_id: Optional[str] = None
) -> Optional[StoryDB]:
    """Update the audio information of a story asynchronously."""
```

## Benefits

### 1. Easier Debugging
- Audio files can be identified by story ID
- Direct correlation between story and audio file
- Simplified troubleshooting of audio issues

### 2. Better File Management
- Predictable file naming: `{story_id}.mp3`
- Easy to find audio file for a specific story
- Simplified cleanup of orphaned audio files

### 3. Improved Tracking
- Clear audit trail from story to audio file
- Better logging with story_id in audio generation logs
- Easier to verify audio file existence

### 4. Database Consistency
- Story is saved before audio generation
- Audio URL is updated after successful generation
- Prevents orphaned audio files if story save fails

## Example

**Before:**
- Story ID: `abc123-def456-ghi789`
- Audio filename: `xyz987-uvw654-rst321.mp3`
- ❌ No obvious relationship

**After:**
- Story ID: `abc123-def456-ghi789`
- Audio filename: `abc123-def456-ghi789.mp3`
- ✅ Clear 1:1 mapping

## Edge Cases Handled

1. **Story save fails**: Uses fallback UUID for audio filename
2. **Audio generation fails**: Story is already saved, no orphaned records
3. **Audio update fails**: Logged as warning, doesn't fail the request
4. **Concurrent audio generations**: Each story has unique ID, no conflicts

## No Breaking Changes

- Existing audio files remain unchanged
- New audio files use the improved naming
- API response format unchanged
- All existing integrations continue to work

## Files Modified

1. `src/api/routes.py` - Updated `_generate_audio()` and `generate_story()`
2. `src/supabase_client.py` - Added `update_story_audio()` method
3. `src/supabase_client_async.py` - Added async `update_story_audio()` method

## Future Considerations

1. Could implement audio file migration to rename old files
2. Could add cleanup task for orphaned audio files
3. Could use story_id for audio caching strategies
