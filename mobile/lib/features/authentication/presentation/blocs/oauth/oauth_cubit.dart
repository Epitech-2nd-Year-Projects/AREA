import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/start_oauth_login.dart';
import '../../../domain/use_cases/complete_oauth_login.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/entities/oauth_provider.dart';
import '../../../domain/exceptions/oauth_exceptions.dart';
import 'oauth_state.dart';

class OAuthCubit extends Cubit<OAuthState> {
  late final StartOAuthLogin _startOAuthLogin;
  late final CompleteOAuthLogin _completeOAuthLogin;

  OAuthCubit(AuthRepository repository) : super(OAuthInitial()) {
    _startOAuthLogin = StartOAuthLogin(repository);
    _completeOAuthLogin = CompleteOAuthLogin(repository);
  }

  Future<void> startOAuth(OAuthProvider provider) async {
    try {
      emit(OAuthStarting(provider));
      final redirectUrl = await _startOAuthLogin(provider);
      emit(OAuthRedirectReady(provider, redirectUrl));
    } on OAuthException catch (e) {
      emit(OAuthError(e.message));
    } catch (_) {
      emit(OAuthError('Failed to start OAuth login'));
    }
  }

  Future<void> handleCallback(OAuthProvider provider, String code) async {
    try {
      emit(OAuthCallbackReceived(provider, code));
      final session = await _completeOAuthLogin(provider, code);
      emit(OAuthSuccess(session));
    } on OAuthException catch (e) {
      emit(OAuthError(e.message));
    } catch (_) {
      emit(OAuthError('OAuth callback failed'));
    }
  }
}