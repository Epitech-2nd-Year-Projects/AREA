import '../../domain/entities/service_provider.dart';
import '../../domain/value_objects/service_category.dart';
import '../../domain/value_objects/auth_kind.dart';

class ServiceProviderModel {
  final String id;
  final String name;
  final String displayName;
  final ServiceCategory category;
  final AuthKind oauthType;
  final Map<String, dynamic> authConfig;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceProviderModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.category,
    required this.oauthType,
    required this.authConfig,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: json['id'] as String? ?? json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName:
          json['displayName'] as String? ??
          json['display_name'] as String? ??
          '',
      category: ServiceCategory.fromString(
        json['category'] as String? ?? 'other',
      ),
      oauthType: AuthKind.fromString(
        json['oauthType'] as String? ??
            json['authType'] as String? ??
            json['auth_type'] as String? ??
            'oauth2',
      ),
      authConfig:
          json['authConfig'] as Map<String, dynamic>? ??
          json['auth_config'] as Map<String, dynamic>? ??
          {},
      isEnabled:
          json['isEnabled'] as bool? ?? json['is_enabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toUtc()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toUtc()
          : DateTime.now(),
    );
  }

  factory ServiceProviderModel.fromServiceName(String serviceName) {
    final now = DateTime.now();

    ServiceCategory category = ServiceCategory.other;
    final lowerName = serviceName.toLowerCase();

    if (lowerName.contains('facebook') ||
        lowerName.contains('twitter') ||
        lowerName.contains('instagram')) {
      category = ServiceCategory.social;
    } else if (lowerName.contains('drive') || lowerName.contains('dropbox')) {
      category = ServiceCategory.storage;
    } else if (lowerName.contains('gmail') || lowerName.contains('outlook')) {
      category = ServiceCategory.communication;
    } else if (lowerName.contains('calendar') || lowerName.contains('notion')) {
      category = ServiceCategory.productivity;
    } else if (lowerName.contains('github') ||
        lowerName.contains('gitlab') ||
        lowerName.contains('bitbucket')) {
      category = ServiceCategory.development;
    }

    return ServiceProviderModel(
      id: serviceName.toLowerCase().replaceAll(' ', '_'),
      name: serviceName.toLowerCase(),
      displayName: _formatDisplayName(serviceName),
      category: category,
      oauthType: AuthKind.oauth2,
      authConfig: {},
      isEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _formatDisplayName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  ServiceProvider toEntity() {
    return ServiceProvider(
      id: id,
      name: name,
      displayName: displayName,
      category: category,
      oauthType: oauthType,
      authConfig: authConfig,
      isEnabled: isEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
