import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'dart:io';

import 'api_config.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class ApiClient {
    late final Dio _dio;
    late final PersistCookieJar cookieJar;

    ApiClient({String? baseUrl}) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: ApiConfig.defaultHeaders,
        ),
      );
      cookieJar = PersistCookieJar(
        ignoreExpires: false,
        storage: FileStorage("${Directory.systemTemp.path}/cookies"),
      );
      _dio.interceptors.add(CookieManager(cookieJar));

      _dio.interceptors.addAll([
        ErrorInterceptor(),
        if (ApiConfig.enableLogging)
          LoggingInterceptor(),
        RetryInterceptor(dio: _dio),
      ]);
    }

    Dio get dio => _dio;

    Future<Response<T>> get<T>(String path,
        {Map<String, dynamic>? queryParameters}) async {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    }

    Future<Response<T>> post<T>(String path,
        {dynamic data, Map<String, dynamic>? queryParameters}) async {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters);
    }

    Future<Response<T>> put<T>(String path,
        {dynamic data, Map<String, dynamic>? queryParameters}) async {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters);
    }

    Future<Response<T>> delete<T>(String path,
        {dynamic data, Map<String, dynamic>? queryParameters}) async {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters);
    }
}