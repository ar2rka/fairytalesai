import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/story.dart';

part 'generate_story_response.g.dart';

@JsonSerializable()
class GenerateStoryResponse {
  final Story story;
  @JsonKey(name: 'generation_id')
  final String generationId;

  GenerateStoryResponse({
    required this.story,
    required this.generationId,
  });

  factory GenerateStoryResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateStoryResponseFromJson(json);
}

