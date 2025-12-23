# Manage Stories Utility

This utility provides a command-line interface for managing stories and children in the tale generator database.

## Installation

The utility uses the `click` library which should already be installed as part of the project dependencies:

```bash
uv pip install click
```

## Usage

All commands are accessed through the main script:

```bash
python manage_stories.py [COMMAND] [OPTIONS]
```

### Available Commands

#### Stories Management

- `list-all-stories` - List all stories in the database
- `list-child-stories CHILD_NAME` - List all stories for a specific child
- `list-language-stories LANGUAGE` - List all stories in a specific language
- `rate-story STORY_ID RATING` - Rate a story with a score from 1 to 10
- `delete-story STORY_ID` - Delete a story by ID

#### Children Management

- `list-all-children` - List all children in the database
- `list-children-by-name NAME` - List all children with a specific name
- `delete-child CHILD_ID` - Delete a child by ID

### Examples

```bash
# List all stories
python manage_stories.py list-all-stories

# List stories for a specific child
python manage_stories.py list-child-stories Emma

# List stories in Russian
python manage_stories.py list-language-stories ru

# Rate a story (assuming story ID is "123" and rating is 8)
python manage_stories.py rate-story 123 8

# Delete a story (assuming story ID is "123")
python manage_stories.py delete-story 123

# List all children
python manage_stories.py list-all-children

# List children with a specific name
python manage_stories.py list-children-by-name Emma

# Delete a child (assuming child ID is "456")
python manage_stories.py delete-child 456
```

### Help

Get help for any command:

```bash
python manage_stories.py --help
python manage_stories.py [COMMAND] --help
```