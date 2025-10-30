import 'package:equatable/equatable.dart';
import '../value_objects/service_category.dart';
import '../value_objects/auth_kind.dart';

class ServiceProvider extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final ServiceCategory category;
  final AuthKind oauthType;
  final Map<String, dynamic> authConfig;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceProvider({
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

  @override
  List<Object?> get props => [
    id,
    name,
    displayName,
    category,
    oauthType,
    authConfig,
    isEnabled,
    createdAt,
    updatedAt,
  ];
}
