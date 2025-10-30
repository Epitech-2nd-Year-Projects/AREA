import 'package:bloc/bloc.dart';
import 'package:area/features/areas/domain/use_cases/get_areas.dart';
import 'package:area/features/areas/domain/use_cases/delete_area.dart';
import 'package:area/features/areas/presentation/cubits/areas_state.dart';
import 'package:area/features/areas/domain/repositories/area_repository.dart';

class AreasCubit extends Cubit<AreasState> {
  late final GetAreas _getAreas;
  late final DeleteArea _deleteArea;

  AreasCubit(AreaRepository repository) : super(AreasInitial()) {
    _getAreas = GetAreas(repository);
    _deleteArea = DeleteArea(repository);
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
}
