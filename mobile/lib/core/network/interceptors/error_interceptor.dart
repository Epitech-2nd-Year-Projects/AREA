import 'package:dio/dio.dart';
import '../exceptions/network_exceptions.dart';
import '../exceptions/unauthorized_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: UnauthorizedException("Unauthorized - login required"),
      ));
      return;
    }

    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: NetworkException.fromDioError(err),
    ));
  }
}