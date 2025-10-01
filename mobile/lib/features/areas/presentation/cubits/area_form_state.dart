import '../../domain/entities/area.dart';

abstract class AreaFormState {
  const AreaFormState();
}

class AreaFormInitial extends AreaFormState {
  const AreaFormInitial();
}

class AreaFormSubmitting extends AreaFormState {
  const AreaFormSubmitting();
}

class AreaFormSuccess extends AreaFormState {
  final Area area;
  const AreaFormSuccess(this.area);
}

class AreaFormError extends AreaFormState {
  final String message;
  const AreaFormError(this.message);
}
