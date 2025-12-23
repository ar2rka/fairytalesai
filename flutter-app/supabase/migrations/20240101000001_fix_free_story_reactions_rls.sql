-- Исправление политик RLS и функции для free_story_reactions
-- Выполните этот скрипт, если возникли проблемы с доступом к таблице

-- Удаляем конфликтующие политики (если они были созданы)
DROP POLICY IF EXISTS "Allow authenticated upsert access" ON tales.free_story_reactions;

-- Убеждаемся, что политики правильно настроены
-- Политика SELECT уже должна быть правильной, но проверим
DROP POLICY IF EXISTS "Allow authenticated read access" ON tales.free_story_reactions;
CREATE POLICY "Allow authenticated read access"
    ON tales.free_story_reactions
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Политика INSERT
DROP POLICY IF EXISTS "Allow authenticated insert access" ON tales.free_story_reactions;
CREATE POLICY "Allow authenticated insert access"
    ON tales.free_story_reactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Политика UPDATE
DROP POLICY IF EXISTS "Allow authenticated update access" ON tales.free_story_reactions;
CREATE POLICY "Allow authenticated update access"
    ON tales.free_story_reactions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Политика DELETE
DROP POLICY IF EXISTS "Allow authenticated delete access" ON tales.free_story_reactions;
CREATE POLICY "Allow authenticated delete access"
    ON tales.free_story_reactions
    FOR DELETE
    USING (auth.uid() = user_id);

-- Функция RPC больше не используется в коде приложения
-- Статистика получается напрямую через запросы к таблице
-- Оставляем функцию на случай, если понадобится в будущем
-- Если функция вызывает проблемы, можно её удалить:
-- DROP FUNCTION IF EXISTS tales.get_free_story_reaction_stats(UUID);

