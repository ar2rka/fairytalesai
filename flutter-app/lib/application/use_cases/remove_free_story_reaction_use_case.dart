import '../../domain/repositories/free_story_reaction_repository.dart';

class RemoveFreeStoryReactionUseCase {
  final FreeStoryReactionRepository _repository;

  RemoveFreeStoryReactionUseCase(this._repository);

  Future<void> execute(String freeStoryId) async {
    return await _repository.removeReaction(freeStoryId);
  }
}

