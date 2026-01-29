# Промпты (шаблоны)

Промпты хранятся в **файлах** в `templates/` и рендерятся через **Jinja2**.

## Структура

- Один файл на пару (тип истории, язык): `{story_type}_{lang}.md`
- Типы: `child`, `hero`, `combined`
- Языки: `en`, `ru`

Примеры: `child_en.md`, `child_ru.md`, `hero_en.md`, `hero_ru.md`, `combined_en.md`, `combined_ru.md`.

## Переменные в шаблоне (Jinja)

- **child** — объект ребёнка: `name`, `age_category`, `gender`, `interests`
- **hero** — объект героя: `name`, `age`, `gender`, `appearance`, `personality_traits`, `strengths`, `interests`
- **moral**, **language**, **word_count**, **story_length**, **story_type**
- **parent_story** — опционально: `title`, `summary`, `content`
- **relationship** — только для `combined`: строка связи ребёнок–герой

## Фильтры Jinja

Доступны из `src.utils.jinja_helpers`: `translate_moral`, `translate_gender`, `translate_interests`, `format_age_category`, `join`, `truncate`.

## Загрузка

`FilePromptLoader` в `src/prompts/loader.py` читает шаблоны из `templates/` и отдаёт их в `PromptTemplateService`. БД для промптов не используется.
