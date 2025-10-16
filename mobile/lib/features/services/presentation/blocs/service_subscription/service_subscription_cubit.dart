import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/di/injector.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/services/deep_link_service.dart';
import '../../../../../core/services/local_oauth_server.dart';
import '../../../../../core/services/service_subscription_manager.dart';
import '../../../domain/entities/service_subscription_result.dart';
import '../../../domain/repositories/services_repository.dart';
import '../../../domain/use_cases/subscribe_to_service.dart';
import '../../../domain/use_cases/unsubscribe_from_service.dart';
import 'service_subscription_state.dart';

class ServiceSubscriptionCubit extends Cubit<ServiceSubscriptionState> {
  final DeepLinkService _deepLinkService;
  final ServiceSubscriptionManager _manager;
  final LocalOAuthServer _localServer = LocalOAuthServer();
  final Random _random;

  late final SubscribeToService _subscribeToService;
  late final UnsubscribeFromService _unsubscribeFromService;

  ServiceSubscriptionCubit(
      ServicesRepository repository, {
        DeepLinkService? deepLinkService,
        Random? random,
      })  : _deepLinkService = deepLinkService ?? DeepLinkService(),
        _manager = ServiceSubscriptionManager(),
        _random = _createRandom(random),
        super(ServiceSubscriptionInitial()) {
    unawaited(_deepLinkService.initialize());
    _subscribeToService = SubscribeToService(repository);
    _unsubscribeFromService = UnsubscribeFromService(repository);

    _deepLinkService.addServiceCallbackListener(_handleServiceCallback);
    _deepLinkService.addServiceErrorListener(_handleServiceError);

    _setupManager(repository);
  }

  void _setupManager(ServicesRepository repository) {
    _manager.onSuccess = (serviceId) {
      if (!isClosed) {
        emit(const ServiceSubscriptionSuccess(null));
      }
    };

    _manager.onError = (error) {
      if (!isClosed) {
        emit(ServiceSubscriptionError(error));
      }
    };
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

      // Stocker les données pour le callback
      _manager.setupSubscription(
        serviceId: provider,
        codeVerifier: authorization.codeVerifier,
        redirectUri: _extractRedirectUri(authorization.authorizationUrl),
        state: authorization.state,
      );

      // Démarrer le serveur local
      await _localServer.start().catchError((e) {
        debugPrint('⚠️ Could not start local server: $e');
      });

      final launchUri = Uri.tryParse(authorization.authorizationUrl);
      if (launchUri == null) {
        emit(const ServiceSubscriptionError('Invalid authorization URL provided.'));
        return;
      }

      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
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

  // ⭐ NOUVEAU: Callback pour les services
  void _handleServiceCallback(
      String provider,
      String code,
      String? state,
      ) async {
    debugPrint('🔄 Service callback received for $provider');

    final normalizedProvider = _normalizeProvider(provider);
    final pending = _manager.getPendingSubscription(normalizedProvider);

    if (pending == null) {
      debugPrint('⚠️ No pending subscription found');
      return;
    }

    if (isClosed) {
      debugPrint('⚠️ Cubit is closed');
      return;
    }

    emit(ServiceSubscriptionLoading());

    // Obtenir le repository depuis l'injector
    final repository = sl<ServicesRepository>();

    // Compléter la subscription
    await _manager.completeSubscription(
      serviceId: normalizedProvider,
      code: code,
      repository: repository,
    );
  }

  void _handleServiceError(String? provider, String error) {
    if (provider == null) return;

    final normalizedProvider = _normalizeProvider(provider);
    _manager.clearSubscription(normalizedProvider);

    if (!isClosed) {
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
    _deepLinkService.removeServiceCallbackListener(_handleServiceCallback);
    _deepLinkService.removeServiceErrorListener(_handleServiceError);
    _manager.dispose();
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