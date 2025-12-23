import 'package:json_annotation/json_annotation.dart';
import '../value_objects/gender.dart';
import '../value_objects/age_category.dart';

part 'child.g.dart';

@JsonSerializable()
class Child {
  final String? id;
  final String name;
  @JsonKey(name: 'age_category')
  final String ageCategory;
  final String gender;
  final List<String> interests;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Child({
    this.id,
    required this.name,
    required this.ageCategory,
    required this.gender,
    required this.interests,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Child.fromJson(Map<String, dynamic> json) => _$ChildFromJson(json);

  Map<String, dynamic> toJson() => _$ChildToJson(this);

  Gender get genderEnum => Gender.fromString(gender);

  AgeCategory get ageCategoryEnum => AgeCategory.fromLegacyString(ageCategory);
}
