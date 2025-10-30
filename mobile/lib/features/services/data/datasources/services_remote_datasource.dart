import 'package:area/core/network/api_config.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../models/about_info_model.dart';
import '../models/service_component_model.dart';
import '../models/identity_summary_model.dart';
import '../models/subscribe_exchange_response_model.dart';
import '../models/subscribe_service_response_model.dart';
import '../../domain/entities/service_subscription_exchange_result.dart';

abstract class ServicesRemoteDataSource {
  Future<AboutInfoModel> getAboutInfo();

  Future<List<ServiceComponentModel>> listComponents({bool onlyAvailable});

  Future<List<IdentitySummaryModel>> listIdentities();

  Future<List<Map<String, dynamic>>> listServiceProviders();

  Future<List<Map<String, dynamic>>> listServiceSubscriptions();

  Future<void> unsubscribeFromService(String provider);

  Future<SubscribeServiceResponseModel> subscribeToService({
    required String provider,
    List<String>? scopes,
    String? redirectUri,
    String? state,
    bool? usePkce,
  });

  Future<ServiceSubscriptionExchangeResult> completeSubscription({
    required String provider,
    required String code,
    String? codeVerifier,
    String? redirectUri,
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
    bool onlyAvailable = false,
  }) async {
    try {
      final endpoint = onlyAvailable
          ? '/v1/components/available'
          : '/v1/components';
      final response = await apiClient.get<Map<String, dynamic>>(endpoint);
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

  @override
  Future<List<IdentitySummaryModel>> listIdentities() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/v1/identities',
      );
      final data = response.data;
      if (data == null || data['identities'] is! List) {
        throw const NetworkFailure('Invalid identities response');
      }

      final identities = data['identities'] as List;
      return identities
          .whereType<Map<String, dynamic>>()
          .map(IdentitySummaryModel.fromJson)
          .toList();
    } catch (e) {
      throw NetworkFailure('Failed to fetch identities: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listServiceProviders() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/v1/services',
      );
      final data = response.data;
      if (data == null || data['providers'] is! List) {
        throw const NetworkFailure('Invalid services response');
      }

      final providers = data['providers'] as List;
      return providers.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw NetworkFailure(
        'Failed to fetch service providers: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listServiceSubscriptions() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/v1/services/subscriptions',
      );
      final data = response.data;
      if (data == null || data['subscriptions'] is! List) {
        throw const NetworkFailure('Invalid subscriptions response');
      }

      final subscriptions = data['subscriptions'] as List;
      return subscriptions.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw NetworkFailure('Failed to fetch subscriptions: ${e.toString()}');
    }
  }

  @override
  Future<void> unsubscribeFromService(String provider) async {
    try {
      await apiClient.delete<void>('/v1/services/$provider/subscription');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkFailure('Failed to unsubscribe: ${e.toString()}');
    }
  }

  @override
  Future<SubscribeServiceResponseModel> subscribeToService({
    required String provider,
    List<String>? scopes,
    String? redirectUri,
    String? state,
    bool? usePkce,
  }) async {
    try {
      redirectUri = ApiConfig.getServiceCallbackUrl(provider);
      final payload = <String, dynamic>{};
      if (scopes != null && scopes.isNotEmpty) {
        payload['scopes'] = scopes;
      }
      payload['redirectUri'] = redirectUri;
      if (state != null) {
        payload['state'] = state;
      }
      payload['usePkce'] = usePkce ?? true;

      final response = await apiClient.post<Map<String, dynamic>>(
        '/v1/services/$provider/subscribe',
        data: payload.isEmpty ? null : payload,
      );

      final data = response.data;
      if (data == null) {
        throw const NetworkFailure('Empty subscription response');
      }

      return SubscribeServiceResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkFailure('Failed to subscribe: ${e.toString()}');
    }
  }

  @override
  Future<ServiceSubscriptionExchangeResult> completeSubscription({
    required String provider,
    required String code,
    String? codeVerifier,
    String? redirectUri,
  }) async {
    try {
      final payload = <String, dynamic>{'code': code};
      if (codeVerifier != null && codeVerifier.isNotEmpty) {
        payload['codeVerifier'] = codeVerifier;
      }
      if (redirectUri != null && redirectUri.isNotEmpty) {
        payload['redirectUri'] = redirectUri;
      }

      final response = await apiClient.post<Map<String, dynamic>>(
        '/v1/services/$provider/subscribe/exchange',
        data: payload,
      );

      final data = response.data;
      if (data == null) {
        throw const NetworkFailure('Empty subscription exchange response');
      }

      return SubscribeExchangeResponseModel.fromJson(data).toEntity();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkFailure('Failed to complete subscription: ${e.toString()}');
    }
  }

  Failure _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      final data = error.response!.data;

      String message = 'Subscription request failed';
      if (data is Map<String, dynamic> && data['error'] is String) {
        message = data['error'] as String;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }

      if (statusCode == 401) {
        return UnauthorizedFailure(message);
      }
      if (statusCode == 404) {
        return NetworkFailure('Provider not found');
      }
      if (statusCode == 409) {
        return NetworkFailure('Identity already linked to another user');
      }
      if (statusCode >= 500) {
        return NetworkFailure('Server error ($statusCode): $message');
      }
      return NetworkFailure(message);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.badCertificate ||
        error.type == DioExceptionType.connectionError) {
      return NetworkFailure('Network error: ${error.message}');
    }

    return NetworkFailure('Subscription error: ${error.message}');
  }
}
