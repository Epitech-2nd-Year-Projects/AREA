enum ServiceCategory {
  social('social'),
  productivity('productivity'),
  communication('communication'),
  storage('storage'),
  development('development'),
  other('other');

  const ServiceCategory(this.value);
  final String value;

  static ServiceCategory fromString(String value) {
    return ServiceCategory.values.firstWhere(
          (category) => category.value == value,
      orElse: () => ServiceCategory.other,
    );
  }

  String get displayName {
    switch (this) {
      case ServiceCategory.social:
        return 'Social Media';
      case ServiceCategory.productivity:
        return 'Productivity';
      case ServiceCategory.communication:
        return 'Communication';
      case ServiceCategory.storage:
        return 'Cloud Storage';
      case ServiceCategory.development:
        return 'Development';
      case ServiceCategory.other:
        return 'Other';
    }
  }
}