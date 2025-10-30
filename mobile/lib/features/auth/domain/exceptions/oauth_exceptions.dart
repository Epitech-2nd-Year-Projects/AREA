class OAuthException implements Exception {
  final String message;
  OAuthException(this.message);

  @override
  String toString() => 'OAuthException: $message';
}

class UnsupportedProviderException extends OAuthException {
  UnsupportedProviderException(String provider)
    : super("OAuth provider not supported: $provider");
}

class InvalidRedirectUrlException extends OAuthException {
  InvalidRedirectUrlException(String url)
    : super("Invalid OAuth redirect URL: $url");
}

class OAuthFlowFailedException extends OAuthException {
  OAuthFlowFailedException([String reason = "Unknown"])
    : super("OAuth login flow failed: $reason");
}

class CallbackErrorException extends OAuthException {
  CallbackErrorException([String reason = "Unknown"])
    : super("OAuth callback error: $reason");
}
