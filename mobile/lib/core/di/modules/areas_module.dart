import 'package:get_it/get_it.dart';
import '../../../features/areas/data/datasources/area_remote_datasource.dart';
import '../../../features/areas/data/repositories/area_repository_impl.dart';
import '../../../features/areas/domain/repositories/area_repository.dart';
import '../../network/api_client.dart';
import '../di_modules.dart';

class AreasModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    sl.registerLazySingleton<AreaRemoteDataSource>(
          () => AreaRemoteDataSourceImpl(sl<ApiClient>()),
    );

    sl.registerLazySingleton<AreaRepository>(
          () => AreaRepositoryImpl(sl<AreaRemoteDataSource>()),
    );
  }
}