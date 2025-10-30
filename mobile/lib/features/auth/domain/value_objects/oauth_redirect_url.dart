import '../exceptions/oauth_exceptions.dart';

class OAuthRedirectUrl {
  final String url;

  OAuthRedirectUrl._(this.url);

  factory OAuthRedirectUrl(String input) {
    if (!_isValidUrl(input)) {
      throw InvalidRedirectUrlException(input);
    }
    return OAuthRedirectUrl._(input);
  }

  static bool _isValidUrl(String url) {
    Uri? parsed;
    try {
      parsed = Uri.parse(url);
    } catch (_) {
      return false;
    }
    return parsed.hasScheme && parsed.hasAuthority;
  }

  @override
  String toString() => url;
}
