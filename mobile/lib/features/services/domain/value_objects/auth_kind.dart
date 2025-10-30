enum AuthKind {
  none('none'),
  oauth2('oauth2'),
  apikey('apikey');

  const AuthKind(this.value);
  final String value;

  static AuthKind fromString(String value) {
    return AuthKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => AuthKind.none,
    );
  }

  bool get requiresOAuth => this == AuthKind.oauth2;
  bool get requiresApiKey => this == AuthKind.apikey;
  bool get requiresAuth => this != AuthKind.none;
}
