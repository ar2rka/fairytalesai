# Настройка доступа к бесплатным историям (free_stories)

## Проблема

Если вы видите ошибку `permission denied for table free_stories`, это означает, что на таблице включен Row Level Security (RLS), но нет политики для публичного доступа.

## Решение

Необходимо создать политику RLS в Supabase, которая разрешает публичный доступ на чтение для таблицы `free_stories`.

### Вариант 1: Через SQL Editor в Supabase Dashboard

1. Откройте Supabase Dashboard
2. Перейдите в SQL Editor
3. Выполните следующий SQL:

```sql
-- Создать политику для чтения таблицы free_stories только для аутентифицированных пользователей
CREATE POLICY "Allow authenticated read access" 
ON tales.free_stories
FOR SELECT
USING (auth.uid() IS NOT NULL);
```

**Примечание:** Эта политика разрешает доступ только залогиненным пользователям. Если вы хотите сделать таблицу полностью публичной (доступной даже неаутентифицированным пользователям), используйте `USING (true)` вместо `USING (auth.uid() IS NOT NULL)`.

### Вариант 2: Через Supabase CLI

Если вы используете Supabase CLI, добавьте миграцию:

```sql
-- migrations/XXXXXX_add_free_stories_authenticated_policy.sql
CREATE POLICY "Allow authenticated read access" 
ON tales.free_stories
FOR SELECT
USING (auth.uid() IS NOT NULL);
```

### Вариант 3: Отключить RLS (не рекомендуется)

Если вы хотите полностью отключить RLS для этой таблицы (менее безопасно):

```sql
ALTER TABLE tales.free_stories DISABLE ROW LEVEL SECURITY;
```

**Примечание:** Отключение RLS не рекомендуется, лучше использовать политику.

## Проверка

После создания политики, попробуйте снова открыть экран бесплатных историй в приложении. Ошибка должна исчезнуть.

## Дополнительная информация

Таблица `free_stories` настроена для доступа только аутентифицированным пользователям. Политика `USING (auth.uid() IS NOT NULL)` проверяет, что пользователь залогинен (имеет непустой UUID).

### Альтернатива: Полностью публичный доступ

Если вы хотите сделать таблицу доступной даже для неаутентифицированных пользователей, используйте:

```sql
CREATE POLICY "Allow public read access" 
ON tales.free_stories
FOR SELECT
USING (true);
```

