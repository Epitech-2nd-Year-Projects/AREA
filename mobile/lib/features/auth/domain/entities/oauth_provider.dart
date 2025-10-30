enum OAuthProvider {
  google,
  apple,
  facebook;

  String get slug {
    switch (this) {
      case OAuthProvider.google:
        return 'google';
      case OAuthProvider.apple:
        return 'apple';
      case OAuthProvider.facebook:
        return 'facebook';
    }
  }
}
