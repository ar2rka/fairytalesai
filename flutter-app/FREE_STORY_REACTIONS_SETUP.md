# Настройка системы оценок бесплатных историй

## Описание

Реализована система оценки бесплатных историй пользователями. Каждый пользователь может поставить либо лайк, либо дизлайк на бесплатную историю.

## Миграция базы данных

### Применение миграции через Supabase Dashboard

1. Откройте Supabase Dashboard
2. Перейдите в SQL Editor
3. Откройте файл `supabase/migrations/20240101000000_create_free_story_reactions.sql`
4. Скопируйте содержимое и выполните SQL запрос
5. **ВАЖНО**: Если возникли проблемы с доступом к таблице, выполните также исправляющий скрипт:
   - Откройте файл `supabase/migrations/20240101000001_fix_free_story_reactions_rls.sql`
   - Скопируйте содержимое и выполните SQL запрос

### Применение миграции через Supabase CLI

Если вы используете Supabase CLI:

```bash
supabase db push
```

### Решение проблем с доступом

Если при попытке поставить лайк/дизлайк возникает ошибка доступа к таблице:

1. Убедитесь, что вы выполнили обе миграции (основную и исправляющую)
2. Проверьте, что таблица `tales.free_story_reactions` существует в Supabase Dashboard
3. Проверьте, что политики RLS созданы (Table Editor → free_story_reactions → Policies)
4. Убедитесь, что функция `tales.get_free_story_reaction_stats` создана и использует `SECURITY INVOKER`
5. Проверьте, что пользователь аутентифицирован (`auth.uid()` не NULL)

## Структура таблицы

Таблица `tales.free_story_reactions` содержит следующие поля:

- `id` (UUID) - первичный ключ
- `free_story_id` (UUID) - ссылка на бесплатную историю
- `user_id` (UUID) - ссылка на пользователя
- `reaction_type` (TEXT) - тип реакции: 'like' или 'dislike'
- `created_at` (TIMESTAMPTZ) - дата создания
- `updated_at` (TIMESTAMPTZ) - дата обновления

**Ограничения:**
- UNIQUE constraint на `(free_story_id, user_id)` - один пользователь может поставить только одну реакцию на историю
- CHECK constraint на `reaction_type` - только 'like' или 'dislike'

## Row Level Security (RLS)

Таблица защищена политиками RLS:

- **SELECT**: Аутентифицированные пользователи могут видеть все реакции
- **INSERT**: Пользователи могут создавать только свои реакции
- **UPDATE**: Пользователи могут обновлять только свои реакции
- **DELETE**: Пользователи могут удалять только свои реакции

## Получение статистики

Статистика реакций получается напрямую через запросы к таблице `free_story_reactions`. Это обеспечивает правильную работу с RLS политиками и не требует дополнительных функций.

Приложение получает:
- `likesCount` - количество лайков
- `dislikesCount` - количество дизлайков  
- `userReaction` - реакция текущего пользователя (NULL, если пользователь не оценил историю)

**Примечание:** В миграции также создана функция `get_free_story_reaction_stats`, но она не используется в текущей реализации приложения и может быть удалена, если вызывает проблемы.

## Использование в приложении

### Добавление реакции

```dart
final useCase = ref.read(setFreeStoryReactionUseCaseProvider);
await useCase.execute(
  freeStoryId: storyId,
  reactionType: ReactionType.like, // или ReactionType.dislike
);
```

### Удаление реакции

```dart
final useCase = ref.read(removeFreeStoryReactionUseCaseProvider);
await useCase.execute(storyId);
```

### Получение статистики

```dart
final useCase = ref.read(getFreeStoryReactionStatsUseCaseProvider);
final stats = await useCase.execute(storyId);
// stats.likesCount - количество лайков
// stats.dislikesCount - количество дизлайков
// stats.userReactionEnum - реакция текущего пользователя (может быть null)
```

## UI

Экран деталей бесплатной истории (`FreeStoryDetailScreen`) теперь включает:

- Кнопки для лайка и дизлайка
- Отображение количества лайков и дизлайков
- Визуальное выделение выбранной реакции
- Возможность отменить реакцию (повторное нажатие на ту же кнопку)

## Проверка работы

После применения миграции:

1. Убедитесь, что таблица создана в Supabase Dashboard
2. Проверьте, что политики RLS созданы
3. Проверьте, что функция `get_free_story_reaction_stats` создана
4. Откройте приложение и перейдите к любой бесплатной истории
5. Попробуйте поставить лайк или дизлайк
6. Проверьте, что счетчики обновляются корректно

