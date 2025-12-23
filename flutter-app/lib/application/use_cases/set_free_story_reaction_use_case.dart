import '../../domain/entities/free_story_reaction.dart';
import '../../domain/repositories/free_story_reaction_repository.dart';

class SetFreeStoryReactionUseCase {
  final FreeStoryReactionRepository _repository;

  SetFreeStoryReactionUseCase(this._repository);

  Future<FreeStoryReaction> execute({
    required String freeStoryId,
    required ReactionType reactionType,
  }) async {
    return await _repository.setReaction(
      freeStoryId: freeStoryId,
      reactionType: reactionType,
    );
  }
}

