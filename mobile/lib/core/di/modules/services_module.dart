import 'package:get_it/get_it.dart';
import '../../../features/services/data/datasources/services_remote_datasource.dart';
import '../../../features/services/data/repositories/services_repository_impl.dart';
import '../../../features/services/domain/repositories/services_repository.dart';
import '../../network/api_client.dart';
import '../di_modules.dart';

class ServicesModule implements DIModule {
  @override
  Future<void> register(GetIt sl) async {
    sl.registerLazySingleton<ServicesRemoteDataSource>(
      () => ServicesRemoteDataSourceImpl(sl<ApiClient>()),
    );

    sl.registerLazySingleton<ServicesRepository>(
      () => ServicesRepositoryImpl(sl<ServicesRemoteDataSource>()),
    );
  }
}
