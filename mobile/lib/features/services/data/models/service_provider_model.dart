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

  // Create from about.json service name
  factory ServiceProviderModel.fromServiceName(String serviceName) {
    final now = DateTime.now();

    // Map service names to categories (temporary mapping)
    ServiceCategory category = ServiceCategory.other;
    if (serviceName.toLowerCase().contains('facebook') ||
        serviceName.toLowerCase().contains('twitter') ||
        serviceName.toLowerCase().contains('instagram')) {
      category = ServiceCategory.social;
    } else if (serviceName.toLowerCase().contains('drive') ||
        serviceName.toLowerCase().contains('dropbox')) {
      category = ServiceCategory.storage;
    } else if (serviceName.toLowerCase().contains('gmail') ||
        serviceName.toLowerCase().contains('outlook')) {
      category = ServiceCategory.communication;
    } else if (serviceName.toLowerCase().contains('calendar') ||
        serviceName.toLowerCase().contains('notion')) {
      category = ServiceCategory.productivity;
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