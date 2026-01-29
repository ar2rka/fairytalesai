# Test: Anonymous User Creation

Этот тест проверяет, что при подключении анонимного пользователя автоматически создается профиль с пустым именем и FREE подпиской.

## Требования

Для запуска теста нужны следующие переменные окружения:

### Обязательные:
- `SUPABASE_URL` - URL вашего Supabase проекта
- `SUPABASE_KEY` - Service role key (для админских операций)

### Рекомендуемые (для полного теста):
- `SUPABASE_ANON_KEY` - Anonymous key (для создания реального анонимного пользователя)

## Где взять ключи?

1. **SUPABASE_URL** и **SUPABASE_KEY**: 
   - Supabase Dashboard → Settings → API
   - `SUPABASE_URL` = Project URL
   - `SUPABASE_KEY` = `service_role` key (секретный ключ)

2. **SUPABASE_ANON_KEY**:
   - Supabase Dashboard → Settings → API
   - `SUPABASE_ANON_KEY` = `anon` key (публичный ключ)


## Запуск теста

```bash
# Убедитесь, что переменные окружения установлены в .env файле
uv run python test_anonymous_user.py
```

## Что проверяет тест?

1. ✅ Создание анонимного пользователя (через `auth.sign_in_anonymously()`)
2. ✅ Проверка, что пользователь помечен как `is_anonymous=true` в `auth.users`
3. ✅ Автоматическое создание профиля при вызове `get_user_subscription()`
4. ✅ Профиль создается с:
   - Пустым именем (`name = ''`)
   - Тарифом FREE (`subscription_plan = 'free'`)
   - Статусом ACTIVE (`subscription_status = 'active'`)
   - Начальными значениями счетчиков

## Ожидаемый результат

```
✅ ALL TESTS PASSED!

Summary:
  ✓ Anonymous user created successfully
  ✓ User marked as anonymous in auth.users
  ✓ Profile created automatically with empty name
  ✓ FREE subscription assigned automatically
  ✓ All subscription fields initialized correctly
```

## Troubleshooting

### "Subscription not found after get_user_subscription call"

Это означает, что пользователь не существует в `auth.users` или не помечен как анонимный.

**Решение:**
1. Установите `SUPABASE_ANON_KEY` и перезапустите тест
2. Или создайте анонимного пользователя вручную через Supabase Dashboard

### "Could not find the table 'tales.auth.users'"

Это нормально - таблица `auth.users` не доступна через PostgREST API в схеме `tales`. Тест продолжит работу и проверит логику создания профиля.

