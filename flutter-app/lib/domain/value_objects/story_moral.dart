import 'language.dart';

enum StoryMoral {
  kindness('kindness'),
  honesty('honesty'),
  bravery('bravery'),
  friendship('friendship'),
  perseverance('perseverance'),
  empathy('empathy'),
  respect('respect'),
  responsibility('responsibility');

  final String value;
  const StoryMoral(this.value);

  static StoryMoral fromString(String value) {
    return StoryMoral.values.firstWhere(
      (moral) => moral.value == value,
      orElse: () => StoryMoral.kindness,
    );
  }

  String translate(Language language) {
    if (language == Language.russian) {
      switch (this) {
        case StoryMoral.kindness:
          return 'Доброта';
        case StoryMoral.honesty:
          return 'Честность';
        case StoryMoral.bravery:
          return 'Храбрость';
        case StoryMoral.friendship:
          return 'Дружба';
        case StoryMoral.perseverance:
          return 'Настойчивость';
        case StoryMoral.empathy:
          return 'Эмпатия';
        case StoryMoral.respect:
          return 'Уважение';
        case StoryMoral.responsibility:
          return 'Ответственность';
      }
    } else {
      return value;
    }
  }
}

