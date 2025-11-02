import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/exceptions/network_exceptions.dart';
import '../models/area_model.dart';
import '../models/area_request_model.dart';
import '../models/area_update_request_model.dart';
import '../../domain/entities/area_status.dart';

abstract class AreaRemoteDataSource {
  Future<List<AreaModel>> listAreas();
  Future<AreaModel> createArea(AreaRequestModel request);
  Future<AreaModel> updateArea(String areaId, AreaUpdateRequestModel request);
  Future<AreaModel> updateAreaStatus(String areaId, AreaStatus status);
  Future<void> deleteArea(String areaId);
  Future<void> executeArea(String areaId);
}

class AreaRemoteDataSourceImpl implements AreaRemoteDataSource {
  final ApiClient _apiClient;

  AreaRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<AreaModel>> listAreas() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/v1/areas');
      final data = response.data;
      if (data == null || data['areas'] is! List) {
        throw NetworkException('Invalid areas response');
      }
      final list = data['areas'] as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(AreaModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AreaModel> createArea(AreaRequestModel request) async {
    try {
      debugPrint(jsonEncode(request.toJson()));
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/areas',
        data: request.toJson(),
      );
      if (response.statusCode == 201 && response.data != null) {
        return AreaModel.fromJson(response.data!);
      }
      throw NetworkException('Unexpected response when creating area');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AreaModel> updateArea(
    String areaId,
    AreaUpdateRequestModel request,
  ) async {
    try {
      final payload = request.toJson();
      if (payload.isEmpty) {
        throw NetworkException('No changes detected.');
      }

      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/v1/areas/$areaId',
        data: payload,
      );
      if (response.statusCode == 200 && response.data != null) {
        return AreaModel.fromJson(response.data!);
      }
      throw NetworkException('Unexpected response when updating area');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<AreaModel> updateAreaStatus(String areaId, AreaStatus status) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/v1/areas/$areaId/status',
        data: {'status': status.value},
      );

      if (response.statusCode == 200 && response.data != null) {
        return AreaModel.fromJson(response.data!);
      }
      throw NetworkException('Unexpected response when updating area status');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> deleteArea(String areaId) async {
    try {
      await _apiClient.delete<void>('/v1/areas/$areaId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  @override
  Future<void> executeArea(String areaId) async {
    try {
      await _apiClient.post<void>('/v1/areas/$areaId/execute');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return NetworkException.fromDioError(error);
    }

    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      final data = error.response!.data;
      String message = 'Request failed';
      if (data is Map<String, dynamic> && data['error'] is String) {
        message = data['error'] as String;
      }

      if (statusCode == 401) {
        return NetworkException('Authentication required');
      }
      if (statusCode == 403) {
        return NetworkException('You are not allowed to perform this action');
      }
      if (statusCode == 404) {
        return NetworkException('Area not found');
      }
      if (statusCode == 409) {
        return NetworkException('Area already exists');
      }
      if (statusCode >= 500) {
        return NetworkException('Server error: $message');
      }
      return NetworkException(message);
    }

    return NetworkException.fromDioError(error);
  }
}
