import '../dto/generate_story_request.dart';
import '../dto/generate_story_response.dart';
import '../../infrastructure/external/api_client.dart';

class GenerateStoryUseCase {
  final ApiClient _apiClient;

  GenerateStoryUseCase(this._apiClient);

  Future<GenerateStoryResponse> execute(GenerateStoryRequest request) async {
    final response = await _apiClient.post(
      '/stories/generate',
      data: request.toJson(),
    );

    return GenerateStoryResponse.fromJson(response.data);
  }
}

