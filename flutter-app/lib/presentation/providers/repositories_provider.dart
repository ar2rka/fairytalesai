import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../infrastructure/repositories/user_repository_impl.dart';
import '../../infrastructure/repositories/child_repository_impl.dart';
import '../../infrastructure/repositories/hero_repository_impl.dart';
import '../../infrastructure/repositories/story_repository_impl.dart';
import '../../infrastructure/repositories/generation_repository_impl.dart';
import '../../infrastructure/repositories/free_story_repository_impl.dart';
import '../../infrastructure/repositories/free_story_reaction_repository_impl.dart';
import '../../infrastructure/external/api_client.dart';
import '../../infrastructure/storage/local_story_storage.dart';
import '../../infrastructure/services/connectivity_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: 'http://127.0.0.1:8000/api/v1', // TODO: Замените на ваш API URL
    supabase: ref.watch(supabaseProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final localStoryStorageProvider = Provider<LocalStoryStorage>((ref) {
  return LocalStoryStorage();
});

final userRepositoryProvider = Provider((ref) {
  return UserRepositoryImpl(ref.watch(supabaseProvider));
});

final childRepositoryProvider = Provider((ref) {
  return ChildRepositoryImpl(ref.watch(supabaseProvider));
});

final heroRepositoryProvider = Provider((ref) {
  return HeroRepositoryImpl(ref.watch(supabaseProvider));
});

final storyRepositoryProvider = Provider((ref) {
  return StoryRepositoryImpl(
    ref.watch(supabaseProvider),
    ref.watch(localStoryStorageProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final generationRepositoryProvider = Provider((ref) {
  return GenerationRepositoryImpl(ref.watch(supabaseProvider));
});

final freeStoryRepositoryProvider = Provider((ref) {
  return FreeStoryRepositoryImpl(ref.watch(supabaseProvider));
});

final freeStoryReactionRepositoryProvider = Provider((ref) {
  return FreeStoryReactionRepositoryImpl(ref.watch(supabaseProvider));
});
