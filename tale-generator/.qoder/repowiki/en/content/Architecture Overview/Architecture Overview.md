# Architecture Overview

<cite>
**Referenced Files in This Document**   
- [QUICK_START.md](file://QUICK_START.md)
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [IMPLEMENTATION_STATUS.md](file://IMPLEMENTATION_STATUS.md)
- [README.md](file://README.md)
- [src/domain/value_objects.py](file://src/domain/value_objects.py)
- [src/domain/entities.py](file://src/domain/entities.py)
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)
- [src/application/dto.py](file://src/application/dto.py)
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)
- [src/domain/services/story_service.py](file://src/domain/services/story_service.py)
- [src/domain/services/prompt_service.py](file://src/domain/services/prompt_service.py)
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)

## Introduction
The Tale Generator application has been refactored into a modern, layered architecture following Clean Architecture principles and Domain-Driven Design (DDD). This architectural documentation provides a comprehensive overview of the 4-layer structure: Core, Domain, Application, and Infrastructure. The refactoring has achieved production readiness with complete separation of concerns, type safety, and testability. The system enables personalized bedtime story generation for children with AI, supporting multiple languages, story rating, and audio narration capabilities.

## Project Structure
The Tale Generator application follows a clean, modular structure with well-defined layers. The architecture separates concerns into distinct packages, each with specific responsibilities. The src/ directory contains the core application code organized into four main layers: core (shared utilities), domain (business logic), application (use cases), and infrastructure (persistence and external services). This structure enables maintainability, testability, and scalability while following SOLID principles and dependency inversion.

```mermaid
graph TD
subgraph "src/"
subgraph "Core Layer"
core[core/]
core_exceptions[exceptions.py]
core_constants[constants.py]
core_logging[logging.py]
end
subgraph "Domain Layer"
domain[domain/]
value_objects[value_objects.py]
entities[entities.py]
repositories[repositories/]
services[services/]
end
subgraph "Application Layer"
application[application/]
dto[dto.py]
use_cases[use_cases/]
end
subgraph "Infrastructure Layer"
infrastructure[infrastructure/]
config[config/]
persistence[persistence/]
models[models.py]
end
end
core --> domain
domain --> application
application --> infrastructure
```

**Diagram sources**
- [src/domain/value_objects.py](file://src/domain/value_objects.py)
- [src/domain/entities.py](file://src/domain/entities.py)
- [src/application/dto.py](file://src/application/dto.py)
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py)

**Section sources**
- [QUICK_START.md](file://QUICK_START.md)
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)

## Core Components
The Tale Generator application's core components implement a 4-layer Clean Architecture with Domain-Driven Design. The Core layer provides shared utilities for exceptions, constants, and logging. The Domain layer contains business entities, value objects, repository interfaces, and domain services. The Application layer orchestrates use cases and defines data transfer objects (DTOs). The Infrastructure layer handles persistence, configuration, and external service integration. This separation ensures that business logic remains independent of technical implementation details.

**Section sources**
- [QUICK_START.md](file://QUICK_START.md)
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [IMPLEMENTATION_STATUS.md](file://IMPLEMENTATION_STATUS.md)

## Architecture Overview
The Tale Generator application implements a 4-layer Clean Architecture with Domain-Driven Design, following the principles of separation of concerns and dependency inversion. The architecture consists of Core, Domain, Application, and Infrastructure layers, where outer layers depend on inner layers through abstractions. This design enables testability, maintainability, and flexibility in implementation.

```mermaid
graph TD
subgraph "API Layer"
API[(FastAPI Routes)]
end
subgraph "Application Layer"
UseCases[Use Cases]
DTOs[DTOs]
end
subgraph "Domain Layer"
Entities[Entities]
ValueObjects[Value Objects]
Repositories[Repository Interfaces]
Services[Domain Services]
end
subgraph "Infrastructure Layer"
Persistence[Persistence]
Configuration[Configuration]
ExternalServices[External Services]
end
API --> UseCases
UseCases --> DTOs
UseCases --> Entities
UseCases --> Repositories
UseCases --> Services
Entities --> ValueObjects
Repositories --> Persistence
Services --> ExternalServices
UseCases --> Configuration
```

**Diagram sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)
- [src/domain/entities.py](file://src/domain/entities.py)
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)

## Detailed Component Analysis
The Tale Generator application's architecture is analyzed in detail across its four layers, focusing on the separation of concerns, dependency flow, and implementation patterns. Each layer has specific responsibilities and interacts with adjacent layers through well-defined interfaces, ensuring loose coupling and high cohesion.

### Domain Layer Analysis
The Domain layer contains the core business logic of the Tale Generator application, implementing rich entities, value objects, repository interfaces, and domain services. This layer is framework-agnostic and represents the business domain of personalized story generation for children.

#### Domain Entities and Value Objects
```mermaid
classDiagram
class Language {
+ENGLISH : Language
+RUSSIAN : Language
+display_name : str
+from_code(code : str) : Language
}
class Rating {
+value : int
+__str__() : str
+__int__() : int
}
class StoryLength {
+minutes : int
+word_count : int
+__int__() : int
+__str__() : str
}
class Child {
+name : str
+age : int
+gender : Gender
+interests : List[str]
+id : Optional[str]
+created_at : Optional[datetime]
+updated_at : Optional[datetime]
+add_interest(interest : str) : void
+remove_interest(interest : str) : void
}
class Story {
+title : str
+content : str
+moral : str
+language : Language
+child_id : Optional[str]
+rating : Optional[Rating]
+audio_file : Optional[AudioFile]
+model_used : Optional[str]
+id : Optional[str]
+created_at : Optional[datetime]
+updated_at : Optional[datetime]
+rate(rating_value : int) : void
+attach_audio(url : str, provider : str, metadata : Optional[Dict]) : void
+has_audio() : bool
+is_rated() : bool
+word_count : int
+extract_title_from_content() : str
}
class AudioFile {
+url : str
+provider : str
+metadata : Dict[str, Any]
}
Child --> Gender : "uses"
Story --> Language : "uses"
Story --> Rating : "uses"
Story --> StoryLength : "uses"
Story --> AudioFile : "has"
Story --> Child : "belongs to"
```

**Diagram sources**
- [src/domain/value_objects.py](file://src/domain/value_objects.py#L10-L188)
- [src/domain/entities.py](file://src/domain/entities.py#L10-L210)

**Section sources**
- [src/domain/value_objects.py](file://src/domain/value_objects.py)
- [src/domain/entities.py](file://src/domain/entities.py)
- [QUICK_START.md](file://QUICK_START.md)

#### Domain Services and Repository Interfaces
```mermaid
classDiagram
class Repository~T~ {
+save(entity : T) : T
+find_by_id(entity_id : str) : Optional[T]
+list_all() : List[T]
+delete(entity_id : str) : bool
}
class StoryRepository {
+save(story : Story) : Story
+find_by_id(story_id : str) : Optional[Story]
+find_by_child_id(child_id : str) : List[Story]
+find_by_child_name(child_name : str) : List[Story]
+find_by_language(language : Language) : List[Story]
+update_rating(story_id : str, rating : Rating) : bool
}
class ChildRepository {
+save(child : Child) : Child
+find_by_id(child_id : str) : Optional[Child]
+find_by_name(child_name : str) : List[Child]
+find_exact_match(name : str, age : int, gender : Gender) : Optional[Child]
}
class StoryService {
+create_story(title : str, content : str, moral : str, language : Language, child : Optional[Child], story_length : Optional[StoryLength]) : Story
+extract_title_from_content(content : str) : str
+attach_audio_to_story(story : Story, audio_url : str, provider : str, metadata : Optional[Dict]) : void
+rate_story(story : Story, rating_value : int) : void
+validate_story_request(child : Child, moral : str, language : Language, story_length : Optional[int]) : void
}
class PromptService {
+generate_child_prompt(child : Child, moral : str, language : Language, story_length : StoryLength) : str
+generate_hero_prompt(hero : Hero, moral : str, story_length : StoryLength) : str
+_generate_english_child_prompt(child : Child, moral : str, story_length : StoryLength) : str
+_generate_russian_child_prompt(child : Child, moral : str, story_length : StoryLength) : str
+_generate_english_hero_prompt(hero : Hero, moral : str, story_length : StoryLength) : str
+_generate_russian_hero_prompt(hero : Hero, moral : str, story_length : StoryLength) : str
+_translate_moral(moral : str, language : Language) : str
+_translate_interests(interests : List[str], language : Language) : List[str]
}
StoryRepository --> Repository : "extends"
ChildRepository --> Repository : "extends"
StoryService --> Story : "creates"
StoryService --> StoryRepository : "uses"
PromptService --> Language : "uses"
PromptService --> StoryLength : "uses"
```

**Diagram sources**
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)
- [src/domain/repositories/story_repository.py](file://src/domain/repositories/story_repository.py)
- [src/domain/repositories/child_repository.py](file://src/domain/repositories/child_repository.py)
- [src/domain/services/story_service.py](file://src/domain/services/story_service.py)
- [src/domain/services/prompt_service.py](file://src/domain/services/prompt_service.py)

**Section sources**
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)
- [src/domain/services/story_service.py](file://src/domain/services/story_service.py)
- [src/domain/services/prompt_service.py](file://src/domain/services/prompt_service.py)

### Application Layer Analysis
The Application layer orchestrates the use cases of the Tale Generator application, acting as an intermediary between the API layer and the Domain layer. It defines the application's use cases and data transfer objects (DTOs), ensuring that the business logic in the Domain layer is properly utilized while providing a clean interface for the API layer.

#### Use Cases and Data Transfer Objects
```mermaid
classDiagram
class StoryRequestDTO {
+child : ChildProfileDTO
+moral : Optional[StoryMoral]
+custom_moral : Optional[str]
+language : Language
+story_length : Optional[int]
+generate_audio : Optional[bool]
+voice_provider : Optional[str]
+voice_options : Optional[Dict[str, Any]]
}
class ChildProfileDTO {
+name : str
+age : int
+gender : Gender
+interests : List[str]
}
class StoryResponseDTO {
+title : str
+content : str
+moral : str
+language : Language
+story_length : Optional[int]
+audio_file_url : Optional[str]
}
class StoryDBResponseDTO {
+id : str
+title : str
+content : str
+moral : str
+language : str
+child_id : Optional[str]
+child_name : Optional[str]
+child_age : Optional[int]
+child_gender : Optional[str]
+child_interests : Optional[List[str]]
+story_length : Optional[int]
+rating : Optional[int]
+audio_file_url : Optional[str]
+audio_provider : Optional[str]
+audio_generation_metadata : Optional[Dict[str, Any]]
+model_used : Optional[str]
+created_at : Optional[str]
+updated_at : Optional[str]
}
class GenerateStoryUseCase {
-story_repository : StoryRepository
-child_repository : ChildRepository
-story_service : StoryService
-prompt_service : PromptService
-audio_service : AudioService
-ai_service : AIService
-storage_service : StorageService
+execute(request : StoryRequestDTO) : StoryResponseDTO
+_get_or_create_child(request : StoryRequestDTO) : Child
+_generate_and_upload_audio(story : Story, request : StoryRequestDTO) : Optional[str]
}
class RateStoryUseCase {
-story_repository : StoryRepository
-story_service : StoryService
+execute(story_id : str, rating : int) : StoryDBResponseDTO
}
GenerateStoryUseCase --> StoryRequestDTO : "input"
GenerateStoryUseCase --> StoryResponseDTO : "output"
GenerateStoryUseCase --> StoryRepository : "depends on"
GenerateStoryUseCase --> ChildRepository : "depends on"
GenerateStoryUseCase --> StoryService : "depends on"
GenerateStoryUseCase --> PromptService : "depends on"
GenerateStoryUseCase --> AudioService : "depends on"
StoryRequestDTO --> ChildProfileDTO : "contains"
StoryRequestDTO --> Language : "uses"
StoryResponseDTO --> Language : "uses"
RateStoryUseCase --> StoryRepository : "depends on"
RateStoryUseCase --> StoryService : "depends on"
RateStoryUseCase --> StoryDBResponseDTO : "output"
```

**Diagram sources**
- [src/application/dto.py](file://src/application/dto.py)
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)
- [src/application/use_cases/manage_stories.py](file://src/application/use_cases/manage_stories.py)

**Section sources**
- [src/application/dto.py](file://src/application/dto.py)
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)

#### Story Generation Use Case Flow
```mermaid
sequenceDiagram
participant Client as "Client App"
participant API as "API Route"
participant UseCase as "GenerateStoryUseCase"
participant Service as "Domain Services"
participant Repository as "Repositories"
participant External as "External Services"
Client->>API : POST /generate-story
API->>UseCase : execute(request)
UseCase->>ChildRepository : find_exact_match()
ChildRepository-->>UseCase : Child or None
alt Child not found
UseCase->>ChildRepository : save(new Child)
ChildRepository-->>UseCase : Saved Child
end
UseCase->>StoryService : validate_story_request()
StoryService-->>UseCase : Validation Result
UseCase->>PromptService : generate_child_prompt()
PromptService-->>UseCase : Prompt String
UseCase->>External : generate_story(prompt)
External-->>UseCase : AI Result
UseCase->>StoryService : extract_title_from_content()
StoryService-->>UseCase : Title
UseCase->>StoryService : create_story()
StoryService-->>UseCase : Story Entity
alt generate_audio requested
UseCase->>AudioService : generate_audio()
AudioService-->>UseCase : Audio Result
alt Audio generation successful
UseCase->>StorageService : upload_audio_file()
StorageService-->>UseCase : Audio URL
UseCase->>StoryService : attach_audio_to_story()
end
end
UseCase->>StoryRepository : save(story)
StoryRepository-->>UseCase : Saved Story
UseCase-->>API : StoryResponseDTO
API-->>Client : Response
```

**Diagram sources**
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)
- [src/domain/services/story_service.py](file://src/domain/services/story_service.py)
- [src/domain/services/prompt_service.py](file://src/domain/services/prompt_service.py)
- [src/domain/repositories/story_repository.py](file://src/domain/repositories/story_repository.py)

**Section sources**
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)

### Infrastructure Layer Analysis
The Infrastructure layer handles the technical implementation details of the Tale Generator application, including persistence, configuration management, and external service integration. This layer implements the abstractions defined in the Domain layer and provides concrete implementations for database access, configuration, and third-party services.

#### Persistence Models and Configuration
```mermaid
classDiagram
class ChildDB {
+id : Optional[str]
+name : str
+age : int
+gender : str
+interests : List[str]
+created_at : Optional[datetime]
+updated_at : Optional[datetime]
}
class StoryDB {
+id : Optional[str]
+title : str
+content : str
+moral : str
+child_id : Optional[str]
+child_name : Optional[str]
+child_age : Optional[int]
+child_gender : Optional[str]
+child_interests : Optional[List[str]]
+model_used : Optional[str]
+full_response : Optional[Any]
+generation_info : Optional[Any]
+language : str
+story_length : Optional[int]
+rating : Optional[int]
+audio_file_url : Optional[str]
+audio_provider : Optional[str]
+audio_generation_metadata : Optional[Dict[str, Any]]
+created_at : Optional[datetime]
+updated_at : Optional[datetime]
}
class Settings {
+database : DatabaseSettings
+ai_service : AIServiceSettings
+voice_service : VoiceServiceSettings
+application : ApplicationSettings
+logging : LoggingSettings
+get_settings() : Settings
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
+cors_origins : list[str]
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
StoryDB --> ChildDB : "references"
```

**Diagram sources**
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)

**Section sources**
- [src/infrastructure/persistence/models.py](file://src/infrastructure/persistence/models.py)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)

#### Voice Provider Factory Pattern
```mermaid
classDiagram
class VoiceProvider {
+metadata : ProviderMetadata
+validate_configuration() : bool
+generate_audio(text : str, language : Language, options : Dict) : AudioGenerationResult
}
class ElevenLabsProvider {
+metadata : ProviderMetadata
+validate_configuration() : bool
+generate_audio(text : str, language : Language, options : Dict) : AudioGenerationResult
}
class MockProvider {
+metadata : ProviderMetadata
+validate_configuration() : bool
+generate_audio(text : str, language : Language, options : Dict) : AudioGenerationResult
}
class VoiceProviderRegistry {
-providers : Dict[str, VoiceProvider]
-default_provider : Optional[str]
-fallback_providers : List[str]
+register(provider : VoiceProvider) : void
+unregister(provider_name : str) : bool
+get_provider(provider_name : Optional[str]) : Optional[VoiceProvider]
+get_provider_with_fallback(provider_name : Optional[str]) : Optional[VoiceProvider]
+list_providers() : List[str]
+list_available_providers() : List[str]
+get_default_provider_name() : Optional[str]
+set_default_provider(provider_name : str) : bool
+clear() : void
}
class get_registry {
+get_registry() : VoiceProviderRegistry
+reset_registry() : void
}
VoiceProviderRegistry --> VoiceProvider : "contains"
ElevenLabsProvider --> VoiceProvider : "implements"
MockProvider --> VoiceProvider : "implements"
get_registry --> VoiceProviderRegistry : "creates"
```

**Diagram sources**
- [src/voice_providers/base_provider.py](file://src/voice_providers/base_provider.py)
- [src/voice_providers/elevenlabs_provider.py](file://src/voice_providers/elevenlabs_provider.py)
- [src/voice_providers/mock_provider.py](file://src/voice_providers/mock_provider.py)
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py)

**Section sources**
- [src/voice_providers/provider_registry.py](file://src/voice_providers/provider_registry.py)

## Dependency Analysis
The Tale Generator application follows the dependency inversion principle, where high-level modules do not depend on low-level modules. Instead, both depend on abstractions. The dependency flow moves inward, from the Infrastructure layer to the Application layer, then to the Domain layer, and finally to the Core layer. This ensures that business logic remains independent of technical implementation details and external services.

```mermaid
graph TD
Infrastructure[Infrastructure Layer] --> Application[Application Layer]
Application --> Domain[Domain Layer]
Domain --> Core[Core Layer]
Core -.-> Domain
Domain -.-> Application
Application -.-> Infrastructure
style Infrastructure fill:#f9f,stroke:#333
style Application fill:#bbf,stroke:#333
style Domain fill:#f96,stroke:#333
style Core fill:#9f9,stroke:#333
subgraph "Abstractions"
RepositoryInterface[Repository Interface]
ServiceInterface[Service Interface]
end
Domain --> RepositoryInterface
Domain --> ServiceInterface
Infrastructure -.-> RepositoryInterface
Infrastructure -.-> ServiceInterface
```

**Diagram sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [src/domain/repositories/base.py](file://src/domain/repositories/base.py)
- [src/application/use_cases/generate_story.py](file://src/application/use_cases/generate_story.py)

**Section sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [IMPLEMENTATION_STATUS.md](file://IMPLEMENTATION_STATUS.md)

## Performance Considerations
The Tale Generator application's architecture is designed with performance in mind. The separation of concerns allows for targeted optimizations at each layer. The use of Pydantic models ensures efficient data validation and serialization. The repository pattern enables easy implementation of caching strategies at the persistence layer. The application supports async operations through FastAPI, allowing for non-blocking I/O operations when communicating with external services like OpenRouter and ElevenLabs. Connection pooling can be implemented at the database level to improve performance under load. The modular design also facilitates horizontal scaling of specific components as needed.

**Section sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [README.md](file://README.md)

## Troubleshooting Guide
When troubleshooting issues in the Tale Generator application, start by checking the structured logs which provide request-level context and correlation IDs. For configuration issues, verify that environment variables match the settings schema defined in `src/infrastructure/config/settings.py`. For database-related issues, ensure that the Supabase migrations have been applied correctly. For AI generation issues, check the OpenRouter API key and model availability. For audio generation issues, verify the ElevenLabs API key and provider configuration. The application's modular design allows for isolating issues to specific layers, making debugging more efficient.

**Section sources**
- [REFACTORING_COMPLETE.md](file://REFACTORING_COMPLETE.md)
- [README.md](file://README.md)
- [src/infrastructure/config/settings.py](file://src/infrastructure/config/settings.py)

## Conclusion
The Tale Generator application has successfully implemented a 4-layer Clean Architecture with Domain-Driven Design, achieving production readiness with complete separation of concerns, type safety, and testability. The architecture enables maintainability and scalability while following SOLID principles. The refactoring has transformed the application from a monolithic structure to a modular system with clear boundaries between layers. The Domain layer contains rich business logic with entities, value objects, and domain services, while the Application layer orchestrates use cases through well-defined interfaces. The Infrastructure layer handles persistence and external service integration, and the Core layer provides shared utilities. This architectural foundation supports future enhancements and ensures the application can evolve to meet changing requirements.