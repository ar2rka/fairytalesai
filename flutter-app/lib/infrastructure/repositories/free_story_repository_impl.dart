import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/free_story.dart';
import '../../domain/repositories/free_story_repository.dart';

class FreeStoryRepositoryImpl implements FreeStoryRepository {
  final SupabaseClient _supabase;

  FreeStoryRepositoryImpl(this._supabase);

  @override
  Future<List<FreeStory>> getFreeStories({
    String? ageCategory,
    String? language,
  }) async {
    try {
      var query = _supabase.from('free_stories').select().eq('is_active', true);

      if (ageCategory != null) {
        query = query.eq('age_category', ageCategory);
      }

      if (language != null) {
        query = query.eq('language', language);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => FreeStory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Если ошибка доступа, даем более информативное сообщение
      if (e.toString().contains('permission denied') ||
          e.toString().contains('42501')) {
        throw Exception('Доступ к бесплатным историям запрещен. '
            'Необходимо создать политику RLS в Supabase для таблицы free_stories:\n'
            'CREATE POLICY "Allow authenticated read access" ON tales.free_stories\n'
            'FOR SELECT USING (auth.uid() IS NOT NULL);');
      }
      throw Exception('Failed to fetch free stories: $e');
    }
  }

  @override
  Future<FreeStory?> getFreeStoryById(String id) async {
    try {
      final response = await _supabase
          .from('free_stories')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return FreeStory.fromJson(response);
    } catch (e) {
      // Если ошибка доступа, даем более информативное сообщение
      if (e.toString().contains('permission denied') ||
          e.toString().contains('42501')) {
        throw Exception('Доступ к бесплатным историям запрещен. '
            'Необходимо создать политику RLS в Supabase для таблицы free_stories:\n'
            'CREATE POLICY "Allow authenticated read access" ON tales.free_stories\n'
            'FOR SELECT USING (auth.uid() IS NOT NULL);');
      }
      throw Exception('Failed to fetch free story: $e');
    }
  }
}
