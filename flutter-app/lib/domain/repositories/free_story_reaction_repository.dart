import '../entities/free_story_reaction.dart';

abstract class FreeStoryReactionRepository {
  /// Добавить или обновить реакцию пользователя на бесплатную историю
  Future<FreeStoryReaction> setReaction({
    required String freeStoryId,
    required ReactionType reactionType,
  });

  /// Удалить реакцию пользователя
  Future<void> removeReaction(String freeStoryId);

  /// Получить реакцию текущего пользователя на историю
  Future<FreeStoryReaction?> getUserReaction(String freeStoryId);

  /// Получить статистику реакций для истории
  Future<FreeStoryReactionStats> getReactionStats(String freeStoryId);
}

