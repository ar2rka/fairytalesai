import '../entities/generation.dart';

abstract class GenerationRepository {
  Future<Generation> createGeneration(Generation generation);
  Future<Generation> updateGeneration(Generation generation);
  Future<Generation?> getGenerationById(String generationId, int attemptNumber);
  Future<List<Generation>> getGenerationsByUserId(String userId);
}

