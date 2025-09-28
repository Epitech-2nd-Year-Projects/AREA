import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/repositories/services_repository.dart';
import '../../../domain/use_cases/subscribe_to_service.dart';
import '../../../domain/use_cases/unsubscribe_from_service.dart';
import 'service_subscription_state.dart';

class ServiceSubscriptionCubit extends Cubit<ServiceSubscriptionState> {
  late final SubscribeToService _subscribeToService;
  late final UnsubscribeFromService _unsubscribeFromService;

  ServiceSubscriptionCubit(ServicesRepository repository)
      : super(ServiceSubscriptionInitial()) {
    _subscribeToService = SubscribeToService(repository);
    _unsubscribeFromService = UnsubscribeFromService(repository);
  }

  Future<void> subscribe({
    required String serviceId,
    List<String>? requestedScopes,
  }) async {
    emit(ServiceSubscriptionLoading());

    final result = await _subscribeToService(
      serviceId: serviceId,
      requestedScopes: requestedScopes ?? [],
    );

    result.fold(
          (failure) => emit(ServiceSubscriptionError(_mapFailureToMessage(failure))),
          (subscription) => emit(ServiceSubscriptionSuccess(subscription)),
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
}