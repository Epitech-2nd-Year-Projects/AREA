import 'package:bloc/bloc.dart';

import '../../domain/entities/area.dart';
import '../../domain/entities/area_status.dart';
import '../../domain/repositories/area_repository.dart';
import '../../domain/use_cases/delete_area.dart';
import '../../domain/use_cases/get_areas.dart';
import '../../domain/use_cases/update_area_status.dart';
import 'areas_state.dart';

class AreasCubit extends Cubit<AreasState> {
  late final GetAreas _getAreas;
  late final DeleteArea _deleteArea;
  late final UpdateAreaStatus _updateAreaStatus;

  AreasCubit(AreaRepository repository) : super(AreasInitial()) {
    _getAreas = GetAreas(repository);
    _deleteArea = DeleteArea(repository);
    _updateAreaStatus = UpdateAreaStatus(repository);
  }

  Future<void> fetchAreas() async {
    try {
      emit(AreasLoading());
      final areasList = await _getAreas();
      emit(AreasLoaded(areasList));
    } catch (e) {
      emit(AreasError("Unable to load Areas"));
    }
  }

  Future<void> removeArea(String areaId) async {
    try {
      emit(AreasLoading());
      await _deleteArea(areaId);
      final updatedList = await _getAreas();
      emit(AreasLoaded(updatedList));
    } catch (e) {
      emit(AreasError("Error deleting Area"));
    }
  }

  Future<void> toggleAreaStatus(Area area) async {
    final currentState = state;
    if (currentState is! AreasLoaded) {
      return;
    }

    final nextStatus = area.status == AreaStatus.enabled
        ? AreaStatus.disabled
        : AreaStatus.enabled;

    final pendingUpdates = {...currentState.updatingAreaIds, area.id};
    emit(
      currentState.copyWith(
        updatingAreaIds: pendingUpdates,
        clearMessage: true,
      ),
    );

    try {
      final updated = await _updateAreaStatus(
        areaId: area.id,
        status: nextStatus,
      );

      final latestState = state;
      if (latestState is! AreasLoaded) {
        return;
      }

      final refreshedAreas = latestState.areas
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList();
      final remainingUpdates = {...latestState.updatingAreaIds}
        ..remove(area.id);

      emit(
        latestState.copyWith(
          areas: refreshedAreas,
          updatingAreaIds: remainingUpdates,
          clearMessage: true,
        ),
      );
    } catch (e) {
      final latestState = state;
      if (latestState is! AreasLoaded) {
        emit(AreasError("Error updating Area status"));
        return;
      }

      final remainingUpdates = {...latestState.updatingAreaIds}
        ..remove(area.id);

      emit(
        latestState.copyWith(
          updatingAreaIds: remainingUpdates,
          messageKey: 'areaStatusUpdateFailed',
        ),
      );
    }
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is AreasLoaded && currentState.messageKey != null) {
      emit(currentState.copyWith(clearMessage: true));
    }
  }
}
