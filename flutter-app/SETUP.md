# Настройка Flutter приложения Tale Generator

## Предварительные требования

1. Flutter SDK (>=3.0.0)
2. Xcode (для iOS разработки)
3. Аккаунт Supabase

## Шаги настройки

### 1. Установка зависимостей

```bash
flutter pub get
```

### 2. Настройка Supabase

1. Откройте файл `lib/infrastructure/config/supabase_config.dart`
2. Замените `YOUR_SUPABASE_URL` на ваш Supabase URL
3. Замените `YOUR_SUPABASE_ANON_KEY` на ваш Supabase Anon Key

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
```

### 3. Настройка API URL

1. Откройте файл `lib/presentation/providers/repositories_provider.dart`
2. Замените `YOUR_API_BASE_URL` на URL вашего FastAPI backend

```dart
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: 'https://your-api-url.com', // Замените на ваш API URL
    supabase: ref.watch(supabaseProvider),
  );
});
```

### 4. Генерация кода

Запустите генерацию кода для JSON сериализации:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Настройка iOS

1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Настройте Bundle Identifier
3. Настройте Signing & Capabilities

### 6. Запуск приложения

```bash
flutter run
```

## Структура проекта

```
lib/
├── domain/              # Доменный слой
│   ├── entities/        # Сущности
│   ├── value_objects/   # Value Objects (Enums)
│   └── repositories/    # Интерфейсы репозиториев
├── application/         # Слой приложения
│   ├── use_cases/       # Use Cases
│   └── dto/             # Data Transfer Objects
├── infrastructure/      # Инфраструктурный слой
│   ├── config/          # Конфигурация
│   ├── repositories/    # Реализация репозиториев
│   └── external/        # Внешние сервисы
└── presentation/        # Слой представления
    ├── screens/         # Экраны
    ├── widgets/         # Виджеты
    └── providers/       # Riverpod провайдеры
```

## Основные функции

- ✅ Просмотр списка сказок
- ✅ Генерация новых сказок
- ✅ Управление детьми (добавление, удаление)
- ✅ Оценка сказок
- ✅ Просмотр деталей сказки

## Следующие шаги

1. Добавить экран аутентификации
2. Добавить экран профиля пользователя
3. Добавить управление героями
4. Добавить воспроизведение аудио
5. Добавить управление подписками

