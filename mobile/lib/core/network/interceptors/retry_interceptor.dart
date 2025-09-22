import 'package:dio/dio.dart';
import 'dart:math';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  int _retryCount = 0;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err) && _retryCount < maxRetries) {
      _retryCount++;
      final delay = pow(2, _retryCount).toInt();
      await Future.delayed(Duration(seconds: delay));
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        super.onError(err, handler);
      }
    } else {
      super.onError(err, handler);
    }
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout;
  }
}