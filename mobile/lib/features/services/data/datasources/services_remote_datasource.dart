import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/about_info_model.dart';
import '../models/service_component_model.dart';
import '../../domain/value_objects/component_kind.dart';

abstract class ServicesRemoteDataSource {
  Future<AboutInfoModel> getAboutInfo();

  Future<List<ServiceComponentModel>> listComponents({
    ComponentKind? kind,
    String? provider,
    bool onlyAvailable,
  });
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final ApiClient apiClient;

  ServicesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AboutInfoModel> getAboutInfo() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>('/about.json');
      final data = response.data;
      if (data == null) {
        throw const NetworkFailure('Empty about response');
      }
      return AboutInfoModel.fromJson(data);
    } catch (e) {
      throw NetworkFailure('Failed to fetch about info: ${e.toString()}');
    }
  }

  @override
  Future<List<ServiceComponentModel>> listComponents({
    ComponentKind? kind,
    String? provider,
    bool onlyAvailable = false,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (kind != null) {
        query['kind'] = kind.value;
      }
      if (provider != null && provider.isNotEmpty) {
        query['provider'] = provider;
      }

      final endpoint =
          onlyAvailable ? '/v1/components/available' : '/v1/components';
      final response = await apiClient
          .get<Map<String, dynamic>>(endpoint, queryParameters: query);
      final data = response.data;
      if (data == null || data['components'] is! List) {
        throw const NetworkFailure('Invalid components response');
      }

      final components = data['components'] as List;
      return components
          .whereType<Map<String, dynamic>>()
          .map(ServiceComponentModel.fromJson)
          .toList();
    } catch (e) {
      throw NetworkFailure('Failed to fetch components: ${e.toString()}');
    }
  }
}
