import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/services/deep_link_service.dart';
import '../../../../../core/services/local_oauth_server.dart';
import '../../../domain/entities/service_subscription_result.dart';
import '../../../domain/repositories/services_repository.dart';
import '../../../domain/use_cases/complete_service_subscription.dart';
import '../../../domain/use_cases/subscribe_to_service.dart';
import '../../../domain/use_cases/unsubscribe_from_service.dart';
import 'service_subscription_state.dart';

class ServiceSubscriptionCubit extends Cubit<ServiceSubscriptionState> {
  final DeepLinkService _deepLinkService;
  final Random _random;
  late final SubscribeToService _subscribeToService;
  late final UnsubscribeFromService _unsubscribeFromService;
  late final CompleteServiceSubscription _completeServiceSubscription;
  final Map<String, _PendingSubscriptionAuthorization> _pendingAuthorizations = {};

  ServiceSubscriptionCubit(
      ServicesRepository repository, {
        DeepLinkService? deepLinkService,
        Random? random,
      })  : _deepLinkService = deepLinkService ?? DeepLinkService(),
        _random = _createRandom(random),
        super(ServiceSubscriptionInitial()) {
    unawaited(_deepLinkService.initialize());
    _subscribeToService = SubscribeToService(repository);
    _unsubscribeFromService = UnsubscribeFromService(repository);
    _completeServiceSubscription = CompleteServiceSubscription(repository);

    _deepLinkService.addOAuthCallbackListener(_handleOAuthCallback);
    _deepLinkService.addOAuthErrorListener(_handleOAuthError);
  }

  Future<void> subscribe({
    required String serviceId,
    List<String>? requestedScopes,
  }) async {
    emit(ServiceSubscriptionLoading());

    final normalizedProvider = _normalizeProvider(serviceId);
    final clientState = _generateClientState(normalizedProvider);

    final result = await _subscribeToService(
      serviceId: serviceId,
      requestedScopes: requestedScopes ?? const [],
      state: clientState,
      usePkce: true,
    );

    await result.fold(
          (failure) async {
        emit(ServiceSubscriptionError(_mapFailureToMessage(failure)));
      },
          (subscriptionResult) async {
        await _handleSubscriptionResult(
          normalizedProvider,
          subscriptionResult,
        );
      },
    );
  }

  Future<void> unsubscribe(String subscriptionId) async {
    emit(ServiceSubscriptionLoading());

    final result = await _unsubscribeFromService(subscriptionId);

    result.fold(
          (failure) => emit(ServiceSubscriptionError(_mapFailureToMessage(failure))),
          (_) => emit(ServiceUnsubscribed()),
    );
  }

  Future<void> _handleSubscriptionResult(
      String provider,
      ServiceSubscriptionResult result,
      ) async {
    if (result.requiresAuthorization) {
      final authorization = result.authorization;
      if (authorization == null) {
        emit(const ServiceSubscriptionError(
          'Subscription requires authorization but no details were provided.',
        ));
        return;
      }

      _pendingAuthorizations[provider] = _PendingSubscriptionAuthorization(
        provider: provider,
        codeVerifier: authorization.codeVerifier,
        redirectUri: _extractRedirectUri(authorization.authorizationUrl),
        state: authorization.state,
      );

      final localServer = LocalOAuthServer();
      await localServer.start().catchError((e) {
        debugPrint('⚠️ Could not start local server: $e');
      });

      final launchUri = Uri.tryParse(authorization.authorizationUrl);
      if (launchUri == null) {
        _pendingAuthorizations.remove(provider);
        emit(const ServiceSubscriptionError('Invalid authorization URL provided.'));
        return;
      }

      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _pendingAuthorizations.remove(provider);
        emit(const ServiceSubscriptionError('Unable to open authorization screen.'));
        return;
      }

      emit(ServiceSubscriptionAwaitingAuthorization(authorization));
      return;
    }

    final subscription = result.subscription;
    if (subscription != null) {
      emit(ServiceSubscriptionSuccess(subscription));
      return;
    }

    emit(const ServiceSubscriptionError('Subscription flow did not return a result.'));
  }

  void _handleOAuthCallback(
      String provider,
      String code,
      String? state,
      String? returnTo,
      ) async {
    final normalizedProvider = _normalizeProvider(provider);
    final pending = _pendingAuthorizations[normalizedProvider];
    if (pending == null) {
      return;
    }

    if (pending.state != null && state != null && pending.state != state) {
      return;
    }

    if (isClosed) {
      debugPrint('⚠️ Cubit is closed, ignoring callback');
      return;
    }

    emit(ServiceSubscriptionLoading());

    final exchange = await _completeServiceSubscription(
      serviceId: normalizedProvider,
      code: code,
      codeVerifier: pending.codeVerifier,
      redirectUri: pending.redirectUri,
    );

    _pendingAuthorizations.remove(normalizedProvider);

    if (!isClosed) {
      exchange.fold(
            (failure) => emit(ServiceSubscriptionError(_mapFailureToMessage(failure))),
            (result) => emit(ServiceSubscriptionSuccess(result.subscription)),
      );
    }
    exchange.fold(
          (failure) => emit(ServiceSubscriptionError(_mapFailureToMessage(failure))),
          (result) => emit(ServiceSubscriptionSuccess(result.subscription)),
    );
  }

  void _handleOAuthError(String? provider, String error) {
    if (provider == null) return;

    final normalizedProvider = _normalizeProvider(provider);
    if (_pendingAuthorizations.containsKey(normalizedProvider)) {
      _pendingAuthorizations.remove(normalizedProvider);
      emit(ServiceSubscriptionError(error));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure _:
        return 'Network error. Please check your connection.';
      case UnauthorizedFailure _:
        return 'Please log in to manage subscriptions.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _generateClientState(String provider) {
    final nonce = _random.nextInt(0x7fffffff);
    return 'area:$provider:$nonce:${DateTime.now().millisecondsSinceEpoch}';
  }

  String? _extractRedirectUri(String authorizationUrl) {
    try {
      final uri = Uri.parse(authorizationUrl);
      return uri.queryParameters['redirect_uri'];
    } catch (_) {
      return null;
    }
  }

  String _normalizeProvider(String provider) {
    return provider.toLowerCase().replaceAll(' ', '_');
  }

  @override
  Future<void> close() {
    _deepLinkService.removeOAuthCallbackListener(_handleOAuthCallback);
    _deepLinkService.removeOAuthErrorListener(_handleOAuthError);
    _pendingAuthorizations.clear();
    return super.close();
  }

  static Random _createRandom(Random? seed) {
    if (seed != null) {
      return seed;
    }
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }
}

class _PendingSubscriptionAuthorization {
  final String provider;
  final String? codeVerifier;
  final String? redirectUri;
  final String? state;

  const _PendingSubscriptionAuthorization({
    required this.provider,
    this.codeVerifier,
    this.redirectUri,
    this.state,
  });
}