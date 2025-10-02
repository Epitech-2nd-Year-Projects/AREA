import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/oauth_provider.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../../domain/value_objects/oauth_redirect_url.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../../../core/network/exceptions/unauthorized_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<User> register(Email email, Password password) async {
    try {
      final _ = await _remoteDataSource.register(
        email.value,
        password.value,
      );
      return User(
        id: 'pending-verification',
        email: email.value,
      );
    } on UserAlreadyExistsException {
      rethrow;
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  @override
  Future<User> login(Email email, Password password) async {
    try {
      final response = await _remoteDataSource.login(
        email.value,
        password.value,
      );
      final user = response.user.toDomain();
      await _localDataSource.cacheUser(response.user);
      return user;
    } on InvalidCredentialsException {
      rethrow;
    } on AccountNotVerifiedException {
      rethrow;
    } on UnauthorizedException {
      throw InvalidCredentialsException();
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } finally {
      await _localDataSource.clearCache();
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      final user = userModel.toDomain();

      await _localDataSource.cacheUser(userModel);

      return user;
    } on UnauthorizedException {
      await _localDataSource.clearCache();
      throw UserNotAuthenticatedException();
    } catch (e) {
      final cachedUser = await _localDataSource.getCachedUser();
      if (cachedUser != null) {
        return cachedUser.toDomain();
      }
      throw UserNotAuthenticatedException();
    }
  }

  @override
  Future<User> verifyEmail(String token) async {
    try {
      final response = await _remoteDataSource.verifyEmail(token);
      final user = response.user.toDomain();

      await _localDataSource.cacheUser(response.user);

      return user;
    } on TokenExpiredException {
      rethrow;
    } catch (e) {
      throw AuthException('Email verification failed: $e');
    }
  }

  @override
  Future<OAuthRedirectUrl> startOAuthLogin(OAuthProvider provider) async {
    throw UnimplementedError('OAuth not yet implemented');
  }

  @override
  Future<AuthSession> completeOAuthLogin(
      OAuthProvider provider,
      String callbackCode,
      ) async {
    throw UnimplementedError('OAuth not yet implemented');
  }
}