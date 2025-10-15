import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/storage/storage_keys.dart';

void main() {
  group('StorageKeys', () {
    test('should have expected constants', () {
      expect(StorageKeys.authToken, 'auth_token');
      expect(StorageKeys.refreshToken, 'refresh_token');
      expect(StorageKeys.baseUrl, 'base_url');
      expect(StorageKeys.theme, 'theme_mode');
      expect(StorageKeys.language, 'language');
      expect(StorageKeys.userProfile, 'user_profile');
    });
  });
}