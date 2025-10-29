import 'package:flutter_test/flutter_test.dart';
import 'package:area/core/services/logo_service.dart';

void main() {
  group('LogoService', () {
    test('returns correct logo URL with token', () {
      final url = LogoService.getLogoUrl('GitHub');
      expect(url, contains('https://img.logo.dev'));
      expect(url, contains('github.com'));
      expect(url, contains('token='));
    });

    test('normalizes common service names to domains', () {
      expect(LogoService.getLogoUrl('GitHub'), contains('github.com'));
      expect(LogoService.getLogoUrl('Google'), contains('google.com'));
      expect(LogoService.getLogoUrl('Discord'), contains('discord.com'));
      expect(LogoService.getLogoUrl('Slack'), contains('slack.com'));
      expect(LogoService.getLogoUrl('Stripe'), contains('stripe.com'));
      expect(LogoService.getLogoUrl('Twitch'), contains('twitch.tv'));
      expect(LogoService.getLogoUrl('YouTube'), contains('youtube.com'));
    });

    test('handles case insensitivity', () {
      final url1 = LogoService.getLogoUrl('github');
      final url2 = LogoService.getLogoUrl('GITHUB');
      final url3 = LogoService.getLogoUrl('GitHub');
      
      expect(url1, contains('github.com'));
      expect(url2, contains('github.com'));
      expect(url3, contains('github.com'));
    });

    test('defaults to .com for unknown services', () {
      final url = LogoService.getLogoUrl('UnknownService');
      expect(url, contains('unknownservice.com'));
    });
  });
}