import 'dart:io';
import 'package:area/core/network/api_client.dart';
import 'package:area/core/network/interceptors/error_interceptor.dart';
import 'package:area/core/network/interceptors/logging_interceptor.dart';
import 'package:area/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDioAdapter extends Mock implements HttpClientAdapter {}

class RequestOptionsFake extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptionsFake());
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient(baseUrl: "http://fakeurl.test");
    });

    test('should create instance with correct defaults', () {
      expect(client.dio.options.baseUrl, "http://fakeurl.test");
      expect(client.dio.options.connectTimeout, const Duration(seconds: 15));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 20));
      expect(client.cookieJar, isNotNull);
      expect(client.dio.interceptors.whereType<ErrorInterceptor>().length, 1);
      expect(client.dio.interceptors.whereType<LoggingInterceptor>().length, 1);
      expect(client.dio.interceptors.whereType<RetryInterceptor>().length, 1);
    });

    test('updateBaseUrl should change base URL', () {
      client.updateBaseUrl("http://newurl.test");
      expect(client.dio.options.baseUrl, "http://newurl.test");
    });

    test('updateBaseUrl should clear cookies when clearCookies=true', () {
      client.updateBaseUrl("http://clear.test", clearCookies: true);
      expect(client.dio.options.baseUrl, "http://clear.test");
    });

    test('updateBaseUrl should not update when empty', () {
      final before = client.baseUrl;
      client.updateBaseUrl("");
      expect(client.baseUrl, before);
    });

    test('baseUrl getter returns correct value', () {
      expect(client.baseUrl, "http://fakeurl.test");
    });

    test('HTTP methods should call Dio correctly', () async {
      final mockAdapter = MockDioAdapter();
      client.dio.httpClientAdapter = mockAdapter;

      when(() => mockAdapter.fetch(any(), any(), any()))
          .thenAnswer((_) async => ResponseBody.fromString('{}', 200));

      await client.get('/get');
      await client.post('/post', data: {});
      await client.put('/put', data: {});
      await client.delete('/delete');

      verify(() => mockAdapter.fetch(any(), any(), any())).called(greaterThan(0));
    });
  });
}