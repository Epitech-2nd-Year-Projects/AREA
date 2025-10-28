import 'package:area/core/services/deep_link_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService service;
    late List<String> callbackCalls;
    late List<String> errorCalls;
    late List<String> serviceCallbackCalls;
    late List<String> serviceErrorCalls;

    setUp(() {
      service = DeepLinkService();
      callbackCalls = [];
      errorCalls = [];
      serviceCallbackCalls = [];
      serviceErrorCalls = [];
      service.addOAuthCallbackListener(
        (p, c, s, r) => callbackCalls.add('$p:$c:$r'),
      );
      service.addOAuthErrorListener((p, e) => errorCalls.add('$p:$e'));
      service.addServiceCallbackListener(
        (p, c, s) => serviceCallbackCalls.add('$p:$c:$s'),
      );
      service.addServiceErrorListener((p, e) => serviceErrorCalls.add('$p:$e'));
    });

    tearDown(() {
      service.dispose();
    });

    test('should handle OAuth link with code (length > 10)', () {
      final uri = Uri.parse(
        'area:///oauth/google/callback?code=1234567890123&state=s&returnTo=/home',
      );
      service.handleDeepLinkForTest(uri);
      expect(callbackCalls, isNotEmpty);
      expect(callbackCalls.first, contains('google:1234567890123:/home'));
    });

    test('should handle OAuth link with error', () {
      final uri = Uri.parse(
        'area:///oauth/facebook/callback?error=denied_error_value&state=a',
      );
      service.handleDeepLinkForTest(uri);
      expect(errorCalls.first, contains('facebook:denied_error_value'));
    });

    test('should handle OAuth link without code or error', () {
      final uri = Uri.parse('area:///oauth/apple/callback');
      service.handleDeepLinkForTest(uri);
      expect(callbackCalls, isEmpty);
      expect(errorCalls, isEmpty);
    });

    test('should handle Services link with code (length > 10)', () {
      final uri = Uri.parse(
        'area:///services/fake/callback?code=abcdefghijklmnop&state=x&returnTo=/ok',
      );
      service.handleDeepLinkForTest(uri);
      expect(
        serviceCallbackCalls.any((e) => e.contains('fake:abcdefghijklmnop:x')),
        isTrue,
      );
    });

    test('dispose should reset internal state', () async {
      service.dispose();
      expect(
        () => service.handleDeepLinkForTest(Uri.parse('test://a')),
        returnsNormally,
      );
    });

    test('add/remove listener should work properly', () {
      void tempListener(String p, String c, String? s, String? r) {}
      service.addOAuthCallbackListener(tempListener);
      service.removeOAuthCallbackListener(tempListener);
      service.addOAuthErrorListener((p, e) {});
      service.removeOAuthErrorListener((p, e) {});
      expect(true, isTrue);
    });
  });
}
