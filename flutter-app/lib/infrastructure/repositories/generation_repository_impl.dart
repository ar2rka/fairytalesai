import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/generation.dart';
import '../../domain/repositories/generation_repository.dart';

class GenerationRepositoryImpl implements GenerationRepository {
  final SupabaseClient _supabase;

  GenerationRepositoryImpl(this._supabase);

  @override
  Future<Generation> createGeneration(Generation generation) async {
    final response = await _supabase
        .from('generations')
        .insert(generation.toJson())
        .select()
        .single();

    return Generation.fromJson(response);
  }

  @override
  Future<Generation> updateGeneration(Generation generation) async {
    final response = await _supabase
        .from('generations')
        .update(generation.toJson())
        .match({
          'generation_id': generation.generationId,
          'attempt_number': generation.attemptNumber,
        })
        .select()
        .single();

    return Generation.fromJson(response);
  }

  @override
  Future<Generation?> getGenerationById(
      String generationId, int attemptNumber) async {
    final response = await _supabase
        .from('generations')
        .select()
        .eq('generation_id', generationId)
        .eq('attempt_number', attemptNumber)
        .maybeSingle();

    if (response == null) return null;
    return Generation.fromJson(response);
  }

  @override
  Future<List<Generation>> getGenerationsByUserId(String userId) async {
    final response = await _supabase
        .from('generations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Generation.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

