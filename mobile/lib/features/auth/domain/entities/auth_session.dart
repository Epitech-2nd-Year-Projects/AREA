import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthSession extends Equatable {
  final User user;
  final DateTime expiresAt;
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;

  const AuthSession({
    required this.user,
    required this.expiresAt,
    this.accessToken,
    this.refreshToken,
    this.tokenType,
  });

  // Constructor spécifique pour les logins classiques (email/password)
  const AuthSession.withTokens({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  }) : tokenType = 'bearer';

  const AuthSession.fromOAuth({
    required this.user,
    required this.expiresAt,
    this.tokenType = 'session',
  })  : accessToken = null,
        refreshToken = null;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get hasAccessToken => accessToken != null && accessToken!.isNotEmpty;

  bool get hasRefreshToken =>
      refreshToken != null && refreshToken!.isNotEmpty;

  @override
  List<Object?> get props => [
    user,
    expiresAt,
    accessToken,
    refreshToken,
    tokenType,
  ];
}