# Применение миграции для проверки анонимных пользователей

## Важно!

Для работы автоматического создания профилей для анонимных пользователей нужно применить миграцию.

## Быстрое применение

1. Откройте **Supabase Dashboard** → **SQL Editor**
2. Скопируйте и выполните SQL из файла `supabase/migrations/026_add_check_anonymous_user_function.sql`

Или выполните этот SQL напрямую:

```sql
-- Create function to check if user is anonymous
CREATE OR REPLACE FUNCTION check_user_is_anonymous(user_uuid UUID)
RETURNS TABLE(is_anonymous BOOLEAN) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT u.is_anonymous
    FROM auth.users u
    WHERE u.id = user_uuid;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_user_is_anonymous(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION check_user_is_anonymous(UUID) TO authenticated;
```

## После применения

Запустите тест снова:
```bash
uv run python test_anonymous_user.py
```

Тест должен пройти успешно! ✅
