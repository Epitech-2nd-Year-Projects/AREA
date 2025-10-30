import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  static NetworkException fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException("Connection Timeout");
      case DioExceptionType.receiveTimeout:
        return NetworkException("Receive Timeout");
      case DioExceptionType.sendTimeout:
        return NetworkException("Send Timeout");
      case DioExceptionType.badResponse:
        return NetworkException("Bad response: ${error.response?.statusCode}");
      case DioExceptionType.cancel:
        return NetworkException("Request Cancelled");
      default:
        return NetworkException("Unexpected error: ${error.message}");
    }
  }

  @override
  String toString() => "NetworkException: $message";
}
