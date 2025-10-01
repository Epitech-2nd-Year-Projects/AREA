import 'package:equatable/equatable.dart';

class Area extends Equatable {
  final String id;
  final String userId;
  final String name;
  final bool isActive;
  final String actionName;
  final String reactionName;

  const Area({
    required this.id,
    required this.userId,
    required this.name,
    required this.isActive,
    required this.actionName,
    required this.reactionName,
  });

  Area copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isActive,
    String? actionName,
    String? reactionName,
  }) {
    return Area(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      actionName: actionName ?? this.actionName,
      reactionName: reactionName ?? this.reactionName,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, isActive, actionName, reactionName];
}
