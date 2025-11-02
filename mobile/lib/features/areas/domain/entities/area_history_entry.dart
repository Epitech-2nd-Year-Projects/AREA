import 'package:equatable/equatable.dart';

class AreaHistoryEntry extends Equatable {
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

  const AreaHistoryEntry({
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

  bool get isSuccessful => status.toLowerCase() == 'succeeded';

  Duration? get duration {
    if (runAt == null) {
      return null;
    }
    return updatedAt.difference(runAt!);
  }

  @override
  List<Object?> get props => [
    jobId,
    status,
    attempt,
    runAt,
    createdAt,
    updatedAt,
    error,
    resultPayload,
    reactionComponent,
    reactionProvider,
  ];
}
