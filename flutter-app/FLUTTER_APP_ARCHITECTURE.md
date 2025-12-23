# Архитектура Flutter приложения для Tale Generator

## Обзор проекта

Tale Generator - это сервис для генерации персонализированных детских сказок с использованием AI. Backend построен на FastAPI с использованием архитектуры Domain-Driven Design (DDD) и Clean Architecture. База данных - Supabase (PostgreSQL).

## Архитектура Backend

### Слои архитектуры

Проект организован в 4 основных слоя:

1. **Core Layer** (`src/core/`)
   - Исключения (`exceptions.py`)
   - Константы (`constants.py`)
   - Логирование (`logging.py`)

2. **Domain Layer** (`src/domain/`)
   - Сущности (`entities.py`)
   - Value Objects (`value_objects.py`)
   - Интерфейсы репозиториев (`repositories/`)
   - Доменные сервисы (`services/`)

3. **Application Layer** (`src/application/`)
   - DTO (Data Transfer Objects) (`dto.py`)
   - Use Cases (`use_cases/`)

4. **Infrastructure Layer** (`src/infrastructure/`)
   - Конфигурация (`config/`)
   - Модели персистентности (`persistence/`)
   - Кэширование (`cache/`)
   - Внешние сервисы (`external/`)

### Основные компоненты

- **API Routes**: FastAPI endpoints в `src/api/routes.py`
- **Supabase Client**: Асинхронный клиент для работы с БД
- **OpenRouter Client**: Интеграция с AI для генерации сказок
- **Voice Service**: Генерация аудио через ElevenLabs
- **Subscription Service**: Управление подписками и лимитами

## Структура базы данных Supabase

### Схема: `tales`

Все таблицы находятся в схеме `tales`, кроме `auth.users` (стандартная таблица Supabase Auth).

### Таблицы

#### 1. `user_profiles`

Расширяет стандартную таблицу `auth.users` из Supabase Auth.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK, FK на `auth.users(id)` |
| `name` | TEXT | Имя пользователя |
| `subscription_plan` | TEXT | План подписки: `free`, `starter`, `normal`, `premium` |
| `subscription_status` | TEXT | Статус: `active`, `inactive`, `cancelled`, `expired` |
| `subscription_start_date` | TIMESTAMPTZ | Дата начала подписки |
| `subscription_end_date` | TIMESTAMPTZ | Дата окончания подписки (NULL для бессрочных) |
| `monthly_story_count` | INTEGER | Количество сгенерированных сказок в текущем месяце |
| `last_reset_date` | TIMESTAMPTZ | Дата последнего сброса счетчика |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `updated_at` | TIMESTAMPTZ | Дата обновления |

**RLS Policies:**
- Пользователи могут видеть/изменять только свой профиль

#### 2. `children`

Профили детей для персонализации сказок.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK |
| `name` | TEXT | Имя ребенка |
| `age` | INTEGER | Возраст (1-18) |
| `gender` | TEXT | Пол: `male`, `female`, `other` |
| `interests` | TEXT[] | Массив интересов |
| `user_id` | UUID | FK на `auth.users(id)` |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `updated_at` | TIMESTAMPTZ | Дата обновления |

**RLS Policies:**
- Пользователи могут видеть/изменять только своих детей

#### 3. `heroes`

Герои для использования в сказках (опционально).

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK |
| `name` | TEXT | Имя героя |
| `gender` | TEXT | Пол: `male`, `female`, `other` |
| `appearance` | TEXT | Описание внешности |
| `personality_traits` | TEXT[] | Массив черт характера |
| `interests` | TEXT[] | Массив интересов |
| `strengths` | TEXT[] | Массив сильных сторон/способностей |
| `language` | TEXT | Язык героя: `en`, `ru` |
| `user_id` | UUID | FK на `auth.users(id)`, NULL для общих героев |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `updated_at` | TIMESTAMPTZ | Дата обновления |

**RLS Policies:**
- Пользователи могут видеть своих героев и героев без владельца (общие)
- Пользователи могут создавать/изменять/удалять только своих героев

#### 4. `stories`

Сгенерированные сказки.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK |
| `title` | TEXT | Заголовок сказки |
| `content` | TEXT | Текст сказки |
| `summary` | TEXT | Краткое содержание (опционально) |
| `language` | TEXT | Язык: `en`, `ru` |
| `child_id` | UUID | FK на `children(id)` |
| `child_name` | TEXT | Имя ребенка (дублируется для быстрого доступа) |
| `child_age` | INTEGER | Возраст ребенка |
| `child_gender` | TEXT | Пол ребенка |
| `child_interests` | TEXT[] | Интересы ребенка |
| `hero_id` | UUID | FK на `heroes(id)` (опционально) |
| `hero_name` | TEXT | Имя героя (опционально) |
| `hero_gender` | TEXT | Пол героя (опционально) |
| `hero_appearance` | TEXT | Внешность героя (опционально) |
| `relationship_description` | TEXT | Описание отношений ребенок-герой (для combined stories) |
| `rating` | INTEGER | Рейтинг (1-10, опционально) |
| `audio_file_url` | TEXT | URL аудио файла (опционально) |
| `audio_provider` | TEXT | Провайдер аудио (например, `elevenlabs`) |
| `audio_generation_metadata` | JSONB | Метаданные генерации аудио |
| `status` | TEXT | Статус: `draft`, `published`, `archived` |
| `user_id` | UUID | FK на `auth.users(id)` |
| `generation_id` | UUID | FK на `generations(generation_id)` |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `updated_at` | TIMESTAMPTZ | Дата обновления |

**RLS Policies:**
- Пользователи могут видеть/изменять только свои сказки

#### 5. `generations`

Трекинг генераций сказок (метаданные процесса генерации).

| Поле | Тип | Описание |
|------|-----|----------|
| `generation_id` | UUID | PK (часть составного ключа) |
| `attempt_number` | INTEGER | PK (часть составного ключа), номер попытки |
| `model_used` | TEXT | Использованная AI модель |
| `full_response` | JSONB | Полный ответ от OpenRouter API |
| `status` | TEXT | Статус: `pending`, `success`, `failed`, `timeout` |
| `prompt` | TEXT | Промпт, отправленный в AI |
| `user_id` | UUID | FK на `auth.users(id)` |
| `story_type` | TEXT | Тип: `child`, `hero`, `combined` |
| `story_length` | INTEGER | Длина в минутах |
| `hero_appearance` | TEXT | Внешность героя (для hero/combined) |
| `relationship_description` | TEXT | Описание отношений (для combined) |
| `moral` | TEXT | Мораль сказки |
| `error_message` | TEXT | Сообщение об ошибке (если failed) |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `completed_at` | TIMESTAMPTZ | Дата завершения |

**RLS Policies:**
- Пользователи могут видеть/изменять только свои генерации
- Удаление запрещено (аудит)

#### 6. `usage_tracking`

Трекинг использования для контроля лимитов подписки.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK |
| `user_id` | UUID | FK на `auth.users(id)` |
| `action_type` | TEXT | Тип действия: `story_generation`, `audio_generation`, `child_creation` |
| `action_timestamp` | TIMESTAMPTZ | Время действия |
| `resource_id` | UUID | ID связанного ресурса (story_id, child_id и т.д.) |
| `metadata` | JSONB | Дополнительные метаданные |
| `created_at` | TIMESTAMPTZ | Дата создания записи |

**RLS Policies:**
- Пользователи могут видеть только свои записи
- Только система может создавать записи
- Обновление и удаление запрещены (аудит)

#### 7. `purchase_transactions`

История покупок подписок.

| Поле | Тип | Описание |
|------|-----|----------|
| `id` | UUID | PK |
| `user_id` | UUID | FK на `auth.users(id)` |
| `from_plan` | TEXT | План до покупки: `free`, `starter`, `normal`, `premium` |
| `to_plan` | TEXT | План после покупки: `starter`, `normal`, `premium` |
| `amount` | DECIMAL(10,2) | Сумма покупки |
| `currency` | TEXT | Валюта (по умолчанию `USD`) |
| `payment_status` | TEXT | Статус: `pending`, `completed`, `failed`, `refunded` |
| `payment_method` | TEXT | Метод оплаты (например, `mock_card`, `stripe_card`) |
| `payment_provider` | TEXT | Провайдер (например, `mock`, `stripe`, `paddle`) |
| `transaction_reference` | TEXT | Референс транзакции от провайдера |
| `created_at` | TIMESTAMPTZ | Дата создания |
| `completed_at` | TIMESTAMPTZ | Дата завершения (NULL для pending/failed) |
| `metadata` | JSONB | Дополнительные данные |

**RLS Policies:**
- Пользователи могут видеть только свои транзакции
- Пользователи могут создавать транзакции
- Система может обновлять статус
- Удаление запрещено (аудит)

## Модель данных для Flutter

### Value Objects (Enum/Constants)

#### Language
```dart
enum Language {
  english('en', 'English'),
  russian('ru', 'Russian');
  
  final String code;
  final String displayName;
  
  const Language(this.code, this.displayName);
}
```

#### Gender
```dart
enum Gender {
  male('male'),
  female('female'),
  other('other');
  
  final String value;
  const Gender(this.value);
  
  String translate(Language language) {
    // Реализация перевода
  }
}
```

#### StoryMoral
```dart
enum StoryMoral {
  kindness('kindness'),
  honesty('honesty'),
  bravery('bravery'),
  friendship('friendship'),
  perseverance('perseverance'),
  empathy('empathy'),
  respect('respect'),
  responsibility('responsibility');
  
  final String value;
  const StoryMoral(this.value);
  
  String translate(Language language) {
    // Реализация перевода
  }
}
```

#### SubscriptionPlan
```dart
enum SubscriptionPlan {
  free('free'),
  starter('starter'),
  normal('normal'),
  premium('premium');
  
  final String value;
  const SubscriptionPlan(this.value);
}
```

#### SubscriptionStatus
```dart
enum SubscriptionStatus {
  active('active'),
  inactive('inactive'),
  cancelled('cancelled'),
  expired('expired');
  
  final String value;
  const SubscriptionStatus(this.value);
}
```

#### StoryType
```dart
enum StoryType {
  child('child'),
  hero('hero'),
  combined('combined');
  
  final String value;
  const StoryType(this.value);
}
```

#### GenerationStatus
```dart
enum GenerationStatus {
  pending('pending'),
  success('success'),
  failed('failed'),
  timeout('timeout');
  
  final String value;
  const GenerationStatus(this.value);
}
```

#### PaymentStatus
```dart
enum PaymentStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  refunded('refunded');
  
  final String value;
  const PaymentStatus(this.value);
}
```

### Entity Models

#### UserProfile
```dart
class UserProfile {
  final String id;
  final String name;
  final SubscriptionPlan subscriptionPlan;
  final SubscriptionStatus subscriptionStatus;
  final DateTime subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final int monthlyStoryCount;
  final DateTime lastResetDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.subscriptionPlan,
    required this.subscriptionStatus,
    required this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.monthlyStoryCount,
    required this.lastResetDate,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

#### Child
```dart
class Child {
  final String? id;
  final String name;
  final int age;
  final Gender gender;
  final List<String> interests;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Child({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Child.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

#### Hero
```dart
class Hero {
  final String? id;
  final String name;
  final Gender gender;
  final String appearance;
  final List<String> personalityTraits;
  final List<String> interests;
  final List<String> strengths;
  final Language language;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Hero({
    this.id,
    required this.name,
    required this.gender,
    required this.appearance,
    required this.personalityTraits,
    required this.interests,
    required this.strengths,
    required this.language,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Hero.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

#### Story
```dart
class Story {
  final String? id;
  final String title;
  final String content;
  final String? summary;
  final Language language;
  final String? childId;
  final String? childName;
  final int? childAge;
  final Gender? childGender;
  final List<String>? childInterests;
  final String? heroId;
  final String? heroName;
  final Gender? heroGender;
  final String? heroAppearance;
  final String? relationshipDescription;
  final int? rating; // 1-10
  final String? audioFileUrl;
  final String? audioProvider;
  final Map<String, dynamic>? audioGenerationMetadata;
  final String status; // draft, published, archived
  final String? userId;
  final String generationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Story({
    this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.language,
    this.childId,
    this.childName,
    this.childAge,
    this.childGender,
    this.childInterests,
    this.heroId,
    this.heroName,
    this.heroGender,
    this.heroAppearance,
    this.relationshipDescription,
    this.rating,
    this.audioFileUrl,
    this.audioProvider,
    this.audioGenerationMetadata,
    required this.status,
    this.userId,
    required this.generationId,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Story.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

#### Generation
```dart
class Generation {
  final String generationId;
  final int attemptNumber;
  final String modelUsed;
  final Map<String, dynamic>? fullResponse;
  final GenerationStatus status;
  final String prompt;
  final String userId;
  final StoryType storyType;
  final int? storyLength;
  final String? heroAppearance;
  final String? relationshipDescription;
  final String moral;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;
  
  Generation({
    required this.generationId,
    required this.attemptNumber,
    required this.modelUsed,
    this.fullResponse,
    required this.status,
    required this.prompt,
    required this.userId,
    required this.storyType,
    this.storyLength,
    this.heroAppearance,
    this.relationshipDescription,
    required this.moral,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });
  
  factory Generation.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

#### UsageTracking
```dart
class UsageTracking {
  final String id;
  final String userId;
  final String actionType; // story_generation, audio_generation, child_creation
  final DateTime actionTimestamp;
  final String? resourceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  
  UsageTracking({
    required this.id,
    required this.userId,
    required this.actionType,
    required this.actionTimestamp,
    this.resourceId,
    this.metadata,
    required this.createdAt,
  });
  
  factory UsageTracking.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
}
```

#### PurchaseTransaction
```dart
class PurchaseTransaction {
  final String id;
  final String userId;
  final SubscriptionPlan fromPlan;
  final SubscriptionPlan toPlan;
  final double amount;
  final String currency;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final String paymentProvider;
  final String transactionReference;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  
  PurchaseTransaction({
    required this.id,
    required this.userId,
    required this.fromPlan,
    required this.toPlan,
    required this.amount,
    required this.currency,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentProvider,
    required this.transactionReference,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });
  
  factory PurchaseTransaction.fromJson(Map<String, dynamic> json) {
    // Парсинг из JSON
  }
  
  Map<String, dynamic> toJson() {
    // Конвертация в JSON
  }
}
```

## API Endpoints

### Authentication
Все endpoints требуют аутентификации через Supabase Auth (JWT токен в заголовке `Authorization: Bearer <token>`).

### Основные Endpoints

#### Story Generation
- `POST /stories/generate` - Генерация новой сказки
  - Request: `GenerateStoryRequestDTO`
  - Response: `GenerateStoryResponseDTO`

#### Children Management
- `POST /children` - Создание профиля ребенка
- `GET /children` - Получение всех детей пользователя
- `GET /children/{child_id}` - Получение конкретного ребенка
- `DELETE /children/{child_id}` - Удаление ребенка

#### Stories Management
- `GET /stories` - Получение всех сказок пользователя
- `GET /stories/{story_id}` - Получение конкретной сказки
- `PUT /stories/{story_id}/rating` - Оценка сказки (1-10)
- `DELETE /stories/{story_id}` - Удаление сказки

#### Subscription Management
- `GET /users/subscription` - Получение информации о подписке
- `GET /subscription/plans` - Получение доступных планов
- `POST /subscription/purchase` - Покупка подписки
- `GET /subscription/purchases` - История покупок

## Планы подписки и лимиты

### Free Plan
- Лимит генераций в месяц: определяется в `SubscriptionService`
- Без аудио генерации

### Starter Plan
- Увеличенный лимит генераций
- Базовая аудио генерация

### Normal Plan
- Еще больший лимит генераций
- Расширенная аудио генерация

### Premium Plan
- Максимальный лимит генераций
- Полный доступ к функциям

Лимиты проверяются через `SubscriptionValidator` перед генерацией.

## Row Level Security (RLS)

Все таблицы используют RLS для безопасности:
- Пользователи видят только свои данные
- Пользователи могут изменять только свои данные
- Некоторые таблицы (generations, usage_tracking, purchase_transactions) не позволяют удаление для аудита

## Рекомендации для Flutter приложения

1. **Supabase Flutter SDK**: Используйте официальный `supabase_flutter` пакет для аутентификации и работы с БД
2. **State Management**: Рекомендуется использовать Riverpod или Bloc для управления состоянием
3. **Local Storage**: Используйте `hive` или `shared_preferences` для кэширования данных
4. **API Client**: Создайте отдельный слой для работы с REST API (если нужны дополнительные endpoints)
5. **Models**: Используйте `json_serializable` для автоматической генерации fromJson/toJson
6. **Error Handling**: Реализуйте централизованную обработку ошибок
7. **Offline Support**: Рассмотрите возможность офлайн режима с синхронизацией

## Дополнительные замечания

- Все даты в UTC (TIMESTAMPTZ)
- UUID используются для всех ID
- Массивы хранятся как PostgreSQL массивы (TEXT[])
- JSONB используется для гибких метаданных
- Все таблицы имеют `created_at` и `updated_at` для аудита
- Триггеры автоматически обновляют `updated_at` при изменении записи

