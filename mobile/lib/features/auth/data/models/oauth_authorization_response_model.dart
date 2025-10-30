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
    final url = json['authorizationUrl'] ?? json['authorization_url'];
    if (url == null || url is! String) {
      throw Exception('Invalid OAuth authorization response: $json');
    }

    return OAuthAuthorizationResponseModel(
      authorizationUrl: url,
      state: json['state'] as String?,
      codeVerifier: (json['codeVerifier'] ?? json['code_verifier']) as String?,
      codeChallenge:
          (json['codeChallenge'] ?? json['code_challenge']) as String?,
      codeChallengeMethod:
          (json['codeChallengeMethod'] ?? json['code_challenge_method'])
              as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorizationUrl': authorizationUrl,
      if (state != null) 'state': state,
      if (codeVerifier != null) 'codeVerifier': codeVerifier,
      if (codeChallenge != null) 'codeChallenge': codeChallenge,
      if (codeChallengeMethod != null)
        'codeChallengeMethod': codeChallengeMethod,
    };
  }
}
