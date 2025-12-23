# Диагностика проблемы 404 с generations

## Шаги для диагностики

### 1. Проверьте тестовый эндпоинт

Откройте в браузере или через curl:
```
http://localhost:8000/api/v1/admin/generations/test
```

Этот эндпоинт покажет:
- Работает ли доступ к таблице
- Какая ошибка возникает (если есть)
- Пример данных (если доступ есть)

### 2. Проверьте основной эндпоинт

```
http://localhost:8000/api/v1/admin/generations
```

### 3. Проверьте логи бекенда

Запустите бекенд и посмотрите логи. Должны быть сообщения:
- "Fetching generations with filters..."
- "Retrieved X generations from database"
- Или сообщения об ошибках

### 4. Проверьте миграцию

Убедитесь, что миграция `022_add_service_role_access_to_generations.sql` применена:
- Откройте Supabase Dashboard → SQL Editor
- Выполните: `SELECT * FROM pg_policies WHERE tablename = 'generations';`
- Должны быть видны политики для service_role

### 5. Проверьте ключ Supabase

Убедитесь, что используется **service_role** ключ (не anon key):
- В `.env` файле должна быть переменная `SUPABASE_KEY` с service_role ключом
- Service_role ключ можно найти в Supabase Dashboard → Settings → API → service_role key

### 6. Проверьте напрямую в Supabase

Выполните SQL запрос в Supabase Dashboard:
```sql
SELECT COUNT(*) FROM tales.generations;
```

Если запрос возвращает 0, значит данных нет в таблице.
Если запрос возвращает ошибку доступа, значит проблема с RLS.

### 7. Проверьте схему таблицы

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'tales' AND table_name = 'generations';
```

## Возможные причины 404

1. **RLS блокирует доступ** - нужно применить миграцию или использовать service_role ключ
2. **Таблица пустая** - нет данных в таблице generations
3. **Неправильное имя таблицы** - проверьте, что таблица называется `generations` в схеме `tales`
4. **Ошибка в запросе** - проверьте логи бекенда на наличие исключений

## Решение

После проверки тестового эндпоинта `/admin/generations/test` вы увидите точную причину проблемы.








