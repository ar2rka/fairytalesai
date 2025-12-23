import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/story.dart';
import '../../application/use_cases/get_stories_use_case.dart';
import 'use_cases_provider.dart';
import 'repositories_provider.dart';

final storiesProvider = FutureProvider<List<Story>>((ref) async {
  final useCase = ref.watch(getStoriesUseCaseProvider);
  return await useCase.execute();
});

final storyProvider =
    FutureProvider.family<Story?, String>((ref, storyId) async {
  final repository = ref.watch(storyRepositoryProvider);
  return await repository.getStoryById(storyId);
});

class PaginatedStoriesState {
  final List<Story> stories;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final Object? error;

  PaginatedStoriesState({
    required this.stories,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedStoriesState copyWith({
    List<Story>? stories,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    Object? error,
  }) {
    return PaginatedStoriesState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

class PaginatedStoriesNotifier extends StateNotifier<PaginatedStoriesState> {
  final GetStoriesUseCase _useCase;
  static const int _pageSize = 10;

  PaginatedStoriesNotifier(this._useCase)
      : super(PaginatedStoriesState(stories: [])) {
    loadInitialStories();
  }

  Future<void> loadInitialStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stories = await _useCase.executePaginated(
        limit: _pageSize,
        offset: 0,
      );
      state = state.copyWith(
        stories: stories,
        isLoading: false,
        hasMore: stories.length == _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> loadMoreStories() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final nextPage = state.currentPage + 1;
      final stories = await _useCase.executePaginated(
        limit: _pageSize,
        offset: nextPage * _pageSize,
      );

      if (stories.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          stories: [...state.stories, ...stories],
          isLoadingMore: false,
          hasMore: stories.length == _pageSize,
          currentPage: nextPage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e,
      );
    }
  }

  Future<void> refresh() async {
    await loadInitialStories();
  }
}

final paginatedStoriesProvider =
    StateNotifierProvider<PaginatedStoriesNotifier, PaginatedStoriesState>(
  (ref) {
    final useCase = ref.watch(getStoriesUseCaseProvider);
    return PaginatedStoriesNotifier(useCase);
  },
);
