import 'package:equatable/equatable.dart';
import '../../domain/entities/area.dart';

abstract class AreaFormState extends Equatable {
  const AreaFormState();
  @override List<Object?> get props => [];
}
class AreaFormInitial extends AreaFormState {}
class AreaFormSubmitting extends AreaFormState {}
class AreaFormSuccess extends AreaFormState {
  final Area area;
  const AreaFormSuccess(this.area);
  @override List<Object?> get props => [area];
}
class AreaFormError extends AreaFormState {
  final String message;
  const AreaFormError(this.message);
  @override List<Object?> get props => [message];
}
