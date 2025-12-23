import '../../domain/repositories/story_repository.dart';

class RateStoryUseCase {
  final StoryRepository _repository;

  RateStoryUseCase(this._repository);

  Future<void> execute(String storyId, int rating) async {
    if (rating < 1 || rating > 10) {
      throw Exception('Rating must be between 1 and 10');
    }
    return await _repository.rateStory(storyId, rating);
  }
}

