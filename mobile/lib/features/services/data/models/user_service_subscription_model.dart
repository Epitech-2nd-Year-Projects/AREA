import '../../domain/entities/user_service_subscription.dart';
import '../../domain/value_objects/subscription_status.dart';

class UserServiceSubscriptionModel {
  final String id;
  final String providerId;
  final String? identityId;
  final SubscriptionStatus status;
  final List<String> scopeGrants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserServiceSubscriptionModel({
    required this.id,
    required this.providerId,
    required this.identityId,
    required this.status,
    required this.scopeGrants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserServiceSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final scopeGrants = <String>[];
    final rawScopes = json['scopeGrants'] ?? json['scope_grants'];
    if (rawScopes is List) {
      for (final scope in rawScopes) {
        if (scope is String) {
          scopeGrants.add(scope);
        }
      }
    }

    return UserServiceSubscriptionModel(
      id: json['id'] as String,
      providerId: json['providerId'] as String,
      identityId: json['identityId'] as String?,
      status: SubscriptionStatus.fromString(json['status'] as String),
      scopeGrants: scopeGrants,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
    );
  }

  UserServiceSubscription toEntity() {
    return UserServiceSubscription(
      id: id,
      userId: null,
      providerId: providerId,
      identityId: identityId,
      status: status,
      scopeGrants: scopeGrants,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
