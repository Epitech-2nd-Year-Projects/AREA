import '../../domain/entities/service_identity_summary.dart';

class IdentitySummaryModel {
  final String id;
  final String provider;
  final String subject;
  final List<String> scopes;
  final DateTime connectedAt;
  final DateTime? expiresAt;

  const IdentitySummaryModel({
    required this.id,
    required this.provider,
    required this.subject,
    required this.scopes,
    required this.connectedAt,
    this.expiresAt,
  });

  factory IdentitySummaryModel.fromJson(Map<String, dynamic> json) {
    final scopes = <String>[];
    final rawScopes = json['scopes'];
    if (rawScopes is List) {
      for (final scope in rawScopes) {
        if (scope is String) {
          scopes.add(scope);
        }
      }
    }

    return IdentitySummaryModel(
      id: json['id'] as String,
      provider: json['provider'] as String,
      subject: json['subject'] as String,
      scopes: scopes,
      connectedAt: DateTime.parse(json['connectedAt'] as String).toUtc(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String).toUtc()
          : null,
    );
  }

  ServiceIdentitySummary toEntity() {
    return ServiceIdentitySummary(
      id: id,
      provider: provider,
      subject: subject,
      scopes: scopes,
      connectedAt: connectedAt,
      expiresAt: expiresAt,
    );
  }
}
