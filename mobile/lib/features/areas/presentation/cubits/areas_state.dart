import 'package:equatable/equatable.dart';
import '../../domain/entities/area.dart';

abstract class AreasState extends Equatable {
  const AreasState();

  @override
  List<Object?> get props => [];
}

class AreasInitial extends AreasState {}

class AreasLoading extends AreasState {}

class AreasLoaded extends AreasState {
  final List<Area> areas;
  final Set<String> updatingAreaIds;
  final String? messageKey;

  const AreasLoaded(
    this.areas, {
    this.updatingAreaIds = const <String>{},
    this.messageKey,
  });

  AreasLoaded copyWith({
    List<Area>? areas,
    Set<String>? updatingAreaIds,
    String? messageKey,
    bool clearMessage = false,
  }) {
    return AreasLoaded(
      areas ?? this.areas,
      updatingAreaIds: updatingAreaIds ?? this.updatingAreaIds,
      messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
    );
  }

  bool isUpdating(String areaId) => updatingAreaIds.contains(areaId);

  @override
  List<Object?> get props => [areas, updatingAreaIds, messageKey];
}

class AreasError extends AreasState {
  final String message;
  const AreasError(this.message);
  @override
  List<Object?> get props => [message];
}
