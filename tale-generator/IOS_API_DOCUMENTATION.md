# Документация API для iOS приложения

## Содержание

1. [Общая информация](#общая-информация)
2. [Аутентификация](#аутентификация)
3. [Эндпоинты для генерации историй](#эндпоинты-для-генерации-историй)
4. [Управление профилями детей](#управление-профилями-детей)
5. [Управление подписками](#управление-подписками)
6. [Бесплатные истории](#бесплатные-истории)
7. [Примеры Swift кода](#примеры-swift-кода)
8. [Обработка ошибок](#обработка-ошибок)

---

## Общая информация

### Базовый URL

```
https://your-api-domain.com/api/v1
```

Для разработки:
```
http://localhost:8000/api/v1
```

### Формат данных

- **Content-Type**: `application/json`
- **Accept**: `application/json`

### Версионирование

Все эндпоинты используют префикс `/api/v1`

---

## Аутентификация

Все защищенные эндпоинты требуют JWT токен в заголовке `Authorization`.

### Формат заголовка

```
Authorization: Bearer <JWT_TOKEN>
```

### Получение токена

Токен получается через Supabase Auth. После успешной аутентификации пользователя, Supabase возвращает `access_token`, который используется для всех последующих запросов.

### Пример на Swift

```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

---

## Эндпоинты для генерации историй

### POST /stories/generate

Генерирует персонализированную сказку для ребенка.

#### Запрос

**URL**: `POST /api/v1/stories/generate`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Body**:

```json
{
  "language": "ru",
  "child_id": "123e4567-e89b-12d3-a456-426614174000",
  "story_type": "child",
  "hero_id": "987fcdeb-51a2-43f7-b123-9876543210ab",
  "story_length": 5,
  "moral": "kindness",
  "custom_moral": null,
  "parent_id": null,
  "generate_audio": false,
  "voice_provider": null,
  "voice_options": null
}
```

**Параметры**:

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `language` | string | Да | Язык истории: `"en"` или `"ru"` |
| `child_id` | string (UUID) | Да | ID профиля ребенка |
| `story_type` | string | Нет | Тип истории: `"child"`, `"hero"`, `"combined"` (по умолчанию: `"child"`) |
| `hero_id` | string (UUID) | Условно | Требуется для `story_type: "hero"` или `"combined"` |
| `story_length` | integer | Нет | Длина истории в минутах (1-30, по умолчанию: 5) |
| `moral` | string | Нет | Предопределенная мораль (kindness, honesty, bravery, friendship и т.д.) |
| `custom_moral` | string | Нет | Кастомная мораль (если не подходит предопределенная) |
| `parent_id` | string (UUID) | Нет | ID родительской истории для продолжения |
| `generate_audio` | boolean | Нет | Генерировать ли аудио (по умолчанию: `false`) |
| `voice_provider` | string | Нет | Провайдер голоса (например, `"elevenlabs"`) |
| `voice_options` | object | Нет | Опции для провайдера голоса |

**Типы историй**:

- `"child"` - История только с ребенком в главной роли
- `"hero"` - История только с героем в главной роли
- `"combined"` - История с ребенком и героем вместе

#### Ответ (200 OK)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Эмма и волшебный сад",
  "content": "Жила-была девочка по имени Эмма...",
  "moral": "kindness",
  "language": "ru",
  "story_type": "combined",
  "story_length": 5,
  "child": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "name": "Эмма",
    "age_category": "5-7",
    "gender": "female",
    "interests": ["единороги", "феи", "принцессы"]
  },
  "hero": {
    "id": "987fcdeb-51a2-43f7-b123-9876543210ab",
    "name": "Капитан Чудо",
    "gender": "male",
    "appearance": "Храбрый капитан с золотым компасом"
  },
  "relationship_description": "Эмма встречает легендарного героя Капитана Чудо",
  "audio_file_url": "https://storage.supabase.co/.../story.mp3",
  "created_at": "2024-12-01T12:00:00Z"
}
```

#### Ошибки

**400 Bad Request** - Неверные параметры запроса:
```json
{
  "detail": "Hero ID is required for combined stories"
}
```

**401 Unauthorized** - Неверный или отсутствующий токен:
```json
{
  "detail": "Not authenticated"
}
```

**402 Payment Required** - Превышен лимит подписки:
```json
{
  "detail": "Monthly story limit exceeded. You have used 5/5 stories this month.",
  "error_code": "MONTHLY_LIMIT_EXCEEDED",
  "limit_info": {
    "current_plan": "free",
    "monthly_limit": 5,
    "stories_used": 5,
    "reset_date": "2025-01-01T00:00:00Z"
  }
}
```

**404 Not Found** - Ребенок или герой не найден:
```json
{
  "detail": "Child with ID {child_id} not found"
}
```

**500 Internal Server Error** - Ошибка генерации:
```json
{
  "detail": "Story generation failed: {error_message}"
}
```

---

## Управление профилями детей

### POST /children

Создает новый профиль ребенка.

#### Запрос

**URL**: `POST /api/v1/children`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Body**:

```json
{
  "name": "Эмма",
  "age_category": "5-7",
  "gender": "female",
  "interests": ["единороги", "феи", "принцессы"]
}
```

**Параметры**:

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `name` | string | Да | Имя ребенка |
| `age_category` | string | Да | Возрастная категория: `"2-3"`, `"3-5"`, `"5-7"` |
| `gender` | string | Да | Пол: `"male"` или `"female"` |
| `interests` | array[string] | Да | Массив интересов (минимум 1 элемент) |

**Поддерживаемые форматы age_category**:
- `"2-3"`, `"2-3 года"`, `"2-3 лет"`
- `"3-5"`, `"4-5"`, `"3-5 лет"`
- `"5-7"`, `"6-7"`, `"5-7 лет"`

#### Ответ (200 OK)

```json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Эмма",
  "age_category": "5-7",
  "gender": "female",
  "interests": ["единороги", "феи", "принцессы"],
  "created_at": "2024-12-01T12:00:00Z"
}
```

#### Ошибки

**400 Bad Request** - Неверные параметры:
```json
{
  "detail": "Invalid age_category: {value}"
}
```

**402 Payment Required** - Превышен лимит профилей:
```json
{
  "detail": "Child profile limit exceeded for your free plan. Maximum 2 child profiles allowed."
}
```

---

## Управление подписками

### GET /users/subscription

Получает информацию о текущей подписке пользователя и статистику использования.

#### Запрос

**URL**: `GET /api/v1/users/subscription`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

#### Ответ (200 OK)

```json
{
  "subscription": {
    "plan": "free",
    "status": "active",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": null
  },
  "limits": {
    "monthly_stories": 5,
    "stories_used": 3,
    "stories_remaining": 2,
    "reset_date": "2025-01-01T00:00:00Z",
    "child_profiles_limit": 2,
    "child_profiles_count": 1,
    "audio_enabled": false,
    "hero_stories_enabled": false,
    "combined_stories_enabled": false,
    "max_story_length": 5,
    "priority_support": false
  },
  "features": {
    "audio_generation": false,
    "hero_stories": false,
    "combined_stories": false,
    "priority_support": false
  }
}
```

**Планы подписки**:
- `"free"` - Бесплатный план
- `"basic"` - Базовый план
- `"premium"` - Премиум план

### GET /subscription/plans

Получает список всех доступных планов подписки.

#### Запрос

**URL**: `GET /api/v1/subscription/plans`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

#### Ответ (200 OK)

```json
{
  "plans": [
    {
      "tier": "free",
      "display_name": "Free",
      "description": "Бесплатный план с базовыми возможностями",
      "monthly_price": 0.0,
      "annual_price": 0.0,
      "features": ["Базовые истории"],
      "limits": {
        "monthly_stories": 5,
        "child_profiles": 2,
        "max_story_length": 5,
        "audio_enabled": false,
        "hero_stories_enabled": false,
        "combined_stories_enabled": false,
        "priority_support": false
      },
      "is_purchasable": false,
      "is_current": true
    },
    {
      "tier": "basic",
      "display_name": "Basic",
      "description": "Базовый план с расширенными возможностями",
      "monthly_price": 9.99,
      "annual_price": 99.99,
      "features": ["Больше историй", "Аудио генерация"],
      "limits": {
        "monthly_stories": 30,
        "child_profiles": 5,
        "max_story_length": 15,
        "audio_enabled": true,
        "hero_stories_enabled": true,
        "combined_stories_enabled": false,
        "priority_support": false
      },
      "is_purchasable": true,
      "is_current": false
    },
    {
      "tier": "premium",
      "display_name": "Premium",
      "description": "Премиум план со всеми возможностями",
      "monthly_price": 19.99,
      "annual_price": 199.99,
      "features": ["Неограниченные истории", "Все типы историй", "Приоритетная поддержка"],
      "limits": {
        "monthly_stories": -1,
        "child_profiles": -1,
        "max_story_length": 30,
        "audio_enabled": true,
        "hero_stories_enabled": true,
        "combined_stories_enabled": true,
        "priority_support": true
      },
      "is_purchasable": true,
      "is_current": false
    }
  ],
  "current_plan": "free"
}
```

**Примечание**: `-1` в лимитах означает неограниченное количество.

### POST /subscription/purchase

Покупка или обновление плана подписки.

#### Запрос

**URL**: `POST /api/v1/subscription/purchase`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Query Parameters**:

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `plan_tier` | string | Да | Уровень плана: `"free"`, `"basic"`, `"premium"` |
| `billing_cycle` | string | Да | Цикл оплаты: `"monthly"` или `"annual"` |
| `payment_method` | string | Да | Метод оплаты (например, `"apple_pay"`, `"card"`) |

**Body**:

```json
{
  "plan_tier": "basic",
  "billing_cycle": "monthly",
  "payment_method": "apple_pay"
}
```

#### Ответ (200 OK)

```json
{
  "success": true,
  "transaction_id": "550e8400-e29b-41d4-a716-446655440000",
  "subscription": {
    "plan": "basic",
    "status": "active",
    "start_date": "2024-12-01T00:00:00Z",
    "end_date": "2025-01-01T00:00:00Z"
  },
  "message": "Successfully upgraded to basic plan"
}
```

#### Ошибки

**400 Bad Request** - Неверные параметры:
```json
{
  "detail": "Invalid plan tier: {tier}"
}
```

**402 Payment Required** - Ошибка обработки платежа:
```json
{
  "detail": "Payment processing failed"
}
```

### GET /subscription/purchases

Получает историю покупок пользователя.

#### Запрос

**URL**: `GET /api/v1/subscription/purchases`

**Headers**:
```
Authorization: Bearer <JWT_TOKEN>
```

**Query Parameters**:

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `status` | string | Нет | Фильтр по статусу: `"pending"`, `"completed"`, `"failed"`, `"refunded"` |
| `limit` | integer | Нет | Максимум записей (по умолчанию: 50, максимум: 100) |
| `offset` | integer | Нет | Смещение для пагинации (по умолчанию: 0) |

**Пример**: `GET /api/v1/subscription/purchases?status=completed&limit=10&offset=0`

#### Ответ (200 OK)

```json
{
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "user-uuid",
      "from_plan": "free",
      "to_plan": "basic",
      "amount": 9.99,
      "currency": "USD",
      "payment_status": "completed",
      "payment_method": "apple_pay",
      "payment_provider": "mock",
      "transaction_reference": "txn_123456",
      "created_at": "2024-12-01T12:00:00Z",
      "completed_at": "2024-12-01T12:01:00Z",
      "metadata": {}
    }
  ],
  "total": 1
}
```

---

## Бесплатные истории

### GET /free-stories

Получает список бесплатных историй (публичный эндпоинт, не требует аутентификации).

#### Запрос

**URL**: `GET /api/v1/free-stories`

**Query Parameters**:

| Параметр | Тип | Обязательный | Описание |
|----------|-----|--------------|----------|
| `age_category` | string | Нет | Фильтр по возрасту: `"2-3"`, `"3-5"`, `"5-7"` |
| `language` | string | Нет | Фильтр по языку: `"en"` или `"ru"` |
| `limit` | integer | Нет | Максимум историй (1-1000, по умолчанию: без ограничений) |

**Примеры**:
- `GET /api/v1/free-stories?age_category=5-7&language=ru&limit=10`
- `GET /api/v1/free-stories?language=en`

#### Ответ (200 OK)

```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Приключения в волшебном лесу",
    "content": "Жила-была девочка...",
    "age_category": "5-7",
    "language": "ru",
    "created_at": "2024-12-01T12:00:00Z"
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "title": "The Magic Garden",
    "content": "Once upon a time...",
    "age_category": "3-5",
    "language": "en",
    "created_at": "2024-12-01T11:00:00Z"
  }
]
```

---

## Примеры Swift кода

### Структуры данных

```swift
import Foundation

// MARK: - Story Generation Request
struct GenerateStoryRequest: Codable {
    let language: String
    let childId: String
    let storyType: String?
    let heroId: String?
    let storyLength: Int?
    let moral: String?
    let customMoral: String?
    let parentId: String?
    let generateAudio: Bool?
    let voiceProvider: String?
    let voiceOptions: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case language
        case childId = "child_id"
        case storyType = "story_type"
        case heroId = "hero_id"
        case storyLength = "story_length"
        case moral
        case customMoral = "custom_moral"
        case parentId = "parent_id"
        case generateAudio = "generate_audio"
        case voiceProvider = "voice_provider"
        case voiceOptions = "voice_options"
    }
}

// MARK: - Story Generation Response
struct GenerateStoryResponse: Codable {
    let id: String
    let title: String
    let content: String
    let moral: String
    let language: String
    let storyType: String
    let storyLength: Int
    let child: ChildInfo
    let hero: HeroInfo?
    let relationshipDescription: String?
    let audioFileUrl: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, moral, language
        case storyType = "story_type"
        case storyLength = "story_length"
        case child, hero
        case relationshipDescription = "relationship_description"
        case audioFileUrl = "audio_file_url"
        case createdAt = "created_at"
    }
}

struct ChildInfo: Codable {
    let id: String
    let name: String
    let ageCategory: String
    let gender: String
    let interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, gender, interests
        case ageCategory = "age_category"
    }
}

struct HeroInfo: Codable {
    let id: String
    let name: String
    let gender: String
    let appearance: String
}

// MARK: - Create Child Request
struct CreateChildRequest: Codable {
    let name: String
    let ageCategory: String
    let gender: String
    let interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case ageCategory = "age_category"
        case gender, interests
    }
}

// MARK: - Subscription Info
struct SubscriptionInfo: Codable {
    let subscription: Subscription
    let limits: Limits
    let features: Features
}

struct Subscription: Codable {
    let plan: String
    let status: String
    let startDate: String
    let endDate: String?
    
    enum CodingKeys: String, CodingKey {
        case plan, status
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

struct Limits: Codable {
    let monthlyStories: Int
    let storiesUsed: Int
    let storiesRemaining: Int
    let resetDate: String
    let childProfilesLimit: Int
    let childProfilesCount: Int
    let audioEnabled: Bool
    let heroStoriesEnabled: Bool
    let combinedStoriesEnabled: Bool
    let maxStoryLength: Int
    let prioritySupport: Bool
    
    enum CodingKeys: String, CodingKey {
        case monthlyStories = "monthly_stories"
        case storiesUsed = "stories_used"
        case storiesRemaining = "stories_remaining"
        case resetDate = "reset_date"
        case childProfilesLimit = "child_profiles_limit"
        case childProfilesCount = "child_profiles_count"
        case audioEnabled = "audio_enabled"
        case heroStoriesEnabled = "hero_stories_enabled"
        case combinedStoriesEnabled = "combined_stories_enabled"
        case maxStoryLength = "max_story_length"
        case prioritySupport = "priority_support"
    }
}

struct Features: Codable {
    let audioGeneration: Bool
    let heroStories: Bool
    let combinedStories: Bool
    let prioritySupport: Bool
    
    enum CodingKeys: String, CodingKey {
        case audioGeneration = "audio_generation"
        case heroStories = "hero_stories"
        case combinedStories = "combined_stories"
        case prioritySupport = "priority_support"
    }
}

// MARK: - API Error
struct APIError: Codable, Error {
    let detail: String
    let errorCode: String?
    let limitInfo: LimitInfo?
    
    enum CodingKeys: String, CodingKey {
        case detail
        case errorCode = "error_code"
        case limitInfo = "limit_info"
    }
}

struct LimitInfo: Codable {
    let currentPlan: String
    let monthlyLimit: Int
    let storiesUsed: Int
    let resetDate: String
    
    enum CodingKeys: String, CodingKey {
        case currentPlan = "current_plan"
        case monthlyLimit = "monthly_limit"
        case storiesUsed = "stories_used"
        case resetDate = "reset_date"
    }
}
```

### API Service

```swift
import Foundation

class TaleGeneratorAPI {
    static let shared = TaleGeneratorAPI()
    
    private let baseURL = "https://your-api-domain.com/api/v1"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func createRequest(
        endpoint: String,
        method: String,
        accessToken: String? = nil
    ) -> URLRequest? {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(APIError(detail: "Invalid response")))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError(detail: "No data received")))
                return
            }
            
            // Check for errors
            if httpResponse.statusCode >= 400 {
                if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                    completion(.failure(apiError))
                } else {
                    completion(.failure(APIError(detail: "HTTP \(httpResponse.statusCode)")))
                }
                return
            }
            
            // Decode successful response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(T.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Story Generation
    
    func generateStory(
        request: GenerateStoryRequest,
        accessToken: String,
        completion: @escaping (Result<GenerateStoryResponse, Error>) -> Void
    ) {
        guard var urlRequest = createRequest(
            endpoint: "/stories/generate",
            method: "POST",
            accessToken: accessToken
        ) else {
            completion(.failure(APIError(detail: "Invalid URL")))
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(urlRequest, responseType: GenerateStoryResponse.self, completion: completion)
    }
    
    // MARK: - Children Management
    
    func createChild(
        request: CreateChildRequest,
        accessToken: String,
        completion: @escaping (Result<ChildInfo, Error>) -> Void
    ) {
        guard var urlRequest = createRequest(
            endpoint: "/children",
            method: "POST",
            accessToken: accessToken
        ) else {
            completion(.failure(APIError(detail: "Invalid URL")))
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        performRequest(urlRequest, responseType: ChildInfo.self, completion: completion)
    }
    
    // MARK: - Subscription
    
    func getSubscription(
        accessToken: String,
        completion: @escaping (Result<SubscriptionInfo, Error>) -> Void
    ) {
        guard let urlRequest = createRequest(
            endpoint: "/users/subscription",
            method: "GET",
            accessToken: accessToken
        ) else {
            completion(.failure(APIError(detail: "Invalid URL")))
            return
        }
        
        performRequest(urlRequest, responseType: SubscriptionInfo.self, completion: completion)
    }
    
    func getAvailablePlans(
        accessToken: String,
        completion: @escaping (Result<PlansResponse, Error>) -> Void
    ) {
        guard let urlRequest = createRequest(
            endpoint: "/subscription/plans",
            method: "GET",
            accessToken: accessToken
        ) else {
            completion(.failure(APIError(detail: "Invalid URL")))
            return
        }
        
        performRequest(urlRequest, responseType: PlansResponse.self, completion: completion)
    }
    
    // MARK: - Free Stories
    
    func getFreeStories(
        ageCategory: String? = nil,
        language: String? = nil,
        limit: Int? = nil,
        completion: @escaping (Result<[FreeStory], Error>) -> Void
    ) {
        var components = URLComponents(string: "\(baseURL)/free-stories")
        var queryItems: [URLQueryItem] = []
        
        if let ageCategory = ageCategory {
            queryItems.append(URLQueryItem(name: "age_category", value: ageCategory))
        }
        if let language = language {
            queryItems.append(URLQueryItem(name: "language", value: language))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components?.url else {
            completion(.failure(APIError(detail: "Invalid URL")))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        performRequest(request, responseType: [FreeStory].self, completion: completion)
    }
}

// MARK: - Additional Response Types

struct PlansResponse: Codable {
    let plans: [Plan]
    let currentPlan: String
}

struct Plan: Codable {
    let tier: String
    let displayName: String
    let description: String
    let monthlyPrice: Double
    let annualPrice: Double
    let features: [String]
    let limits: PlanLimits
    let isPurchasable: Bool
    let isCurrent: Bool
}

struct PlanLimits: Codable {
    let monthlyStories: Int
    let childProfiles: Int
    let maxStoryLength: Int
    let audioEnabled: Bool
    let heroStoriesEnabled: Bool
    let combinedStoriesEnabled: Bool
    let prioritySupport: Bool
}

struct FreeStory: Codable {
    let id: String
    let title: String
    let content: String
    let ageCategory: String
    let language: String
    let createdAt: String
}
```

### Примеры использования

```swift
// MARK: - Генерация истории

func generateStoryExample() {
    let request = GenerateStoryRequest(
        language: "ru",
        childId: "123e4567-e89b-12d3-a456-426614174000",
        storyType: "combined",
        heroId: "987fcdeb-51a2-43f7-b123-9876543210ab",
        storyLength: 5,
        moral: "kindness",
        customMoral: nil,
        parentId: nil,
        generateAudio: false,
        voiceProvider: nil,
        voiceOptions: nil
    )
    
    TaleGeneratorAPI.shared.generateStory(
        request: request,
        accessToken: userAccessToken
    ) { result in
        switch result {
        case .success(let story):
            print("История создана: \(story.title)")
            print("Содержание: \(story.content)")
            if let audioUrl = story.audioFileUrl {
                print("Аудио доступно: \(audioUrl)")
            }
        case .failure(let error):
            if let apiError = error as? APIError {
                print("Ошибка API: \(apiError.detail)")
                if let limitInfo = apiError.limitInfo {
                    print("Лимит: \(limitInfo.storiesUsed)/\(limitInfo.monthlyLimit)")
                }
            } else {
                print("Ошибка: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Создание профиля ребенка

func createChildExample() {
    let request = CreateChildRequest(
        name: "Эмма",
        ageCategory: "5-7",
        gender: "female",
        interests: ["единороги", "феи", "принцессы"]
    )
    
    TaleGeneratorAPI.shared.createChild(
        request: request,
        accessToken: userAccessToken
    ) { result in
        switch result {
        case .success(let child):
            print("Профиль создан: \(child.name), ID: \(child.id)")
        case .failure(let error):
            print("Ошибка: \(error.localizedDescription)")
        }
    }
}

// MARK: - Получение информации о подписке

func getSubscriptionExample() {
    TaleGeneratorAPI.shared.getSubscription(
        accessToken: userAccessToken
    ) { result in
        switch result {
        case .success(let subscriptionInfo):
            print("План: \(subscriptionInfo.subscription.plan)")
            print("Использовано историй: \(subscriptionInfo.limits.storiesUsed)/\(subscriptionInfo.limits.monthlyStories)")
            print("Осталось: \(subscriptionInfo.limits.storiesRemaining)")
        case .failure(let error):
            print("Ошибка: \(error.localizedDescription)")
        }
    }
}

// MARK: - Получение бесплатных историй

func getFreeStoriesExample() {
    TaleGeneratorAPI.shared.getFreeStories(
        ageCategory: "5-7",
        language: "ru",
        limit: 10
    ) { result in
        switch result {
        case .success(let stories):
            print("Найдено историй: \(stories.count)")
            for story in stories {
                print("- \(story.title)")
            }
        case .failure(let error):
            print("Ошибка: \(error.localizedDescription)")
        }
    }
}
```

---

## Обработка ошибок

### Коды статусов HTTP

| Код | Описание | Действие |
|-----|----------|----------|
| 200 | Успешно | Обработать ответ |
| 400 | Неверный запрос | Проверить параметры запроса |
| 401 | Не авторизован | Обновить токен или запросить повторную авторизацию |
| 402 | Требуется оплата | Показать экран покупки подписки |
| 404 | Не найдено | Показать сообщение "Ресурс не найден" |
| 500 | Ошибка сервера | Показать сообщение об ошибке, предложить повторить позже |

### Обработка ошибок лимитов

```swift
func handleAPIError(_ error: Error) {
    if let apiError = error as? APIError {
        switch apiError.errorCode {
        case "MONTHLY_LIMIT_EXCEEDED":
            if let limitInfo = apiError.limitInfo {
                showLimitExceededAlert(
                    currentPlan: limitInfo.currentPlan,
                    used: limitInfo.storiesUsed,
                    limit: limitInfo.monthlyLimit,
                    resetDate: limitInfo.resetDate
                )
            }
        case "CHILD_LIMIT_EXCEEDED":
            showUpgradePrompt(message: "Достигнут лимит профилей детей")
        default:
            showErrorAlert(message: apiError.detail)
        }
    } else {
        showErrorAlert(message: error.localizedDescription)
    }
}

func showLimitExceededAlert(
    currentPlan: String,
    used: Int,
    limit: Int,
    resetDate: String
) {
    let message = """
    Вы использовали все доступные истории в этом месяце.
    
    Использовано: \(used)/\(limit)
    Сброс: \(formatDate(resetDate))
    
    Хотите обновить подписку?
    """
    
    // Показать alert с кнопками "Обновить" и "Отмена"
}
```

### Retry логика

```swift
func generateStoryWithRetry(
    request: GenerateStoryRequest,
    accessToken: String,
    maxRetries: Int = 3,
    completion: @escaping (Result<GenerateStoryResponse, Error>) -> Void
) {
    var retryCount = 0
    
    func attempt() {
        TaleGeneratorAPI.shared.generateStory(
            request: request,
            accessToken: accessToken
        ) { result in
            switch result {
            case .success(let story):
                completion(.success(story))
            case .failure(let error):
                if retryCount < maxRetries {
                    retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount)) {
                        attempt()
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    attempt()
}
```

---

## Дополнительные рекомендации

### Кэширование

Рекомендуется кэшировать:
- Информацию о подписке (обновлять при каждом запуске приложения)
- Список профилей детей
- Список бесплатных историй (обновлять раз в день)

### Индикаторы загрузки

Генерация истории может занимать 10-30 секунд. Обязательно показывайте индикатор загрузки и возможность отмены запроса.

### Офлайн режим

Для лучшего UX рекомендуется:
- Сохранять сгенерированные истории локально
- Показывать сохраненные истории в офлайн режиме
- Синхронизировать при восстановлении соединения

### Безопасность

- Никогда не храните токены в открытом виде
- Используйте Keychain для хранения токенов
- Обновляйте токены перед истечением срока действия
- Используйте HTTPS для всех запросов

---

## Контакты и поддержка

При возникновении вопросов или проблем обращайтесь к команде разработки.

**Версия документации**: 1.0  
**Дата обновления**: 2024-12-01

