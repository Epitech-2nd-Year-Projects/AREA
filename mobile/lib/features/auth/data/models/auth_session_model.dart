import '../../domain/entities/auth_session.dart';
import 'user_model.dart';

class AuthSessionModel {
  final UserModel user;
  final DateTime expiresAt;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  const AuthSessionModel({
    required this.user,
    required this.expiresAt,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
  });

  factory AuthSessionModel.fromOAuthJson(
    Map<String, dynamic> json,
    UserModel user,
  ) {
    DateTime expiresAt;

    if (json.containsKey('expiresAt') && json['expiresAt'] != null) {
      expiresAt = DateTime.parse(json['expiresAt'] as String);
    } else {
      expiresAt = DateTime.now().add(const Duration(days: 7));
    }

    return AuthSessionModel(
      user: user,
      expiresAt: expiresAt,
      tokenType: json['tokenType'] as String? ?? 'session',
      accessToken: null,
      refreshToken: null,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
      if (accessToken != null) 'accessToken': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (tokenType != null) 'tokenType': tokenType,
    };
  }

  AuthSession toDomain() {
    if (accessToken != null && refreshToken != null) {
      return AuthSession.withTokens(
        user: user.toDomain(),
        accessToken: accessToken!,
        refreshToken: refreshToken!,
        expiresAt: expiresAt,
      );
    } else {
      return AuthSession.fromOAuth(
        user: user.toDomain(),
        expiresAt: expiresAt,
        tokenType: tokenType ?? 'session',
      );
    }
  }
}
