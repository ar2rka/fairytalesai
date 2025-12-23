import '../entities/story.dart';

abstract class StoryRepository {
  Future<List<Story>> getStories();
  Future<List<Story>> getStoriesPaginated(
      {required int limit, required int offset});
  Future<Story?> getStoryById(String id);
  Future<Story> createStory(Story story);
  Future<Story> updateStory(Story story);
  Future<void> deleteStory(String id);
  Future<void> rateStory(String storyId, int rating);
}
