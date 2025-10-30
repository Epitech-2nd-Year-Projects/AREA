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
  const AreasLoaded(this.areas);
  @override
  List<Object?> get props => [areas];
}

class AreasError extends AreasState {
  final String message;
  const AreasError(this.message);
  @override
  List<Object?> get props => [message];
}
