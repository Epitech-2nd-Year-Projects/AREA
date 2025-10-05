import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/services/oauth_manager.dart';
import '../../../domain/entities/oauth_provider.dart';
import '../../../domain/exceptions/oauth_exceptions.dart';
import 'oauth_state.dart';

class OAuthCubit extends Cubit<OAuthState> {
  final OAuthManager _oauthManager;
  bool _isDisposed = false;

  OAuthCubit()
      : _oauthManager = sl<OAuthManager>(),
        super(OAuthInitial()) {
    _oauthManager.onSuccess = (user) {
      if (!_isDisposed && !isClosed) {
        emit(OAuthSuccess(user));
      }
    };
    _oauthManager.onError = (error) {
      if (!_isDisposed && !isClosed) {
        emit(OAuthError(error));
      }
    };
  }

  Future<void> startOAuth(OAuthProvider provider) async {
    if (_isDisposed || isClosed) return;

    try {
      emit(OAuthStarting(provider));

      final authUrl = await _oauthManager.startOAuth(provider);
      final url = Uri.parse(authUrl);

      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        emit(OAuthError('Could not launch OAuth URL'));
        return;
      }

      if (!_isDisposed && !isClosed) {
        emit(OAuthWaitingForCallback(provider));
      }
    } on OAuthException catch (e) {
      if (!_isDisposed && !isClosed) {
        emit(OAuthError(e.message));
      }
    } catch (e) {
      if (!_isDisposed && !isClosed) {
        emit(OAuthError('Failed to start OAuth: $e'));
      }
    }
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    _oauthManager.onSuccess = null;
    _oauthManager.onError = null;
    return super.close();
  }
}