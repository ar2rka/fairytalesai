import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/use_cases/generate_story_use_case.dart';
import '../../application/use_cases/get_children_use_case.dart';
import '../../application/use_cases/create_child_use_case.dart';
import '../../application/use_cases/get_stories_use_case.dart';
import '../../application/use_cases/rate_story_use_case.dart';
import '../../application/use_cases/get_user_profile_use_case.dart';
import '../../application/use_cases/create_user_profile_use_case.dart';
import '../../application/use_cases/get_free_stories_use_case.dart';
import '../../application/use_cases/set_free_story_reaction_use_case.dart';
import '../../application/use_cases/remove_free_story_reaction_use_case.dart';
import '../../application/use_cases/get_free_story_reaction_stats_use_case.dart';
import 'repositories_provider.dart';

final generateStoryUseCaseProvider = Provider((ref) {
  return GenerateStoryUseCase(ref.watch(apiClientProvider));
});

final getChildrenUseCaseProvider = Provider((ref) {
  return GetChildrenUseCase(ref.watch(childRepositoryProvider));
});

final createChildUseCaseProvider = Provider((ref) {
  return CreateChildUseCase(ref.watch(childRepositoryProvider));
});

final getStoriesUseCaseProvider = Provider((ref) {
  return GetStoriesUseCase(ref.watch(storyRepositoryProvider));
});

final rateStoryUseCaseProvider = Provider((ref) {
  return RateStoryUseCase(ref.watch(storyRepositoryProvider));
});

final getUserProfileUseCaseProvider = Provider((ref) {
  return GetUserProfileUseCase(ref.watch(userRepositoryProvider));
});

final createUserProfileUseCaseProvider = Provider((ref) {
  return CreateUserProfileUseCase(ref.watch(userRepositoryProvider));
});

final getFreeStoriesUseCaseProvider = Provider((ref) {
  return GetFreeStoriesUseCase(ref.watch(freeStoryRepositoryProvider));
});

final setFreeStoryReactionUseCaseProvider = Provider((ref) {
  return SetFreeStoryReactionUseCase(
      ref.watch(freeStoryReactionRepositoryProvider));
});

final removeFreeStoryReactionUseCaseProvider = Provider((ref) {
  return RemoveFreeStoryReactionUseCase(
      ref.watch(freeStoryReactionRepositoryProvider));
});

final getFreeStoryReactionStatsUseCaseProvider = Provider((ref) {
  return GetFreeStoryReactionStatsUseCase(
      ref.watch(freeStoryReactionRepositoryProvider));
});
