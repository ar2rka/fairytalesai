import '../../domain/entities/free_story_reaction.dart';
import '../../domain/repositories/free_story_reaction_repository.dart';

class GetFreeStoryReactionStatsUseCase {
  final FreeStoryReactionRepository _repository;

  GetFreeStoryReactionStatsUseCase(this._repository);

  Future<FreeStoryReactionStats> execute(String freeStoryId) async {
    return await _repository.getReactionStats(freeStoryId);
  }
}

