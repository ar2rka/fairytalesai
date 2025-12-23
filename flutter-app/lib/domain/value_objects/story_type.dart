enum StoryType {
  child('child'),
  hero('hero'),
  combined('combined');

  final String value;
  const StoryType(this.value);

  static StoryType fromString(String value) {
    return StoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StoryType.child,
    );
  }
}

