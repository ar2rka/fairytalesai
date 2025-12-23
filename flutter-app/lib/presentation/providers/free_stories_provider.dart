import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/free_story.dart';
import 'use_cases_provider.dart';

final freeStoriesProvider = FutureProvider.family<List<FreeStory>, FreeStoriesParams>(
  (ref, params) async {
    final useCase = ref.watch(getFreeStoriesUseCaseProvider);
    return await useCase.execute(
      ageCategory: params.ageCategory,
      language: params.language,
    );
  },
);

class FreeStoriesParams {
  final String? ageCategory;
  final String? language;

  FreeStoriesParams({
    this.ageCategory,
    this.language,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreeStoriesParams &&
          runtimeType == other.runtimeType &&
          ageCategory == other.ageCategory &&
          language == other.language;

  @override
  int get hashCode => ageCategory.hashCode ^ language.hashCode;
}

