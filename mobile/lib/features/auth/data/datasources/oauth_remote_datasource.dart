import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/exceptions/network_exceptions.dart';
import '../../domain/entities/oauth_provider.dart';
import '../../domain/exceptions/oauth_exceptions.dart';
import '../models/oauth_authorization_response_model.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

abstract class OAuthRemoteDataSource {
  Future<OAuthAuthorizationResponseModel> startOAuthFlow(
      OAuthProvider provider,
      String? redirectUri,
      );

  Future<AuthSessionModel> exchangeCode(
      OAuthProvider provider,
      String code,
      String? codeVerifier,
      String? redirectUri,
      String? state,
      );
}

class OAuthRemoteDataSourceImpl implements OAuthRemoteDataSource {
  final ApiClient _apiClient;

  OAuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<OAuthAuthorizationResponseModel> startOAuthFlow(
      OAuthProvider provider,
      String? redirectUri,
      ) async {
    try {
      redirectUri = ApiConfig.getOAuthCallbackUrl(provider.slug);
      final providerSlug = provider.slug;

      final Map<String, dynamic> requestData = {};
      if (redirectUri != null) {
        requestData['redirectUri'] = redirectUri;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/oauth/$providerSlug/authorize',
        data: requestData.isNotEmpty ? requestData : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        return OAuthAuthorizationResponseModel.fromJson(response.data!);
      }

      throw NetworkException('Failed to start OAuth flow');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthSessionModel> exchangeCode(
      OAuthProvider provider,
      String code,
      String? codeVerifier,
      String? redirectUri,
      String? state,
      ) async {
    try {
      final providerSlug = _getProviderSlug(provider);

      final Map<String, dynamic> requestData = {'code': code};

      if (codeVerifier != null) {
        requestData['codeVerifier'] = codeVerifier;
      }

      if (redirectUri != null) {
        requestData['redirectUri'] = redirectUri;
      }

      if (state != null) {
        requestData['state'] = state;
      }

      debugPrint('📤 Exchange request data: $requestData');

      final exchangeResponse = await _apiClient.post<Map<String, dynamic>>(
        '/v1/oauth/$providerSlug/exchange',
        data: requestData,
      );

      if (exchangeResponse.statusCode != 200 ||
          exchangeResponse.data == null) {
        throw NetworkException('Failed to exchange OAuth code');
      }

      final userResponse = await _apiClient.get<Map<String, dynamic>>(
        '/v1/auth/me',
      );

      if (userResponse.statusCode != 200 || userResponse.data == null) {
        throw NetworkException('Failed to fetch user after OAuth exchange');
      }

      final userData = userResponse.data!['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      return AuthSessionModel.fromOAuthJson(
        exchangeResponse.data!,
        user,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _getProviderSlug(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.google:
        return 'google';
      case OAuthProvider.facebook:
        return 'facebook';
      case OAuthProvider.apple:
        return 'apple';
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String errorMessage = 'Unknown error';

      if (data is Map<String, dynamic>) {
        if (data.containsKey('error')) {
          errorMessage = data['error'] as String;
        } else if (data.containsKey('message')) {
          errorMessage = data['message'] as String;
        }
      } else if (data is String) {
        errorMessage = data;
      }

      debugPrint('❌ Server error ($statusCode): $errorMessage');
      debugPrint('❌ Response body: $data');

      switch (statusCode) {
        case 400:
          return OAuthFlowFailedException('Bad request: $errorMessage');
        case 401:
          return CallbackErrorException('Unauthorized: $errorMessage');
        case 404:
          return UnsupportedProviderException(errorMessage);
        case 502:
          return OAuthFlowFailedException('Server error (502): $errorMessage');
        default:
          return OAuthException('HTTP $statusCode: $errorMessage');
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return OAuthException('Connection timeout');
    }

    if (error.type == DioExceptionType.connectionError) {
      return OAuthException('Connection error: ${error.message}');
    }

    return NetworkException.fromDioError(error);
  }
}