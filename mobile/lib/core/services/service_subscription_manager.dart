import 'package:flutter/foundation.dart';
import '../../features/services/domain/repositories/services_repository.dart';
import '../../features/services/domain/use_cases/complete_service_subscription.dart';

class ServiceSubscriptionManager {
  static final ServiceSubscriptionManager _instance =
  ServiceSubscriptionManager._internal();

  factory ServiceSubscriptionManager() => _instance;
  ServiceSubscriptionManager._internal();

  final Map<String, _PendingSubscription> _pendingSubscriptions = {};

  final Map<String, _PendingCallback> _pendingCallbacks = {};

  Function(String serviceId)? onSuccess;
  Function(String error)? onError;

  void setupSubscription({
    required String serviceId,
    required String? codeVerifier,
    required String? redirectUri,
    required String? state,
  }) {
    _pendingSubscriptions[serviceId] = _PendingSubscription(
      serviceId: serviceId,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
      state: state,
    );
    debugPrint('✅ Subscription setup for $serviceId');

    if (_pendingCallbacks.containsKey(serviceId)) {
      final pending = _pendingCallbacks.remove(serviceId)!;
      debugPrint('⭐ Processing pending callback for $serviceId');
      _processPendingCallback(serviceId, pending);
    }
  }

  void handleCallbackReceived({
    required String serviceId,
    required String code,
    required String? state,
    required ServicesRepository repository,
  }) {
    final subscription = _pendingSubscriptions[serviceId];

    if (subscription == null) {
      debugPrint('⭐ Callback received but subscription not setup yet - storing');
      _pendingCallbacks[serviceId] = _PendingCallback(
        code: code,
        state: state,
        timestamp: DateTime.now(),
      );
      return;
    }

    debugPrint('🔄 Completing subscription for $serviceId (from callback)');
    _completeSubscriptionNow(
      serviceId: serviceId,
      code: code,
      subscription: subscription,
      repository: repository,
    );
  }

  void _processPendingCallback(String serviceId, _PendingCallback callback) {
    final subscription = _pendingSubscriptions[serviceId];
    if (subscription == null) {
      debugPrint('❌ Subscription already cleared');
      return;
    }

    debugPrint('⭐ Pending callback ready to be processed');
  }

  Future<void> completeSubscription({
    required String serviceId,
    required String code,
    required ServicesRepository repository,
  }) async {
    try {
      final pending = _pendingSubscriptions[serviceId];

      if (pending == null) {
        debugPrint('❌ No pending subscription found for $serviceId');
        onError?.call('Subscription session expired');
        return;
      }

      debugPrint('🔄 Completing subscription for $serviceId');
      debugPrint('   Code: ${code.substring(0, 10)}...');
      debugPrint('   Code verifier: ${pending.codeVerifier?.substring(0, 10)}...');
      debugPrint('   Redirect URI: ${pending.redirectUri}');

      final completeUseCase = CompleteServiceSubscription(repository);

      final result = await completeUseCase(
        serviceId: serviceId,
        code: code,
        codeVerifier: pending.codeVerifier,
        redirectUri: pending.redirectUri,
      );

      result.fold(
            (failure) {
          debugPrint('❌ Subscription failed: ${failure.message}');
          onError?.call(failure.message);
        },
            (subscriptionResult) {
          debugPrint('✅ Subscription completed for $serviceId');
          _pendingSubscriptions.remove(serviceId);
          onSuccess?.call(serviceId);
        },
      );
    } catch (e) {
      debugPrint('❌ Error completing subscription: $e');
      onError?.call(e.toString());
    }
  }

  void _completeSubscriptionNow({
    required String serviceId,
    required String code,
    required _PendingSubscription subscription,
    required ServicesRepository repository,
  }) async {
    try {
      debugPrint('🔄 Completing subscription (from pending)');
      final completeUseCase = CompleteServiceSubscription(repository);

      final result = await completeUseCase(
        serviceId: serviceId,
        code: code,
        codeVerifier: subscription.codeVerifier,
        redirectUri: subscription.redirectUri,
      );

      result.fold(
            (failure) {
          debugPrint('❌ Subscription failed: ${failure.message}');
          onError?.call(failure.message);
        },
            (subscriptionResult) {
          debugPrint('✅ Subscription completed for $serviceId');
          _pendingSubscriptions.remove(serviceId);
          onSuccess?.call(serviceId);
        },
      );
    } catch (e) {
      debugPrint('❌ Error: $e');
      onError?.call(e.toString());
    }
  }

  _PendingSubscription? getPendingSubscription(String serviceId) {
    return _pendingSubscriptions[serviceId];
  }

  void clearSubscription(String serviceId) {
    _pendingSubscriptions.remove(serviceId);
    _pendingCallbacks.remove(serviceId);
  }

  void dispose() {
    _pendingSubscriptions.clear();
    _pendingCallbacks.clear();
    onSuccess = null;
    onError = null;
  }
}

class _PendingSubscription {
  final String serviceId;
  final String? codeVerifier;
  final String? redirectUri;
  final String? state;

  _PendingSubscription({
    required this.serviceId,
    required this.codeVerifier,
    required this.redirectUri,
    required this.state,
  });
}

class _PendingCallback {
  final String code;
  final String? state;
  final DateTime timestamp;

  _PendingCallback({
    required this.code,
    required this.state,
    required this.timestamp,
  });
}