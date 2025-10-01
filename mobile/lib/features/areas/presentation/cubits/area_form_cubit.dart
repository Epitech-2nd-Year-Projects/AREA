import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/area.dart';
import '../../domain/use_cases/create_area.dart';
import '../../domain/use_cases/update_area.dart';
import 'area_form_state.dart';

class AreaFormCubit extends Cubit<AreaFormState> {
  final CreateArea _createArea;
  final UpdateArea _updateArea;
  final Area? initialArea;

  AreaFormCubit({
    required CreateArea createArea,
    required UpdateArea updateArea,
    this.initialArea,
  })  : _createArea = createArea,
        _updateArea = updateArea,
        super(AreaFormInitial());

  Future<void> submit({
    required String name,
    required bool isActive,
    required String actionName,
    required String reactionName,
  }) async {
    emit(AreaFormSubmitting());
    try {
      if (initialArea == null) {
        final newArea = Area(
          id: '',
          userId: 'me', // TODO: use real user ID
          name: name,
          isActive: isActive,
          actionName: actionName,
          reactionName: reactionName,
        );
        final created = await _createArea(newArea);
        emit(AreaFormSuccess(created));
      } else {
        final updated = initialArea!.copyWith(
          name: name,
          isActive: isActive,
          actionName: actionName,
          reactionName: reactionName,
        );
        final result = await _updateArea(updated);
        emit(AreaFormSuccess(result));
      }
    } catch (_) {
      emit(const AreaFormError("Échec de l'enregistrement de l'Area"));
    }
  }
}
