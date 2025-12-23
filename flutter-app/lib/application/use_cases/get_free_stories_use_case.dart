import '../../domain/entities/free_story.dart';
import '../../domain/repositories/free_story_repository.dart';

class GetFreeStoriesUseCase {
  final FreeStoryRepository _repository;

  GetFreeStoriesUseCase(this._repository);

  Future<List<FreeStory>> execute({
    String? ageCategory,
    String? language,
  }) async {
    return await _repository.getFreeStories(
      ageCategory: ageCategory,
      language: language,
    );
  }
}

