import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions/network_exceptions.dart';
import '../../../../core/network/exceptions/unauthorized_exception.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../models/user_model.dart';
import '../models/register_response_model.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<RegisterResponseModel> register(String email, String password);

  Future<AuthResponseModel> verifyEmail(String token);

  Future<AuthResponseModel> login(String email, String password);

  Future<void> logout();

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<RegisterResponseModel> register(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/users',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 202 && response.data != null) {
        return RegisterResponseModel.fromJson(response.data!);
      }

      throw NetworkException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponseModel> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/auth/verify',
        data: {'token': token},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponseModel.fromJson(response.data!);
      }

      throw NetworkException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AuthResponseModel.fromJson(response.data!);
      }

      throw NetworkException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/v1/auth/logout');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException.fromDioError(e);
      }
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/auth/me',
      );

      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data!['user'] as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      }

      throw NetworkException('Unexpected response from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String errorMessage = 'Unknown error';
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        errorMessage = data['error'] as String;
      }

      switch (statusCode) {
        case 400:
          return _handle400Error(errorMessage);
        case 401:
          return UnauthorizedException(errorMessage);
        case 403:
          return AccountNotVerifiedException();
        case 409:
          return UserAlreadyExistsException();
        case 410:
          return TokenExpiredException();
        default:
          return NetworkException(errorMessage);
      }
    }

    return NetworkException.fromDioError(error);
  }

  Exception _handle400Error(String message) {
    if (message.contains('invalid credentials')) {
      return InvalidCredentialsException();
    }
    if (message.contains('email')) {
      return InvalidEmailException(message);
    }
    if (message.contains('password')) {
      return WeakPasswordException(message);
    }
    return NetworkException(message);
  }
}
