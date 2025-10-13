import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/di/injector.dart';
import '../../../../../core/services/oauth_manager.dart';
import '../../../domain/entities/oauth_provider.dart';
import 'oauth_state.dart';

class OAuthCubit extends Cubit<OAuthState> {
  final OAuthManager _oauthManager = sl<OAuthManager>();

  OAuthCubit() : super(OAuthInitial()) {
    _setupOAuthCallbacks();
  }

  void _setupOAuthCallbacks() {
    _oauthManager.onSuccess = (user) {
      if (!isClosed) {
        emit(OAuthSuccess(user));
      }
    };

    _oauthManager.onError = (error) {
      if (!isClosed) {
        emit(OAuthError(error));
      }
    };
  }

  Future<void> startOAuth(OAuthProvider provider, {String? returnTo}) async {
    try {
      emit(OAuthLoading());

      final authorizationUrl = await _oauthManager.startOAuth(
        provider,
        returnTo: returnTo,
      );

      if (!isClosed) {
        emit(OAuthRedirectReady(authorizationUrl, returnTo: returnTo));
      }

      final uri = Uri.parse(authorizationUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!isClosed) {
        emit(OAuthError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _oauthManager.onSuccess = null;
    _oauthManager.onError = null;
    return super.close();
  }
}