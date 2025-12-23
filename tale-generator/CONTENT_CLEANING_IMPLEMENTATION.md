# Story Content Cleaning Implementation

## Overview
This document describes the implementation of automatic content cleaning for story generation to remove formatting markers (such as `****`, `___`, `---`) from AI-generated stories before they are saved to the database or returned to users.

## Problem
AI models sometimes include formatting markers like `****`, `___`, or `---` in their generated content. These markers are used for emphasis or section separation but should not be stored in the final story content.

## Solution
A content cleaning function has been implemented that removes these formatting markers while preserving the actual story text.

## Changes Made

### 1. Added Content Cleaning Function in `src/api/routes.py`

```python
def _clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers.
    
    Args:
        content: Raw story content from AI
        
    Returns:
        Cleaned content without formatting markers
    """
    import re
    
    # Remove sequences of 3 or more asterisks
    cleaned = re.sub(r'\*{3,}', '', content)
    
    # Remove sequences of 3 or more underscores
    cleaned = re.sub(r'_{3,}', '', cleaned)
    
    # Remove sequences of 3 or more hyphens (but not in words)
    cleaned = re.sub(r'(?<!\w)-{3,}(?!\w)', '', cleaned)
    
    # Clean up any excessive whitespace that might have been left
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    
    return cleaned.strip()
```

**Location**: `src/api/routes.py` (around line 404)

### 2. Updated Story Generation Endpoint

The `generate_story()` endpoint now cleans the content immediately after generation:

```python
# Clean the content to remove formatting markers
cleaned_content = _clean_story_content(result.content)

# Extract title from cleaned content
title = _extract_title(cleaned_content)

# Use cleaned content for audio generation
audio_file_url, audio_provider, audio_metadata = await _generate_audio(
    content=cleaned_content,
    ...
)

# Save cleaned content to database
saved_story = await _save_story(
    title=title,
    content=cleaned_content,
    ...
)

# Return cleaned content in response
return _build_response(
    ...
    content=cleaned_content,
    ...
)
```

**Location**: `src/api/routes.py` (lines 684-747)

### 3. Added Content Cleaning Function in `populate_stories.py`

The same cleaning function was added to the populate stories script:

```python
def clean_story_content(content: str) -> str:
    """Clean story content by removing formatting markers."""
    # Same implementation as in routes.py
```

**Location**: `populate_stories.py` (around line 100)

### 4. Updated Story Population Script

The populate stories script now cleans content before saving:

```python
# Clean the content to remove formatting markers
cleaned_content = clean_story_content(result.content)

# Extract title from cleaned content
lines = cleaned_content.strip().split('\n')
title = lines[0].replace('#', '').strip() if lines and lines[0].strip() else f"{child.name}'s Adventure"

# Use cleaned content for audio generation
audio_data = await elevenlabs_client.generate_speech(
    text=cleaned_content,
    ...
)

# Save cleaned content to database
story = StoryDB(
    title=title,
    content=cleaned_content,
    ...
)
```

**Location**: `populate_stories.py` (lines 437-523)

## Cleaning Rules

The cleaning function applies the following rules:

1. **Asterisks**: Removes sequences of 3 or more asterisks (`***`, `****`, etc.)
   - Preserves single and double asterisks for emphasis (e.g., `*italic*`, `**bold**`)

2. **Underscores**: Removes sequences of 3 or more underscores (`___`, `____`, etc.)
   - Preserves single and double underscores for emphasis

3. **Hyphens**: Removes sequences of 3 or more standalone hyphens (`---`, `----`, etc.)
   - Preserves hyphens within words (e.g., `well-known`, `self-made`)

4. **Excessive Newlines**: Reduces sequences of 3+ newlines to double newlines
   - Preserves paragraph spacing while removing excessive gaps

5. **Whitespace**: Trims leading and trailing whitespace from the entire content

## Testing

A comprehensive test suite has been created in `test_content_cleaning.py` that verifies:

- Removal of `****` markers
- Removal of multiple asterisks (`******`, `********`)
- Removal of underscores (`___`, `______`)
- Reduction of excessive newlines
- Preservation of hyphens in words
- Normal content remains unchanged

All tests pass successfully.

## Impact

### Benefits
1. **Cleaner Stories**: Stories no longer contain distracting formatting markers
2. **Consistent Output**: All stories have consistent formatting regardless of AI model quirks
3. **Better Audio**: Audio generation uses cleaned text without attempting to read markers
4. **Improved User Experience**: Users see clean, professional-looking stories

### No Breaking Changes
- Existing stories in the database are not affected
- The cleaning only applies to newly generated stories
- The API response format remains unchanged
- All existing integrations continue to work

## Files Modified

1. `src/api/routes.py` - Added cleaning function and integrated into story generation
2. `populate_stories.py` - Added cleaning function for bulk story population
3. `test_content_cleaning.py` - New test file to verify cleaning functionality

## Future Enhancements

Potential future improvements:

1. Add cleaning for other formatting markers if discovered
2. Make cleaning rules configurable via settings
3. Apply retroactive cleaning to existing stories in database
4. Add option to preserve certain formatting for specific use cases
