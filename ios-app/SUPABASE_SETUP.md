# Настройка Supabase для аутентификации

Этот документ описывает, как настроить Supabase для работы с аутентификацией в приложении.

## Шаг 1: Создание проекта Supabase

1. Зарегистрируйтесь на [supabase.com](https://supabase.com/)
2. Создайте новый проект
3. Дождитесь завершения инициализации проекта

## Шаг 2: Получение API ключей

1. В Dashboard Supabase перейдите в **Project Settings** → **API**
2. Скопируйте следующие значения:
   - **Project URL** (например: `https://xxxxx.supabase.co`)
   - **anon/public key** (длинная строка, начинающаяся с `eyJ...`)

## Шаг 3: Настройка файла конфигурации

Откройте файл `FairyTalesAI/Services/SupabaseConfig.swift` и замените значения:

```swift
static let supabaseURL = "YOUR_SUPABASE_URL"  // Вставьте Project URL
static let supabaseKey = "YOUR_SUPABASE_ANON_KEY"  // Вставьте anon key
```

Например:
```swift
static let supabaseURL = "https://xxxxx.supabase.co"
static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Шаг 4: Добавление Supabase SDK через Swift Package Manager

1. Откройте проект в Xcode
2. Перейдите в **File** → **Add Package Dependencies...**
3. Вставьте URL репозитория:
   ```
   https://github.com/supabase/supabase-swift
   ```
4. Выберите версию (рекомендуется последняя стабильная версия)
5. Добавьте пакет `Supabase` к таргету `FairyTalesAI`

## Шаг 5: Настройка Authentication в Supabase

1. В Dashboard Supabase перейдите в **Authentication** → **Settings**
2. Убедитесь, что включена аутентификация через Email
3. (Опционально) Настройте дополнительные провайдеры (Google, Apple и т.д.)
4. В разделе **Site URL** укажите URL вашего приложения или используйте значение по умолчанию

## Шаг 6: Проверка работы

После настройки:

1. Запустите приложение
2. Вы должны увидеть экран входа (`LoginView`)
3. Попробуйте зарегистрироваться с новым email и паролем
4. После успешной регистрации/входа вы попадете в основное приложение

## Возможные проблемы

### Ошибка "Supabase не настроен"
- Убедитесь, что вы заполнили `SupabaseConfig.swift` правильными значениями
- Проверьте, что URL и ключ скопированы полностью без лишних пробелов

### Ошибка "No such module 'Supabase'"
- Убедитесь, что вы добавили пакет через Swift Package Manager
- Очистите проект: **Product** → **Clean Build Folder** (`Cmd+Shift+K`)
- Пересоберите проект: **Product** → **Build** (`Cmd+B`)

### Ошибки аутентификации
- Проверьте, что в Supabase Dashboard включена аутентификация через Email
- Убедитесь, что email имеет правильный формат
- Пароль должен быть минимум 6 символов

## Дополнительная информация

- [Документация Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)

