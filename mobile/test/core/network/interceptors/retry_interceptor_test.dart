import 'package:area/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fake_async/fake_async.dart';


class MockDio extends Mock implements Dio {}

class RequestOptionsFake extends Fake implements RequestOptions {}

class FakeHandler extends Fake implements ErrorInterceptorHandler {
  bool resolved = false;
  bool nextCalled = false;
  late Response response;

  @override
  void resolve(Response r) {
    resolved = true;
    response = r;
  }

  @override
  void next(DioException err) {
    nextCalled = true;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptionsFake());
  });

  group('RetryInterceptor (fast fake time)', () {
    late RetryInterceptor interceptor;
    late MockDio mockDio;
    late RequestOptions options;

    setUp(() {
      mockDio = MockDio();
      interceptor = RetryInterceptor(dio: mockDio, maxRetries: 2);
      options = RequestOptions(path: '/test');
    });

    DioException makeError(DioExceptionType type) =>
        DioException(requestOptions: options, type: type);

    test('retries on connectionError until success immediately', () {
      fakeAsync((async) {
        final handler = FakeHandler();

        final successResponse = Response(
          requestOptions: options,
          statusCode: 200,
          data: {'ok': true},
        );

        when(() => mockDio.fetch(any()))
            .thenAnswer((_) async => successResponse);

        interceptor.onError(
            makeError(DioExceptionType.connectionError), handler);

        async.elapse(const Duration(seconds: 5));

        expect(handler.resolved, isTrue);
        expect(handler.response.statusCode, 200);
      });
    });

    test('stops retrying after maxRetries when errors persist', () {
      fakeAsync((async) {
        final handler = FakeHandler();
        final err = makeError(DioExceptionType.connectionError);

        when(() => mockDio.fetch(any())).thenThrow(err);

        interceptor.onError(err, handler);

        async.elapse(const Duration(seconds: 10));

        expect(handler.resolved, isFalse);
        expect(handler.nextCalled, isTrue);
      });
    });

    test('does not retry for non-retryable DioExceptionType', () {
      fakeAsync((async) {
        final handler = FakeHandler();
        final nonRetryable = makeError(DioExceptionType.badResponse);

        interceptor.onError(nonRetryable, handler);

        async.elapse(const Duration(seconds: 1));

        expect(handler.resolved, isFalse);
        expect(handler.nextCalled, isTrue);
      });
    });
  });
}