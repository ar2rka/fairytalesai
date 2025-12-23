enum Language {
  english('en', 'English'),
  russian('ru', 'Russian');

  final String code;
  final String displayName;

  const Language(this.code, this.displayName);

  static Language fromCode(String code) {
    return Language.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => Language.english,
    );
  }
}

