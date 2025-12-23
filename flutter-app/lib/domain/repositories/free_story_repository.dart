import '../entities/free_story.dart';

abstract class FreeStoryRepository {
  /// Получить все активные бесплатные истории
  Future<List<FreeStory>> getFreeStories({
    String? ageCategory,
    String? language,
  });

  /// Получить бесплатную историю по ID
  Future<FreeStory?> getFreeStoryById(String id);
}

