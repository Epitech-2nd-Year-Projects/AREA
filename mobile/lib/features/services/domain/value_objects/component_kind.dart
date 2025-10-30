enum ComponentKind {
  action('action'),
  reaction('reaction');

  const ComponentKind(this.value);
  final String value;

  static ComponentKind fromString(String value) {
    return ComponentKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => ComponentKind.action,
    );
  }

  String get displayName {
    switch (this) {
      case ComponentKind.action:
        return 'Action';
      case ComponentKind.reaction:
        return 'Reaction';
    }
  }
}
