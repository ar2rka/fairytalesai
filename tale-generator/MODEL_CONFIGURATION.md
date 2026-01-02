# Конфигурация моделей через переменные окружения

Система поддерживает настройку моделей AI через переменные окружения.

## Доступные переменные окружения

### Основная модель генерации

**Переменная:** `LANGGRAPH_GENERATION_MODEL`

**Описание:** Основная модель для генерации историй. Если не указана, используется модель по умолчанию из `OPENROUTER_DEFAULT_MODEL`.

**Пример:**
```bash
export LANGGRAPH_GENERATION_MODEL="openai/gpt-4o"
# или
export LANGGRAPH_GENERATION_MODEL="anthropic/claude-3.5-sonnet"
```

### Fallback модель

**Переменная:** `OPENROUTER_FALLBACK_MODEL`

**Описание:** Модель, которая будет использоваться при ошибках или rate limit на основной модели. Если не указана, используется цепочка моделей по умолчанию.

**Пример:**
```bash
export OPENROUTER_FALLBACK_MODEL="openai/gpt-4o-mini"
# или
export OPENROUTER_FALLBACK_MODEL="anthropic/claude-3-haiku"
```

### Модель для верификации

**Переменная:** `LANGGRAPH_VALIDATION_MODEL`

**Описание:** Модель для валидации промптов перед генерацией истории.

**Пример:**
```bash
export LANGGRAPH_VALIDATION_MODEL="openai/gpt-4o-mini"
```

## Полный пример .env файла

```bash
# OpenRouter API ключ
OPENROUTER_API_KEY=your_api_key_here

# Основная модель для генерации
LANGGRAPH_GENERATION_MODEL=openai/gpt-4o

# Fallback модель
OPENROUTER_FALLBACK_MODEL=openai/gpt-4o-mini

# Модель для верификации
LANGGRAPH_VALIDATION_MODEL=openai/gpt-4o-mini

# Модель по умолчанию (используется если LANGGRAPH_GENERATION_MODEL не указана)
OPENROUTER_DEFAULT_MODEL=openai/gpt-4o-mini
```

## Доступные модели

Система поддерживает следующие модели OpenRouter:

- `openai/gpt-4o` - GPT-4 Optimized
- `openai/gpt-4o-mini` - GPT-4 Optimized Mini
- `anthropic/claude-3.5-sonnet` - Claude 3.5 Sonnet
- `anthropic/claude-3-haiku` - Claude 3 Haiku
- `meta-llama/llama-3.1-405b-instruct` - Llama 3.1 405B
- `meta-llama/llama-3.1-70b-instruct` - Llama 3.1 70B
- `meta-llama/llama-3.1-8b-instruct` - Llama 3.1 8B
- `google/gemma-2-27b-it` - Gemma 2 27B
- `mistralai/mixtral-8x22b-instruct` - Mixtral 8x22B
- `google/gemini-2.0-flash-exp:free` - Gemini 2.0 Flash (Free)
- `x-ai/grok-4.1-fast:free` - Grok 4.1 Fast (Free)
- `openai/gpt-oss-120b:exacto` - GPT OSS 120B

## Поведение по умолчанию

Если переменные окружения не установлены:

1. **Основная модель генерации**: Используется `OPENROUTER_DEFAULT_MODEL` (по умолчанию `openai/gpt-4o-mini`)
2. **Fallback модель**: Используется цепочка моделей по умолчанию:
   - `openai/gpt-4o-mini`
   - `anthropic/claude-3-haiku`
   - `meta-llama/llama-3.1-8b-instruct`
3. **Модель верификации**: Используется `openai/gpt-4o-mini`

## Приоритет настроек

1. Переменные окружения (наивысший приоритет)
2. Значения по умолчанию в коде
3. Fallback цепочка моделей (для fallback)

## Логирование

При запуске приложения в логах будет указано, какие модели используются:

```
Using configured fallback model: openai/gpt-4o-mini
🤖 Model: openai/gpt-4o
Validation Model: openai/gpt-4o-mini
```

