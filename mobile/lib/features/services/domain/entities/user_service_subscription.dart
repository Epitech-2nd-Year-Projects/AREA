import 'package:equatable/equatable.dart';
import '../value_objects/subscription_status.dart';

class UserServiceSubscription extends Equatable {
  final String id;
  final String userId;
  final String providerId;
  final String? identityId;
  final SubscriptionStatus status;
  final List<String> scopeGrants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserServiceSubscription({
    required this.id,
    required this.userId,
    required this.providerId,
    this.identityId,
    required this.status,
    required this.scopeGrants,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get needsConsent => status == SubscriptionStatus.needsConsent;

  @override
  List<Object?> get props => [
    id,
    userId,
    providerId,
    identityId,
    status,
    scopeGrants,
    createdAt,
    updatedAt,
  ];
}