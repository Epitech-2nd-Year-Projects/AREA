import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/network/api_config.dart';

void main() {
  group('ApiConfig', () {
    setUpAll(() async {
      await dotenv.load();
      ApiConfig.initialize();
    });

    test('constants should have expected values', () {
      expect(ApiConfig.baseUrl, "http://10.0.2.2:8080");
      expect(ApiConfig.defaultHeaders["Accept"], "application/json");
      expect(ApiConfig.connectTimeout, const Duration(seconds: 15));
      expect(ApiConfig.receiveTimeout, const Duration(seconds: 20));
      expect(ApiConfig.enableLogging, isTrue);
    });

    test('getOAuthCallbackUrl returns correct URL', () {
      final url = ApiConfig.getOAuthCallbackUrl("google");
      expect(url, "http://localhost:8080/oauth/google/callback");
    });

    test('getServiceCallbackUrl returns correct URL', () {
      final url = ApiConfig.getServiceCallbackUrl("discord");
      expect(url, "http://localhost:8080/services/discord/callback");
    });
  });
}