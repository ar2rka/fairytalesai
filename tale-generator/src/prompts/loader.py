"""Load prompt templates from Markdown files (Jinja2)."""

from pathlib import Path
from typing import List, Optional

from src.domain.value_objects import Language
from src.infrastructure.persistence.models import PromptDB
from src.core.logging import get_logger

logger = get_logger("prompts.loader")

_TEMPLATES_DIR = Path(__file__).resolve().parent / "templates"


class FilePromptLoader:
    """Loads prompt templates from .md files. One file per (story_type, language)."""

    def __init__(self, templates_dir: Optional[Path] = None):
        self._dir = Path(templates_dir) if templates_dir else _TEMPLATES_DIR
        self._cache: dict[str, List[PromptDB]] = {}

    def get_prompts(
        self,
        language: Language,
        story_type: Optional[str] = None,
    ) -> List[PromptDB]:
        """Return prompt parts for the given language and story_type.

        Each file is one template; returned as a single part (priority=1).
        Falls back to universal file {story_type}.md if {story_type}_{lang}.md missing.
        """
        if not story_type:
            return []

        key = f"{language.value}_{story_type}"
        if key in self._cache:
            return self._cache[key]

        # Try story_type_lang.md (e.g. child_en.md, child_ru.md)
        filename = f"{story_type}_{language.value}.md"
        path = self._dir / filename

        if not path.exists():
            logger.warning(f"Prompt template not found: {path}")
            self._cache[key] = []
            return []

        try:
            text = path.read_text(encoding="utf-8").strip()
        except Exception as e:
            logger.error(f"Failed to read {path}: {e}", exc_info=True)
            self._cache[key] = []
            return []

        part = PromptDB(
            id=None,
            priority=1,
            language=language.value,
            story_type=story_type,
            prompt_text=text,
            is_active=True,
            description=None,
        )
        result = [part]
        self._cache[key] = result
        logger.debug(f"Loaded prompt template: {filename}")
        return result
