class RegisterResponseModel {
  final DateTime expiresAt;

  const RegisterResponseModel({
    required this.expiresAt,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}