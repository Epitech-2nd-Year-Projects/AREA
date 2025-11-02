import '../../domain/entities/area_history_entry.dart';

class AreaHistoryEntryModel {
  final String jobId;
  final String status;
  final int attempt;
  final DateTime? runAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? error;
  final Map<String, dynamic>? resultPayload;
  final String reactionComponent;
  final String reactionProvider;

  AreaHistoryEntryModel({
    required this.jobId,
    required this.status,
    required this.attempt,
    required this.runAt,
    required this.createdAt,
    required this.updatedAt,
    required this.error,
    required this.resultPayload,
    required this.reactionComponent,
    required this.reactionProvider,
  });

  factory AreaHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    final reaction = json['reaction'] is Map
        ? Map<String, dynamic>.from(json['reaction'] as Map)
        : <String, dynamic>{};
    final createdAt = _parseDate(json['createdAt']) ?? DateTime.now().toUtc();
    final updatedAt = _parseDate(json['updatedAt']) ?? createdAt;
    final rawJobId = json['jobId'] as String? ?? '';
    final jobId = rawJobId.isNotEmpty
        ? rawJobId
        : 'job-${updatedAt.microsecondsSinceEpoch}';

    return AreaHistoryEntryModel(
      jobId: jobId,
      status: json['status'] as String? ?? '',
      attempt: json['attempt'] is int
          ? json['attempt'] as int
          : int.tryParse('${json['attempt']}') ?? 0,
      runAt: _parseDate(json['runAt']),
      createdAt: createdAt,
      updatedAt: updatedAt,
      error: json['error'] as String?,
      resultPayload: json['resultPayload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['resultPayload'] as Map<String, dynamic>,
            )
          : null,
      reactionComponent: reaction['component'] as String? ?? '',
      reactionProvider: reaction['provider'] as String? ?? '',
    );
  }

  AreaHistoryEntry toEntity() {
    return AreaHistoryEntry(
      jobId: jobId,
      status: status,
      attempt: attempt,
      runAt: runAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      error: error,
      resultPayload: resultPayload,
      reactionComponent: reactionComponent,
      reactionProvider: reactionProvider,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
