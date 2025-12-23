import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';

class GetStoriesUseCase {
  final StoryRepository _repository;

  GetStoriesUseCase(this._repository);

  Future<List<Story>> execute() async {
    return await _repository.getStories();
  }

  Future<List<Story>> executePaginated(
      {required int limit, required int offset}) async {
    return await _repository.getStoriesPaginated(limit: limit, offset: offset);
  }
}
