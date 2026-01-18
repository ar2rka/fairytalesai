-- Создание таблицы для оценок бесплатных историй (лайки/дизлайки)
CREATE TABLE IF NOT EXISTS tales.free_story_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    free_story_id UUID NOT NULL REFERENCES tales.free_stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(free_story_id, user_id)
);

-- Создание индексов для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_free_story_reactions_story_id ON tales.free_story_reactions(free_story_id);
CREATE INDEX IF NOT EXISTS idx_free_story_reactions_user_id ON tales.free_story_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_free_story_reactions_type ON tales.free_story_reactions(reaction_type);

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_free_story_reactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического обновления updated_at
CREATE TRIGGER trigger_update_free_story_reactions_updated_at
    BEFORE UPDATE ON tales.free_story_reactions
    FOR EACH ROW
    EXECUTE FUNCTION update_free_story_reactions_updated_at();

-- Включение Row Level Security
ALTER TABLE tales.free_story_reactions ENABLE ROW LEVEL SECURITY;

-- Политика: пользователи могут видеть все реакции
CREATE POLICY "Allow authenticated read access"
    ON tales.free_story_reactions
    FOR SELECT
    USING (auth.uid() IS NOT NULL);

-- Политика: пользователи могут создавать свои реакции
CREATE POLICY "Allow authenticated insert access"
    ON tales.free_story_reactions
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Политика: пользователи могут обновлять только свои реакции
CREATE POLICY "Allow authenticated update access"
    ON tales.free_story_reactions
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Политика: пользователи могут удалять только свои реакции
CREATE POLICY "Allow authenticated delete access"
    ON tales.free_story_reactions
    FOR DELETE
    USING (auth.uid() = user_id);

-- Функция для получения статистики реакций по истории
-- Используем SECURITY INVOKER, чтобы функция выполнялась с правами вызывающего пользователя
-- Это необходимо для правильной работы с RLS политиками
CREATE OR REPLACE FUNCTION tales.get_free_story_reaction_stats(story_id UUID)
RETURNS TABLE (
    likes_count BIGINT,
    dislikes_count BIGINT,
    user_reaction TEXT
) AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Получаем текущего пользователя
    current_user_id := auth.uid();
    
    RETURN QUERY
    SELECT 
        COALESCE(
            (SELECT COUNT(*)::BIGINT 
             FROM tales.free_story_reactions 
             WHERE free_story_id = story_id AND reaction_type = 'like'),
            0::BIGINT
        ) as likes_count,
        COALESCE(
            (SELECT COUNT(*)::BIGINT 
             FROM tales.free_story_reactions 
             WHERE free_story_id = story_id AND reaction_type = 'dislike'),
            0::BIGINT
        ) as dislikes_count,
        COALESCE(
            (SELECT reaction_type 
             FROM tales.free_story_reactions 
             WHERE free_story_id = story_id AND user_id = current_user_id 
             LIMIT 1),
            NULL
        )::TEXT as user_reaction;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

