import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';
import '../storage/local_story_storage.dart';
import '../services/connectivity_service.dart';

class StoryRepositoryImpl implements StoryRepository {
  final SupabaseClient _supabase;
  final LocalStoryStorage _localStorage;
  final ConnectivityService _connectivityService;

  StoryRepositoryImpl(
    this._supabase,
    this._localStorage,
    this._connectivityService,
  );

  @override
  Future<List<Story>> getStories() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (hasInternet) {
      try {
        final response = await _supabase
            .from('stories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final stories = (response as List)
            .map((json) => Story.fromJson(json as Map<String, dynamic>))
            .toList();

        // Сохраняем в локальное хранилище для офлайн доступа
        await _localStorage.saveStories(userId, stories);

        return stories;
      } catch (e) {
        // При ошибке сети пытаемся загрузить из локального хранилища
        return await _localStorage.getStories(userId);
      }
    } else {
      // Нет интернета - загружаем из локального хранилища
      return await _localStorage.getStories(userId);
    }
  }

  @override
  Future<List<Story>> getStoriesPaginated(
      {required int limit, required int offset}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (hasInternet) {
      try {
        final response = await _supabase
            .from('stories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        final stories = (response as List)
            .map((json) => Story.fromJson(json as Map<String, dynamic>))
            .toList();

        // Сохраняем все истории в локальное хранилище
        // Для пагинации загружаем все истории и сохраняем их
        final allStories = await getStories();
        await _localStorage.saveStories(userId, allStories);

        return stories;
      } catch (e) {
        // При ошибке сети загружаем из локального хранилища и применяем пагинацию
        final allStories = await _localStorage.getStories(userId);
        final end = (offset + limit < allStories.length)
            ? offset + limit
            : allStories.length;
        return allStories.sublist(
          offset < allStories.length ? offset : allStories.length,
          end,
        );
      }
    } else {
      // Нет интернета - загружаем из локального хранилища с пагинацией
      final allStories = await _localStorage.getStories(userId);
      final end = (offset + limit < allStories.length)
          ? offset + limit
          : allStories.length;
      return allStories.sublist(
        offset < allStories.length ? offset : allStories.length,
        end,
      );
    }
  }

  @override
  Future<Story?> getStoryById(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (hasInternet) {
      try {
        final response = await _supabase
            .from('stories')
            .select()
            .eq('id', id)
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) {
          // Если не найдено в сети, проверяем локальное хранилище
          return await _localStorage.getStoryById(userId, id);
        }

        final story = Story.fromJson(response);
        // Сохраняем в локальное хранилище
        await _localStorage.saveStory(userId, story);

        return story;
      } catch (e) {
        // При ошибке сети загружаем из локального хранилища
        return await _localStorage.getStoryById(userId, id);
      }
    } else {
      // Нет интернета - загружаем из локального хранилища
      return await _localStorage.getStoryById(userId, id);
    }
  }

  @override
  Future<Story> createStory(Story story) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (!hasInternet) {
      throw Exception('No internet connection. Cannot create story.');
    }

    final storyData = story.toJson();
    storyData['user_id'] = userId;

    final response =
        await _supabase.from('stories').insert(storyData).select().single();

    final createdStory = Story.fromJson(response);
    // Сохраняем в локальное хранилище
    await _localStorage.saveStory(userId, createdStory);

    return createdStory;
  }

  @override
  Future<Story> updateStory(Story story) async {
    if (story.id == null) {
      throw Exception('Story ID is required for update');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (!hasInternet) {
      throw Exception('No internet connection. Cannot update story.');
    }

    final response = await _supabase
        .from('stories')
        .update(story.toJson())
        .eq('id', story.id!)
        .eq('user_id', userId)
        .select()
        .single();

    final updatedStory = Story.fromJson(response);
    // Обновляем в локальном хранилище
    await _localStorage.saveStory(userId, updatedStory);

    return updatedStory;
  }

  @override
  Future<void> deleteStory(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (hasInternet) {
      try {
        await _supabase
            .from('stories')
            .delete()
            .eq('id', id)
            .eq('user_id', userId);

        // Удаляем из локального хранилища
        await _localStorage.deleteStory(userId, id);
      } catch (e) {
        // При ошибке сети все равно удаляем из локального хранилища
        await _localStorage.deleteStory(userId, id);
        rethrow;
      }
    } else {
      // Нет интернета - удаляем только из локального хранилища
      await _localStorage.deleteStory(userId, id);
      throw Exception('No internet connection. Story deleted locally only.');
    }
  }

  @override
  Future<void> rateStory(String storyId, int rating) async {
    if (rating < 1 || rating > 10) {
      throw Exception('Rating must be between 1 and 10');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final hasInternet = await _connectivityService.hasInternetConnection();

    if (hasInternet) {
      try {
        await _supabase
            .from('stories')
            .update({'rating': rating})
            .eq('id', storyId)
            .eq('user_id', userId);

        // Обновляем рейтинг в локальном хранилище
        final story = await _localStorage.getStoryById(userId, storyId);
        if (story != null) {
          final updatedStory = Story(
            id: story.id,
            title: story.title,
            content: story.content,
            summary: story.summary,
            language: story.language,
            childId: story.childId,
            childName: story.childName,
            childAge: story.childAge,
            childGender: story.childGender,
            childInterests: story.childInterests,
            heroId: story.heroId,
            heroName: story.heroName,
            heroGender: story.heroGender,
            heroAppearance: story.heroAppearance,
            relationshipDescription: story.relationshipDescription,
            rating: rating,
            audioFileUrl: story.audioFileUrl,
            audioProvider: story.audioProvider,
            audioGenerationMetadata: story.audioGenerationMetadata,
            status: story.status,
            userId: story.userId,
            generationId: story.generationId,
            createdAt: story.createdAt,
            updatedAt: story.updatedAt,
          );
          await _localStorage.saveStory(userId, updatedStory);
        }
      } catch (e) {
        // При ошибке сети сохраняем рейтинг локально
        final story = await _localStorage.getStoryById(userId, storyId);
        if (story != null) {
          final updatedStory = Story(
            id: story.id,
            title: story.title,
            content: story.content,
            summary: story.summary,
            language: story.language,
            childId: story.childId,
            childName: story.childName,
            childAge: story.childAge,
            childGender: story.childGender,
            childInterests: story.childInterests,
            heroId: story.heroId,
            heroName: story.heroName,
            heroGender: story.heroGender,
            heroAppearance: story.heroAppearance,
            relationshipDescription: story.relationshipDescription,
            rating: rating,
            audioFileUrl: story.audioFileUrl,
            audioProvider: story.audioProvider,
            audioGenerationMetadata: story.audioGenerationMetadata,
            status: story.status,
            userId: story.userId,
            generationId: story.generationId,
            createdAt: story.createdAt,
            updatedAt: story.updatedAt,
          );
          await _localStorage.saveStory(userId, updatedStory);
        }
        // Пробрасываем ошибку дальше
        rethrow;
      }
    } else {
      // Нет интернета - сохраняем рейтинг локально
      final story = await _localStorage.getStoryById(userId, storyId);
      if (story == null) {
        throw Exception('Story not found in local storage');
      }
      final updatedStory = Story(
        id: story.id,
        title: story.title,
        content: story.content,
        summary: story.summary,
        language: story.language,
        childId: story.childId,
        childName: story.childName,
        childAge: story.childAge,
        childGender: story.childGender,
        childInterests: story.childInterests,
        heroId: story.heroId,
        heroName: story.heroName,
        heroGender: story.heroGender,
        heroAppearance: story.heroAppearance,
        relationshipDescription: story.relationshipDescription,
        rating: rating,
        audioFileUrl: story.audioFileUrl,
        audioProvider: story.audioProvider,
        audioGenerationMetadata: story.audioGenerationMetadata,
        status: story.status,
        userId: story.userId,
        generationId: story.generationId,
        createdAt: story.createdAt,
        updatedAt: story.updatedAt,
      );
      await _localStorage.saveStory(userId, updatedStory);
    }
  }
}
