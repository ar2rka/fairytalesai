import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/free_story_reaction.dart';
import '../../domain/repositories/free_story_reaction_repository.dart';

class FreeStoryReactionRepositoryImpl implements FreeStoryReactionRepository {
  final SupabaseClient _supabase;

  FreeStoryReactionRepositoryImpl(this._supabase);

  @override
  Future<FreeStoryReaction> setReaction({
    required String freeStoryId,
    required ReactionType reactionType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Сначала проверяем, существует ли уже реакция
    final existingReaction = await _supabase
        .from('free_story_reactions')
        .select()
        .eq('free_story_id', freeStoryId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingReaction != null) {
      // Обновляем существующую реакцию
      final response = await _supabase
          .from('free_story_reactions')
          .update({
            'reaction_type': reactionType.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('free_story_id', freeStoryId)
          .eq('user_id', userId)
          .select()
          .single();

      return FreeStoryReaction.fromJson(response);
    } else {
      // Создаем новую реакцию
      final response = await _supabase
          .from('free_story_reactions')
          .insert({
            'free_story_id': freeStoryId,
            'user_id': userId,
            'reaction_type': reactionType.value,
          })
          .select()
          .single();

      return FreeStoryReaction.fromJson(response);
    }
  }

  @override
  Future<void> removeReaction(String freeStoryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('free_story_reactions')
        .delete()
        .eq('free_story_id', freeStoryId)
        .eq('user_id', userId);
  }

  @override
  Future<FreeStoryReaction?> getUserReaction(String freeStoryId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }

    final response = await _supabase
        .from('free_story_reactions')
        .select()
        .eq('free_story_id', freeStoryId)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return FreeStoryReaction.fromJson(response);
  }

  @override
  Future<FreeStoryReactionStats> getReactionStats(String freeStoryId) async {
    final userId = _supabase.auth.currentUser?.id;

    // Получаем все реакции для данной истории
    final reactions = await _supabase
        .from('free_story_reactions')
        .select('reaction_type, user_id')
        .eq('free_story_id', freeStoryId);

    final reactionsList = reactions as List;

    // Подсчитываем лайки и дизлайки
    int likesCount = 0;
    int dislikesCount = 0;
    String? userReaction;

    for (final reaction in reactionsList) {
      final reactionType = reaction['reaction_type'] as String;
      final reactionUserId = reaction['user_id'] as String;

      if (reactionType == 'like') {
        likesCount++;
      } else if (reactionType == 'dislike') {
        dislikesCount++;
      }

      // Проверяем реакцию текущего пользователя
      if (userId != null && reactionUserId == userId) {
        userReaction = reactionType;
      }
    }

    return FreeStoryReactionStats(
      likesCount: likesCount,
      dislikesCount: dislikesCount,
      userReaction: userReaction,
    );
  }
}
