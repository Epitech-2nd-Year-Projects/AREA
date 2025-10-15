import 'package:area/core/network/interceptors/logging_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class TestRequestHandler extends RequestInterceptorHandler {
  bool called = false;
  @override
  void next(RequestOptions options) {
    called = true;
  }
}

class TestResponseHandler extends ResponseInterceptorHandler {
  bool called = false;
  @override
  void next(Response response) {
    called = true;
  }
}

class TestErrorHandler extends ErrorInterceptorHandler {
  bool called = false;
  @override
  void next(DioException err) {
    called = true;
  }
}

void main() {
  group('LoggingInterceptor', () {
    late LoggingInterceptor interceptor;
    late RequestOptions options;

    setUp(() {
      interceptor = LoggingInterceptor();
      options = RequestOptions(path: '/unit-test', method: 'GET');
    });

    test('onRequest logs without throwing', () {
      final handler = TestRequestHandler();

      interceptor.onRequest(options, handler);

      expect(handler.called, isTrue);
    });

    test('onResponse logs without throwing', () {
      final response = Response(
        requestOptions: options,
        data: {'ok': true},
        statusCode: 200,
      );
      final handler = TestResponseHandler();

      interceptor.onResponse(response, handler);
      expect(handler.called, isTrue);
    });

    test('onError logs without throwing', () {
      final dioError = DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
        message: 'Internal Error',
      );
      final handler = TestErrorHandler();

      interceptor.onError(dioError, handler);

      expect(handler.called, isTrue);
    });
  });
}