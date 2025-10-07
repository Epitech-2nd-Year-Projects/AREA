enum AreaStatus {
  enabled('enabled'),
  disabled('disabled'),
  archived('archived');

  const AreaStatus(this.value);

  final String value;

  static AreaStatus fromString(String value) {
    return AreaStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AreaStatus.enabled,
    );
  }
}
