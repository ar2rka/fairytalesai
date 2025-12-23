enum GenerationStatus {
  pending('pending'),
  success('success'),
  failed('failed'),
  timeout('timeout');

  final String value;
  const GenerationStatus(this.value);

  static GenerationStatus fromString(String value) {
    return GenerationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GenerationStatus.pending,
    );
  }
}

