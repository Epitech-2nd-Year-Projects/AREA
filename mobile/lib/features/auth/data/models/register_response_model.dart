class RegisterResponseModel {
  final DateTime expiresAt;

  const RegisterResponseModel({
    required this.expiresAt,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}