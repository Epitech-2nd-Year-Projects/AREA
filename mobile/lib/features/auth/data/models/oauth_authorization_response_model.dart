class OAuthAuthorizationResponseModel {
  final String authorizationUrl;
  final String? state;
  final String? codeVerifier;
  final String? codeChallenge;
  final String? codeChallengeMethod;

  const OAuthAuthorizationResponseModel({
    required this.authorizationUrl,
    this.state,
    this.codeVerifier,
    this.codeChallenge,
    this.codeChallengeMethod,
  });

  factory OAuthAuthorizationResponseModel.fromJson(Map<String, dynamic> json) {
    final url = json['authorization_url'] ?? json['authorizationUrl'];
    if (url == null || url is! String) {
      throw Exception('Invalid OAuth authorization response: $json');
    }

    return OAuthAuthorizationResponseModel(
      authorizationUrl: url,
      state: json['state'] as String?,
      codeVerifier: (json['code_verifier'] ?? json['codeVerifier']) as String?,
      codeChallenge: (json['code_challenge'] ?? json['codeChallenge']) as String?,
      codeChallengeMethod: (json['code_challenge_method'] ??
          json['codeChallengeMethod']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorizationUrl': authorizationUrl,
      if (state != null) 'state': state,
      if (codeVerifier != null) 'codeVerifier': codeVerifier,
      if (codeChallenge != null) 'codeChallenge': codeChallenge,
      if (codeChallengeMethod != null)
        'code_challengeMethod': codeChallengeMethod,
    };
  }
}