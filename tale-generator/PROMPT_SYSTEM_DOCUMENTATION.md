# Система генерации промптов - Документация

## Обзор

Система генерации промптов для создания персонализированных сказок использует модульную архитектуру с поддержкой различных типов персонажей и шаблонов на основе Jinja2, хранящихся в базе данных Supabase.

## Архитектура

### Компоненты системы

```
┌─────────────────────────────────────────────────────────────┐
│                    PromptService                            │
│  (Высокоуровневый сервис для генерации промптов)           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ├─────────────────┐
                       │                 │
                       ▼                 ▼
        ┌──────────────────────┐  ┌──────────────────────┐
        │ PromptTemplateService│  │  Fallback Methods    │
        │  (Jinja2 рендеринг)  │  │  (Встроенные методы) │
        └──────────┬───────────┘  └──────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  PromptRepository    │
        │  (Загрузка из БД)    │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │   Supabase Database   │
        │   (Таблица prompts)   │
        └───────────────────────┘
```

### Основные классы

1. **PromptService** (`src/domain/services/prompt_service.py`)
   - Высокоуровневый сервис для генерации промптов
   - Поддерживает три типа историй: child, hero, combined
   - Автоматически использует PromptTemplateService при наличии Supabase клиента
   - Fallback на встроенные методы при отсутствии подключения к БД

2. **PromptTemplateService** (`src/domain/services/prompt_template_service.py`)
   - Рендерит промпты из шаблонов базы данных через Jinja2
   - Поддерживает SandboxedEnvironment для безопасности
   - Объединяет несколько частей промпта по приоритету

3. **PromptRepository** (`src/infrastructure/persistence/prompt_repository.py`)
   - Загружает шаблоны промптов из Supabase
   - Кэширует результаты в памяти
   - Фильтрует по языку, типу истории и активности

## Типы персонажей

### BaseCharacter

Базовый интерфейс для всех типов персонажей.

```python
from abc import ABC, abstractmethod

class BaseCharacter(ABC):
    @abstractmethod
    def get_description_data(self) -> Dict[str, Any]:
        """Возвращает данные персонажа для рендеринга."""
        ...
    
    @abstractmethod
    def validate(self) -> None:
        """Валидирует данные персонажа."""
        ...
```

**Важно**: Разные типы персонажей используют разные представления возраста:
- `ChildCharacter` использует `age_category` (str, например '3-5')
- `HeroCharacter` использует `age` (int)

### ChildCharacter

Представляет ребёнка как главного героя истории.

**Атрибуты:**
- `name: str` - Имя ребёнка
- `age_category: str` - Возрастная категория (например, '2-3', '4-5', '6-7')
- `gender: str` - Пол ('male', 'female', 'other')
- `interests: List[str]` - Список интересов
- `description: Optional[str]` - Опциональное описание

**Валидация:**
- Имя не может быть пустым
- Возрастная категория должна быть валидной
- Пол не может быть пустым
- Должен быть хотя бы один интерес

**Пример использования:**
```python
from src.prompts.character_types import ChildCharacter

child = ChildCharacter(
    name="Аня",
    age_category="4-5",
    gender="female",
    interests=["котята", "цветы"],
    description="Аня очень добрая и всегда помогает младшим детям."
)
```

### HeroCharacter

Представляет героя как главного персонажа истории.

**Атрибуты:**
- `name: str` - Имя героя
- `age: int` - Возраст героя
- `gender: str` - Пол
- `appearance: str` - Описание внешности
- `personality_traits: List[str]` - Черты характера
- `strengths: List[str]` - Сильные стороны
- `interests: List[str]` - Интересы
- `language: Language` - Язык героя
- `description: Optional[str]` - Опциональное описание

**Валидация:**
- Все обязательные поля должны быть заполнены
- Возраст должен быть положительным числом
- Должен быть хотя бы один элемент в каждом списке (personality_traits, strengths, interests)

**Пример использования:**
```python
from src.prompts.character_types import HeroCharacter
from src.domain.value_objects import Language

hero = HeroCharacter(
    name="Капитан Чудо",
    age=10,
    gender="female",
    appearance="Носит красный плащ и маску",
    personality_traits=["храбрая", "мудрая"],
    strengths=["летает", "суперсила"],
    interests=["помощь людям", "справедливость"],
    language=Language.RUSSIAN,
    description="Капитан Чудо защищает город уже много лет."
)
```

### CombinedCharacter

Объединяет ребёнка и героя в одной истории.

**Атрибуты:**
- `child: ChildCharacter` - Персонаж-ребёнок
- `hero: HeroCharacter` - Персонаж-герой
- `relationship: Optional[str]` - Описание отношений между персонажами

**Свойства:**
- `name` - Имя ребёнка (основной персонаж)
- `age_category` - Возрастная категория ребёнка
- `gender` - Пол ребёнка

**Методы:**
- `get_merged_interests()` - Объединяет интересы обоих персонажей

**Пример использования:**
```python
from src.prompts.character_types import CombinedCharacter, ChildCharacter, HeroCharacter

combined = CombinedCharacter(
    child=child,
    hero=hero,
    relationship="Аня встречает легендарного героя Капитана Чудо"
)
```

## Структура базы данных

### Таблица `prompts`

Промпты хранятся в таблице Supabase `prompts` со следующей структурой:

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | Уникальный идентификатор |
| `priority` | INTEGER | Приоритет (меньше = выше приоритет) |
| `language` | TEXT | Язык ('en' или 'ru') |
| `story_type` | TEXT | Тип истории ('child', 'hero', 'combined') или NULL (универсальный) |
| `prompt_text` | TEXT | Текст шаблона Jinja2 |
| `is_active` | BOOLEAN | Активен ли промпт |
| `description` | TEXT | Описание части промпта (опционально) |
| `created_at` | TIMESTAMP | Дата создания |
| `updated_at` | TIMESTAMP | Дата обновления |

**Логика загрузки:**
- Промпты загружаются по языку и типу истории
- Универсальные промпты (story_type = NULL) используются для всех типов
- Результаты сортируются по приоритету (ascending)
- Только активные промпты (is_active = true) загружаются
- Части промпта объединяются двойным переносом строки

## Контекст для Jinja шаблонов

При рендеринге промпта в шаблон передаётся следующий контекст:

### Общие переменные

| Переменная | Тип | Описание |
|------------|-----|----------|
| `moral` | str | Нравственный урок истории |
| `language` | Language | Язык истории |
| `story_length` | int | Длина истории в минутах |
| `word_count` | int | Количество слов (story_length * 150) |
| `story_type` | str | Тип истории ('child', 'hero', 'combined') |
| `parent_story` | StoryDB \| None | Родительская история для продолжения |

### Переменные для ChildCharacter

| Переменная | Тип | Описание |
|------------|-----|----------|
| `child` | ChildCharacter | Объект персонажа-ребёнка |
| `child_name` | str | Имя ребёнка |
| `age_category` | str | Возрастная категория |
| `child_gender` | str | Пол ребёнка |
| `child_interests` | List[str] | Интересы ребёнка |
| `child_description` | str \| None | Описание ребёнка |

### Переменные для HeroCharacter

| Переменная | Тип | Описание |
|------------|-----|----------|
| `hero` | HeroCharacter | Объект персонажа-героя |
| `hero_name` | str | Имя героя |
| `hero_age` | int | Возраст героя |
| `hero_gender` | str | Пол героя |
| `hero_appearance` | str | Внешность героя |
| `hero_personality_traits` | List[str] | Черты характера |
| `hero_strengths` | List[str] | Сильные стороны |
| `hero_interests` | List[str] | Интересы героя |
| `hero_description` | str \| None | Описание героя |

### Переменные для CombinedCharacter

Доступны все переменные для `child` и `hero`, плюс:

| Переменная | Тип | Описание |
|------------|-----|----------|
| `relationship` | str | Описание отношений между персонажами |
| `merged_interests` | List[str] | Объединённые интересы обоих персонажей |

## Jinja фильтры

В шаблонах доступны следующие фильтры:

### `translate_moral`

Переводит нравственный урок на целевой язык.

```jinja
{{ moral | translate_moral(language) }}
```

**Пример:**
```jinja
Нравственный урок: {{ moral | translate_moral(language) }}
```

### `translate_gender`

Переводит пол на целевой язык.

```jinja
{{ gender | translate_gender(language) }}
```

**Пример:**
```jinja
Пол: {{ child_gender | translate_gender(language) }}
```

### `translate_interests`

Переводит список интересов на целевой язык.

```jinja
{{ interests | translate_interests(language) }}
```

**Пример:**
```jinja
Интересы: {{ child_interests | translate_interests(language) | join(", ") }}
```

### `format_age_category`

Форматирует возрастную категорию для промпта.

```jinja
{{ age_category | format_age_category(language) }}
```

**Пример:**
```jinja
Возраст: {{ age_category | format_age_category(language) }}
```

### `join`

Объединяет список строк с разделителем.

```jinja
{{ items | join(separator) }}
```

**Пример:**
```jinja
Черты характера: {{ hero_personality_traits | join(", ") }}
```

### `truncate`

Обрезает текст до указанной длины.

```jinja
{{ text | truncate(length) }}
```

**Пример:**
```jinja
{{ parent_story.content | truncate(300) if parent_story else "" }}
```

## Примеры шаблонов

### Пример 1: Промпт для ребёнка (русский)

```jinja
Создай детскую сказку на ночь со следующими характеристиками:
- Имя: {{ child_name }}
- Возраст: {{ age_category | format_age_category(language) }}
- Пол: {{ child_gender | translate_gender(language) }}
- Интересы: {{ child_interests | translate_interests(language) | join(", ") }}

{% if child_description %}
Дополнительная информация: {{ child_description }}
{% endif %}

Сказка должна содержать нравственный урок о "{{ moral | translate_moral(language) }}" и быть подходящей для детей в возрасте {{ age_category | format_age_category(language) }}.
Сделай сказку увлекательной, воображаемой и приблизительно {{ word_count }} слов длинной.
Включи имя ребенка как главного героя сказки.
Закончи сказку четким сообщением о нравственном уроке.
Напиши сказку на русском языке.
```

### Пример 2: Промпт для героя (английский)

```jinja
Create a bedtime story featuring a heroic character with the following characteristics:
- Name: {{ hero_name }}
- Age: {{ hero_age }}
- Gender: {{ hero_gender | translate_gender(language) }}
- Appearance: {{ hero_appearance }}
- Personality Traits: {{ hero_personality_traits | join(", ") }}
- Strengths: {{ hero_strengths | join(", ") }}
- Interests: {{ hero_interests | join(", ") }}

{% if hero_description %}
Additional information: {{ hero_description }}
{% endif %}

The story should focus on the moral value of "{{ moral | translate_moral(language) }}" and be appropriate for children.
Make the story engaging, imaginative, and approximately {{ word_count }} words long.
Include the hero's name as the main character in the story.
End the story with a clear message about the moral value.
Write the story in English.
```

### Пример 3: Промпт для комбинированной истории

```jinja
Create a bedtime story featuring both a child and a hero together:

Child Character:
- Name: {{ child_name }}
- Age: {{ age_category | format_age_category(language) }}
- Gender: {{ child_gender | translate_gender(language) }}
- Interests: {{ child_interests | translate_interests(language) | join(", ") }}

Hero Character:
- Name: {{ hero_name }}
- Age: {{ hero_age }}
- Gender: {{ hero_gender | translate_gender(language) }}
- Appearance: {{ hero_appearance }}
- Personality Traits: {{ hero_personality_traits | join(", ") }}
- Strengths: {{ hero_strengths | join(", ") }}

Relationship: {{ relationship }}

The story should focus on the moral value of "{{ moral | translate_moral(language) }}" and be appropriate for children aged {{ age_category | format_age_category(language) }}.
Make the story engaging, imaginative, and approximately {{ word_count }} words long.
Include both characters' names throughout the story and show how they work together.
End the story with a clear message about the moral value.
Write the story in {{ language.value }}.
```

### Пример 4: Продолжение истории

```jinja
{% if parent_story %}
Previous Story:
Title: {{ parent_story.title }}
Content: {{ parent_story.content | truncate(300) }}

This story is a continuation of the previous one. Create a natural continuation that develops the plot and characters from the previous story. Start the new story where the previous one ended and continue the adventures.

{% endif %}

{# Остальная часть промпта #}
```

## Использование в коде

### Генерация промпта для ребёнка

```python
from src.domain.services.prompt_service import PromptService
from src.domain.entities import Child
from src.domain.value_objects import Language, StoryLength

# Инициализация сервиса
prompt_service = PromptService(supabase_client=supabase_client)

# Создание персонажа
child = Child(
    name="Аня",
    age_category="4-5",
    gender=Gender.FEMALE,
    interests=["котята", "цветы"]
)

# Генерация промпта
prompt = prompt_service.generate_child_prompt(
    child=child,
    moral="kindness",
    language=Language.RUSSIAN,
    story_length=StoryLength.MEDIUM
)
```

### Генерация промпта для героя

```python
from src.domain.entities import Hero

hero = Hero(
    name="Капитан Чудо",
    age=10,
    gender=Gender.FEMALE,
    appearance="Носит красный плащ",
    personality_traits=["храбрая", "мудрая"],
    strengths=["летает"],
    interests=["помощь"],
    language=Language.RUSSIAN
)

prompt = prompt_service.generate_hero_prompt(
    hero=hero,
    moral="bravery",
    story_length=StoryLength.MEDIUM
)
```

### Генерация промпта для комбинированной истории

```python
prompt = prompt_service.generate_combined_prompt(
    child=child,
    hero=hero,
    moral="friendship",
    language=Language.RUSSIAN,
    story_length=StoryLength.MEDIUM
)
```

### Прямое использование PromptTemplateService

```python
from src.domain.services.prompt_template_service import PromptTemplateService
from src.infrastructure.persistence.prompt_repository import PromptRepository
from src.prompts.character_types import ChildCharacter

# Инициализация
repository = PromptRepository(supabase_client)
template_service = PromptTemplateService(repository)

# Создание персонажа
child_character = ChildCharacter(
    name="Аня",
    age_category="4-5",
    gender="female",
    interests=["котята", "цветы"]
)

# Рендеринг промпта
prompt = template_service.render_prompt(
    character=child_character,
    moral="kindness",
    language=Language.RUSSIAN,
    story_length=5,
    story_type="child"
)
```

## Приоритеты промптов

Промпты в базе данных имеют поле `priority`. При загрузке они сортируются по приоритету (ascending), и части объединяются в порядке приоритета.

**Рекомендации по приоритетам:**
- `1-10`: Основная структура промпта (описание персонажа, мораль)
- `11-20`: Дополнительные инструкции (длина, язык)
- `21-30`: Специальные инструкции (продолжение истории, форматирование)

## Кэширование

`PromptRepository` использует простое in-memory кэширование для загруженных промптов. Кэш можно очистить вызовом:

```python
repository.clear_cache()
```

## Обработка ошибок

### Отсутствие промптов

Если для указанного языка и типа истории не найдено промптов, система:
1. Пытается загрузить универсальные промпты (story_type = NULL)
2. Если и их нет, выбрасывает `ValueError`

### Ошибки рендеринга

Если при рендеринге части промпта возникает ошибка:
- Ошибка логируется
- Остальные части продолжают рендериться
- Пустые части игнорируются

### Fallback на встроенные методы

Если `PromptTemplateService` недоступен или возникает ошибка, `PromptService` автоматически использует встроенные методы генерации промптов.

## Безопасность

- Используется `SandboxedEnvironment` для ограничения возможностей Jinja2
- Автоматическое экранирование отключено (не рендерим HTML)
- Валидация всех входных данных через методы `validate()` персонажей

## Расширение системы

### Добавление нового типа персонажа

1. Создайте класс, наследующий `BaseCharacter`
2. Реализуйте методы `get_description_data()` и `validate()`
3. Обновите `PromptTemplateService._build_context()` для поддержки нового типа
4. Добавьте соответствующие переменные в контекст Jinja

### Добавление нового фильтра Jinja

1. Создайте функцию в `src/utils/jinja_helpers.py`
2. Зарегистрируйте её в `register_jinja_filters()`
3. Обновите документацию

### Добавление нового типа истории

1. Добавьте записи в таблицу `prompts` с новым `story_type`
2. Обновите `PromptService` для поддержки нового типа
3. Обновите валидацию в API endpoints

## Миграции

См. файлы миграций в `src/migrations/`:
- `001_create_heroes_table.sql` - Создание таблицы героев
- `002_populate_heroes_table.sql` - Заполнение героев
- `003_add_new_hero_example.sql` - Пример добавления героя

## Тестирование

Примеры тестов:
- `test_prompt_characters.py` - Тесты типов персонажей
- `test_prompt_template_system.py` - Тесты системы шаблонов
- `test_generate_story_endpoint.py` - Интеграционные тесты

## См. также

- `PROMPT_MODULE_IMPLEMENTATION.md` - История реализации модульной системы
- `STORY_TYPES_USER_GUIDE.md` - Руководство пользователя по типам историй
- `GENERATE_STORY_ENDPOINT_README.md` - Документация API endpoint

