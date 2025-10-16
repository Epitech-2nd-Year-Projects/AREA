import 'package:area/core/network/interceptors/error_interceptor.dart';
import 'package:area/core/network/exceptions/network_exceptions.dart';
import 'package:area/core/network/exceptions/unauthorized_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHandler extends ErrorInterceptorHandler {
  bool called = false;
  late DioException captured;

  @override
  void reject(DioException err, [bool propagate = false]) {
    called = true;
    captured = err;
  }
}

void main() {
  group('ErrorInterceptor', () {
    late ErrorInterceptor interceptor;
    late RequestOptions options;

    setUp(() {
      interceptor = ErrorInterceptor();
      options = RequestOptions(path: "/test");
    });

    test('should map 401 to UnauthorizedException', () async {
      final err = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
      );
      final handler = TestHandler();

      interceptor.onError(err, handler);

      expect(handler.called, isTrue);
      expect(handler.captured.error, isA<UnauthorizedException>());
      expect(
        handler.captured.error.toString(),
        contains("Unauthorized"),
      );
    });

    test('should map others to NetworkException', () async {
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: 500),
      );
      final handler = TestHandler();

      interceptor.onError(err, handler);

      expect(handler.called, isTrue);
      expect(handler.captured.error, isA<NetworkException>());
      expect(
        handler.captured.error.toString(),
        contains("NetworkException"),
      );
    });
  });
}