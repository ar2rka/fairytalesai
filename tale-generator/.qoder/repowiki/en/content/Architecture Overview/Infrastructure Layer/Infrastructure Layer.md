# Infrastructure Layer

<cite>
**Referenced Files in This Document**
- [src/supabase_client.py](file://src/supabase_client.py)
- [src/elevenlabs_client.py](file://src/elevenlabs_client.py)
- [src/openrouter_client.py](file://src/openrouter_client.py)
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py)
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)
- [src/domain/repositories/story_repository.py](file://src/domain/repositories/story_repository.py)
- [src/domain/repositories/child_repository.py](file://src/domain/repositories/child_repository.py)
- [src/voice_providers/base_provider.py](file://src/voice_providers/base_provider.py)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py)
- [src/voice_providers/voice_service.py](file://src/voice_providers/voice_service.py)
- [src/voice_providers/elevenlabs_provider.py](file://src/voice_providers/elevenlabs_provider.py)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)
- [src/core/constants.py](file://src/core/constants.py)
- [supabase/migrations/README.md](file://supabase/migrations/README.md)
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [External Service Integrations](#external-service-integrations)
4. [Database Persistence Layer](#database-persistence-layer)
5. [Configuration Management](#configuration-management)
6. [Voice Provider Infrastructure](#voice-provider-infrastructure)
7. [Error Handling and Resilience](#error-handling-and-resilience)
8. [Database Schema Evolution](#database-schema-evolution)
9. [Production Readiness](#production-readiness)
10. [Troubleshooting Guide](#troubleshooting-guide)
11. [Performance Optimization](#performance-optimization)

## Introduction

The Infrastructure Layer of the Tale Generator application serves as the foundation for all external integrations and persistent storage. This layer implements the domain interfaces defined in the Domain Layer while providing concrete implementations for database persistence, AI service communication, and voice generation capabilities. The infrastructure layer follows clean architecture principles, maintaining clear separation between external concerns and business logic.

The layer is built around several key responsibilities:
- **External Service Integration**: Managing connections to AI APIs (OpenRouter), voice synthesis services (ElevenLabs), and database systems (Supabase)
- **Repository Implementations**: Concrete implementations of domain repository interfaces using Supabase models
- **Configuration Management**: Type-safe settings management using Pydantic
- **Voice Provider Plugin Architecture**: Extensible audio generation system with fallback capabilities
- **Database Schema Evolution**: Managed migrations for database schema updates

## Architecture Overview

The Infrastructure Layer follows a layered architecture pattern that separates external concerns from business logic:

```mermaid
graph TB
subgraph "API Layer"
API[FastAPI Routes]
end
subgraph "Application Layer"
UC[Use Cases]
DTO[DTOs]
end
subgraph "Domain Layer"
RI[Repository Interfaces]
ENT[Entities]
VO[Value Objects]
end
subgraph "Infrastructure Layer"
subgraph "External Services"
OR[OpenRouter Client]
EL[ElevenLabs Client]
SC[Supabase Client]
end
subgraph "Repository Implementations"
SR[Story Repository]
CR[Child Repository]
HR[Hero Repository]
end
subgraph "Voice Providers"
PR[Provider Registry]
VS[Voice Service]
EP[ElevenLabs Provider]
MP[Mock Provider]
end
subgraph "Configuration"
SET[Settings Manager]
LOG[Logging Config]
end
end
API --> UC
UC --> RI
RI --> SR
RI --> CR
RI --> HR
SR --> SC
CR --> SC
HR --> SC
UC --> OR
UC --> EL
UC --> VS
VS --> PR
PR --> EP
PR --> MP
```

**Diagram sources**
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py#L1-L56)
- [src/supabase_client.py](file://src/supabase_client.py#L1-L914)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py#L1-L212)

**Section sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md#L107-L136)

## External Service Integrations

### OpenRouter API Client

The OpenRouter client provides intelligent retry mechanisms and comprehensive error handling for AI model interactions:

```mermaid
sequenceDiagram
participant UC as Use Case
participant OR as OpenRouterClient
participant API as OpenRouter API
participant RET as Retry Handler
UC->>OR : generate_story(prompt, model)
OR->>RET : Attempt 1
RET->>API : Chat completion request
API-->>RET : Rate limit error
RET->>RET : Wait with exponential backoff
RET->>API : Retry request
API-->>RET : Success response
RET-->>OR : StoryGenerationResult
OR-->>UC : Generated story
```

**Diagram sources**
- [src/openrouter_client.py](file://src/openrouter_client.py#L99-L161)

Key features include:
- **Intelligent Retry Logic**: Exponential backoff with configurable retry attempts
- **Model Abstraction**: Support for multiple AI models through enum-based selection
- **Generation Info Tracking**: Detailed metadata about API usage and costs
- **Timeout Management**: Configurable timeouts for external API calls

### ElevenLabs API Client

The ElevenLabs client handles text-to-speech generation with language-aware voice selection:

```mermaid
flowchart TD
Start([Text Input]) --> Validate[Validate Text Length]
Validate --> LangDetect[Detect Language]
LangDetect --> VoiceSelect[Select Appropriate Voice]
VoiceSelect --> VoiceFound{Voice Available?}
VoiceFound --> |Yes| GenSpeech[Generate Speech]
VoiceFound --> |No| Fallback[Fallback Voice Selection]
Fallback --> GenSpeech
GenSpeech --> AudioBytes[Convert to Audio Bytes]
AudioBytes --> Success([Return Audio Data])
VoiceFound --> |Error| LogWarning[Log Warning]
Fallback --> |Error| LogWarning
LogWarning --> GenSpeech
```

**Diagram sources**
- [src/elevenlabs_client.py](file://src/elevenlabs_client.py#L54-L133)

**Section sources**
- [src/openrouter_client.py](file://src/openrouter_client.py#L1-L161)
- [src/elevenlabs_client.py](file://src/elevenlabs_client.py#L1-L133)

## Database Persistence Layer

### Repository Pattern Implementation

The infrastructure layer implements domain repository interfaces using Supabase as the underlying database:

```mermaid
classDiagram
class Repository~T~ {
<<abstract>>
+save(entity : T) T
+find_by_id(entity_id : str) Optional[T]
+list_all() List[T]
+delete(entity_id : str) bool
}
class StoryRepository {
+find_by_child_id(child_id : str) List[Story]
+find_by_child_name(child_name : str) List[Story]
+find_by_language(language : Language) List[Story]
+update_rating(story_id : str, rating : Rating) Optional[Story]
}
class ChildRepository {
+find_by_name(name : str) List[Child]
+find_exact_match(name : str, age : int, gender : Gender) Optional[Child]
}
class SupabaseStoryRepository {
-client : SupabaseClient
+save(entity : Story) Story
+find_by_id(id : str) Optional[Story]
+list_all() List[Story]
+delete(id : str) bool
+find_by_child_id(child_id : str) List[Story]
+find_by_child_name(child_name : str) List[Story]
+find_by_language(language : Language) List[Story]
+update_rating(story_id : str, rating : Rating) Optional[Story]
}
class SupabaseChildRepository {
-client : SupabaseClient
+save(entity : Child) Child
+find_by_id(id : str) Optional[Child]
+list_all() List[Child]
+delete(id : str) bool
+find_by_name(name : str) List[Child]
+find_exact_match(name : str, age : int, gender : Gender) Optional[Child]
}
Repository <|-- StoryRepository
Repository <|-- ChildRepository
StoryRepository <|.. SupabaseStoryRepository
ChildRepository <|.. SupabaseChildRepository
```

**Diagram sources**
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py#L8-L56)
- [src/domain/repositories/story_repository.py](file://src/domain/repositories/story_repository.py#L10-L61)
- [src/domain/repositories/child_repository.py](file://src/domain/repositories/child_repository.py#L10-L38)

### Supabase Model Integration

The infrastructure defines database models that map to Supabase tables:

| Model | Purpose | Key Fields | Relationships |
|-------|---------|------------|---------------|
| `ChildDB` | Child profile storage | `id`, `name`, `age`, `gender`, `interests` | One-to-many with Stories |
| `HeroDB` | Character profile storage | `id`, `name`, `gender`, `appearance`, `personality_traits` | One-to-many with Stories |
| `StoryDB` | Story content and metadata | `id`, `title`, `content`, `moral`, `child_id`, `language` | Many-to-one with Children/Heroes |

**Section sources**
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py#L1-L55)
- [src/domain/repositories/story_repository.py](file://src/domain/repositories/story_repository.py#L1-L61)
- [src/domain/repositories/child_repository.py](file://src/domain/repositories/child_repository.py#L1-L38)

## Configuration Management

### Pydantic Settings Architecture

The configuration system uses Pydantic Settings for type-safe, environment-variable-based configuration:

```mermaid
classDiagram
class Settings {
+database : DatabaseSettings
+ai_service : AIServiceSettings
+voice_service : VoiceServiceSettings
+application : ApplicationSettings
+logging : LoggingSettings
+get_settings() Settings
+reset_settings() None
}
class DatabaseSettings {
+url : str
+key : str
+schema_name : str
+timeout : int
}
class AIServiceSettings {
+api_key : str
+default_model : str
+max_tokens : int
+temperature : float
+max_retries : int
+retry_delay : float
}
class VoiceServiceSettings {
+api_key : Optional[str]
+enabled : bool
}
class ApplicationSettings {
+environment : str
+host : str
+port : int
+debug : bool
+cors_origins : List[str]
}
class LoggingSettings {
+level : str
+format : str
+file : Optional[str]
+json_format : bool
}
Settings --> DatabaseSettings
Settings --> AIServiceSettings
Settings --> VoiceServiceSettings
Settings --> ApplicationSettings
Settings --> LoggingSettings
```

**Diagram sources**
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py#L117-L169)

### Environment Variable Management

Configuration is managed through environment variables with sensible defaults:

| Category | Environment Variables | Purpose |
|----------|----------------------|---------|
| Database | `SUPABASE_URL`, `SUPABASE_KEY` | Supabase connection details |
| AI Service | `OPENROUTER_API_KEY` | OpenRouter API authentication |
| Voice Service | `ELEVENLABS_API_KEY` | ElevenLabs API authentication |
| Application | `ENVIRONMENT`, `PORT` | Runtime configuration |
| Logging | `LOG_LEVEL`, `LOG_FORMAT` | Logging behavior |

**Section sources**
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py#L1-L169)
- [src/core/constants.py](file://src/core/constants.py#L1-L38)

## Voice Provider Infrastructure

### Plugin Architecture

The voice provider system implements a plugin architecture enabling extensible audio generation:

```mermaid
graph TB
subgraph "Voice Service Layer"
VS[VoiceService]
AG[AudioGenerationResult]
end
subgraph "Provider Registry"
PR[VoiceProviderRegistry]
GP[get_provider_with_fallback]
end
subgraph "Provider Implementations"
EP[ElevenLabsProvider]
MP[MockProvider]
BP[BaseProvider]
end
subgraph "Configuration"
ENV[Environment Variables]
META[ProviderMetadata]
end
VS --> PR
PR --> GP
GP --> EP
GP --> MP
EP --> BP
MP --> BP
PR --> ENV
BP --> META
VS --> AG
```

**Diagram sources**
- [src/voice_providers/voice_service.py](file://src/voice_providers/voice_service.py#L25-L236)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py#L12-L212)

### Provider Capabilities

Each voice provider implements the base provider interface with specific capabilities:

| Provider | Streaming | Max Text Length | Supported Formats | Languages |
|----------|-----------|-----------------|-------------------|-----------|
| ElevenLabs | ✓ | 5000 chars | MP3, PCM | 12+ languages |
| Mock | ✗ | Unlimited | MP3 | N/A |

### Fallback Strategy

The provider registry implements sophisticated fallback logic:

```mermaid
flowchart TD
Start([Audio Generation Request]) --> Primary[Get Primary Provider]
Primary --> Validate{Primary Valid?}
Validate --> |Yes| Generate[Generate Audio]
Validate --> |No| Default[Get Default Provider]
Default --> ValidateDefault{Default Valid?}
ValidateDefault --> |Yes| Generate
ValidateDefault --> |No| Fallbacks[Try Fallback Providers]
Fallbacks --> TryFallback{Any Fallbacks?}
TryFallback --> |Yes| NextFallback[Next Fallback Provider]
NextFallback --> ValidateFallback{Valid?}
ValidateFallback --> |Yes| Generate
ValidateFallback --> |No| TryFallback
TryFallback --> |No| AnyProviders{Any Available Providers?}
AnyProviders --> |Yes| FirstAvailable[Use First Available]
AnyProviders --> |No| Error[Return Error]
FirstAvailable --> Generate
Generate --> Success{Success?}
Success --> |Yes| Return[Return Audio]
Success --> |No| Error
```

**Diagram sources**
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py#L100-L140)

**Section sources**
- [src/voice_providers/base_provider.py](file://src/voice_providers/base_provider.py#L1-L97)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py#L1-L212)
- [src/voice_providers/voice_service.py](file://src/voice_providers/voice_service.py#L1-L236)
- [src/voice_providers/elevenlabs_provider.py](file://src/voice_providers/elevenlabs_provider.py#L1-L220)

## Error Handling and Resilience

### Retry Mechanisms

The infrastructure implements multiple layers of retry logic:

| Component | Retry Strategy | Max Attempts | Backoff |
|-----------|---------------|--------------|---------|
| OpenRouter Client | Exponential backoff | 3 | 1s → 2s → 4s |
| ElevenLabs Client | Immediate retry | 1 | N/A |
| Supabase Client | Connection timeout | N/A | 10s |

### Error Classification

```mermaid
graph TD
Error[External Service Error] --> Classify{Error Type}
Classify --> |Network Timeout| Transient[Transient Error]
Classify --> |API Rate Limit| Transient
Classify --> |Invalid Credentials| Permanent[Permanent Error]
Classify --> |Service Unavailable| Transient
Transient --> Retry[Retry with Backoff]
Retry --> Success{Success?}
Success --> |Yes| Return[Return Result]
Success --> |No| Exhausted{Max Retries?}
Exhausted --> |No| Retry
Exhausted --> |Yes| Fallback[Try Fallback]
Permanent --> LogError[Log Error]
LogError --> Return
Fallback --> Alternative[Alternative Provider]
Alternative --> Return
```

### Connection Timeouts

External service clients implement configurable timeouts:

- **Database**: 10-second timeout for all operations
- **AI Services**: 30-second timeout for generation requests
- **Voice Services**: 15-second timeout for speech generation

**Section sources**
- [src/openrouter_client.py](file://src/openrouter_client.py#L119-L161)
- [src/supabase_client.py](file://src/supabase_client.py#L33-L42)

## Database Schema Evolution

### Migration System

The application uses a structured migration system for database schema evolution:

```mermaid
graph LR
subgraph "Migration Files"
M1[001_create_stories_table.sql]
M2[002_add_model_info_to_stories.sql]
M3[004_add_language_to_stories.sql]
M4[005_create_children_table.sql]
M5[006_add_rating_to_stories.sql]
M6[007_add_generation_info_to_stories.sql]
M7[008_add_audio_provider_tracking.sql]
end
subgraph "Migration Tools"
RM[run_migrations.py]
AM[apply_migration.py]
end
subgraph "Schema Evolution"
S1[Initial Schema]
S2[Enhanced Stories]
S3[Multi-language Support]
S4[Children Tables]
S5[Ratings System]
S6[Generation Metadata]
S7[Audio Tracking]
end
RM --> M1
RM --> M2
RM --> M3
RM --> M4
RM --> M5
RM --> M6
RM --> M7
M1 --> S1
M2 --> S2
M3 --> S3
M4 --> S4
M5 --> S5
M6 --> S6
M7 --> S7
```

**Diagram sources**
- [supabase/migrations/README.md](file://supabase/migrations/README.md#L1-L50)

### Migration Best Practices

The migration system follows these principles:
- **Version Control**: Each migration is versioned and reversible
- **Incremental Changes**: Small, focused changes minimize risk
- **Data Preservation**: Data migrations preserve existing records
- **Testing Support**: Migrations can be tested independently

**Section sources**
- [supabase/migrations/README.md](file://supabase/migrations/README.md#L1-L50)

## Production Readiness

### Clean Integration Boundaries

The infrastructure layer maintains strict separation between domains:

```mermaid
graph TB
subgraph "Domain Layer"
DI[Domain Interfaces]
DE[Domain Entities]
DS[Domain Services]
end
subgraph "Infrastructure Layer"
II[Infrastructure Implementations]
IC[Infrastructure Clients]
IR[Infrastructure Repositories]
end
subgraph "External Systems"
ES[External Services]
DB[Database]
FS[File Storage]
end
DI -.-> II
II -.-> IC
IC -.-> ES
IR -.-> IC
IR -.-> DB
IC -.-> FS
```

### Quality Assurance

The infrastructure layer incorporates multiple quality assurance measures:

- **Type Safety**: Complete type hints throughout
- **Validation**: Pydantic validation for all inputs
- **Logging**: Structured logging with correlation IDs
- **Monitoring**: Health checks and metrics collection
- **Testing**: Comprehensive unit and integration tests

**Section sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md#L1-L421)

## Troubleshooting Guide

### Common Issues and Solutions

#### Connection Timeouts

**Symptoms**: Requests hang or fail with timeout errors
**Causes**: Network latency, external service overload, incorrect timeout configuration
**Solutions**:
- Verify network connectivity to external services
- Check external service status pages
- Adjust timeout values in configuration
- Implement circuit breaker pattern for external calls

#### Provider Failures

**Symptoms**: Voice generation fails consistently
**Causes**: API key issues, quota exceeded, service unavailable
**Solutions**:
- Verify API keys are correctly configured
- Check service quotas and billing
- Enable fallback providers in configuration
- Monitor service health indicators

#### Database Connection Issues

**Symptoms**: Database operations fail or hang
**Causes**: Connection pool exhaustion, schema mismatches, permission issues
**Solutions**:
- Verify database credentials and connectivity
- Check connection pool configuration
- Run database migrations
- Review database logs for errors

### Debugging Strategies

#### Enable Debug Logging

```python
import logging
logging.getLogger("tale_generator").setLevel(logging.DEBUG)
```

#### Monitor External Service Health

```python
# Check provider availability
providers = voice_service.get_available_providers()
print(f"Available providers: {providers}")

# Test individual providers
for provider_name in providers:
    provider = registry.get_provider(provider_name)
    if provider.validate_configuration():
        print(f"{provider_name} is healthy")
```

#### Database Connectivity Testing

```python
# Test Supabase connection
try:
    client = SupabaseClient()
    # Test basic operations
    client.get_all_stories()
    print("Database connection successful")
except Exception as e:
    print(f"Database connection failed: {e}")
```

## Performance Optimization

### Caching Strategies

The infrastructure layer supports various caching approaches:

#### Client-Side Caching
- **Voice Provider Lists**: Cache available voices to reduce API calls
- **Language Detection**: Cache language detection results
- **Model Information**: Cache AI model capabilities

#### Database Caching
- **Connection Pooling**: Reuse database connections
- **Query Result Caching**: Cache frequently accessed data
- **Schema Metadata**: Cache table structure information

### Async Operations

The architecture supports asynchronous operations where appropriate:

```mermaid
sequenceDiagram
participant API as API Endpoint
participant UC as Use Case
participant AS as Async Service
participant ES as External Service
API->>UC : async generate_story()
UC->>AS : async process_request()
AS->>ES : async external_call()
ES-->>AS : response
AS-->>UC : processed_data
UC-->>API : story_response
```

### Monitoring and Metrics

Key performance indicators to monitor:

| Metric | Purpose | Threshold |
|--------|---------|-----------|
| API Response Time | External service performance | < 5s |
| Database Query Time | Database performance | < 2s |
| Voice Generation Time | Audio processing performance | < 30s |
| Error Rate | System reliability | < 1% |
| Provider Availability | Service health | > 95% |

### Optimization Tips

1. **Connection Management**: Use connection pooling for database and external services
2. **Batch Operations**: Group multiple database operations when possible
3. **Async Processing**: Use async patterns for I/O-bound operations
4. **Resource Cleanup**: Properly close connections and resources
5. **Monitoring**: Implement comprehensive monitoring and alerting

**Section sources**
- [src/core/constants.py](file://src/core/constants.py#L28-L38)