# Tale Generator - Flutter App

Мобильное приложение для генерации персонализированных детских сказок с использованием AI.

## Архитектура

Приложение построено на основе Clean Architecture и Domain-Driven Design (DDD):

- **Domain Layer**: Сущности, Value Objects, интерфейсы репозиториев
- **Application Layer**: Use Cases, DTO
- **Infrastructure Layer**: Реализация репозиториев, Supabase клиент
- **Presentation Layer**: UI, State Management (Riverpod)

## Структура проекта

```
lib/
├── domain/
│   ├── entities/
│   ├── value_objects/
│   └── repositories/
├── application/
│   ├── use_cases/
│   └── dto/
├── infrastructure/
│   ├── config/
│   ├── repositories/
│   └── external/
└── presentation/
    ├── screens/
    ├── widgets/
    └── providers/
```

## Настройка

Подробные инструкции по настройке см. в файле [SETUP.md](SETUP.md)

### Быстрый старт

1. Установите зависимости:
```bash
flutter pub get
```

2. Настройте Supabase:
   - Откройте `lib/infrastructure/config/supabase_config.dart`
   - Замените `YOUR_SUPABASE_URL` и `YOUR_SUPABASE_ANON_KEY` на ваши значения

3. Настройте API URL:
   - Откройте `lib/presentation/providers/repositories_provider.dart`
   - Замените `YOUR_API_BASE_URL` на URL вашего FastAPI backend

4. Запустите генерацию кода:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Запустите приложение:
```bash
flutter run
```

## Основные функции

- ✅ Аутентификация через Supabase Auth
- ✅ Просмотр списка сказок
- ✅ Генерация новых сказок (child, hero, combined типы)
- ✅ Управление детьми (добавление, удаление)
- ✅ Оценка сказок (1-10)
- ✅ Просмотр деталей сказки
- ✅ Многоязычность (English, Russian)
- ✅ Выбор морали сказки

## Технологии

- **Flutter** - UI фреймворк
- **Riverpod** - State Management
- **Supabase** - Backend (Auth, Database)
- **Clean Architecture** - Архитектурный паттерн
- **DDD** - Domain-Driven Design

## Структура кода

Приложение следует принципам Clean Architecture:

- **Domain Layer**: Бизнес-логика, сущности, интерфейсы
- **Application Layer**: Use Cases, DTO
- **Infrastructure Layer**: Реализация репозиториев, внешние сервисы
- **Presentation Layer**: UI, State Management

## Дополнительная информация

См. [FLUTTER_APP_ARCHITECTURE.md](FLUTTER_APP_ARCHITECTURE.md) для подробного описания архитектуры backend и структуры базы данных.

