import 'package:equatable/equatable.dart';

class ServiceIdentitySummary extends Equatable {
  final String id;
  final String provider;
  final String subject;
  final List<String> scopes;
  final DateTime connectedAt;
  final DateTime? expiresAt;

  const ServiceIdentitySummary({
    required this.id,
    required this.provider,
    required this.subject,
    required this.scopes,
    required this.connectedAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props => [
    id,
    provider,
    subject,
    scopes,
    connectedAt,
    expiresAt,
  ];
}
