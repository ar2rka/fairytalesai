import 'language.dart';

enum Gender {
  male('male'),
  female('female'),
  other('other');

  final String value;
  const Gender(this.value);

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.other,
    );
  }

  String translate(Language language) {
    switch (this) {
      case Gender.male:
        return language == Language.russian ? 'Мужской' : 'Male';
      case Gender.female:
        return language == Language.russian ? 'Женский' : 'Female';
      case Gender.other:
        return language == Language.russian ? 'Другой' : 'Other';
    }
  }
}

