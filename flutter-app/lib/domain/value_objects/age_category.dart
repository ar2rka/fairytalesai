import 'language.dart';

enum AgeCategory {
  twoToThree('2-3', '2-3 года', '2-3 years'),
  threeToFive('3-5', '3-5 лет', '3-5 years'),
  fiveToSeven('5-7', '5-7 лет', '5-7 years');

  final String value;
  final String labelRu;
  final String labelEn;

  const AgeCategory(this.value, this.labelRu, this.labelEn);

  static AgeCategory fromString(String value) {
    return AgeCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => AgeCategory.threeToFive,
    );
  }

  // Обратная совместимость со старыми значениями
  static AgeCategory fromLegacyString(String value) {
    switch (value) {
      case 'under_3':
        return AgeCategory.twoToThree;
      case '3_to_5':
        return AgeCategory.threeToFive;
      case 'over_5':
        return AgeCategory.fiveToSeven;
      default:
        return fromString(value);
    }
  }

  String translate(Language language) {
    return language == Language.russian ? labelRu : labelEn;
  }

  String get displayLabel => labelRu;
}
