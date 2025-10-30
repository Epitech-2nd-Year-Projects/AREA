import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/domain/use_cases/get_current_user.dart';
import '../../../services/domain/use_cases/get_services_with_status.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../services/domain/repositories/services_repository.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../services/domain/entities/service_with_status.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetCurrentUser _getCurrentUser;
  final GetServicesWithStatus _getServicesWithStatus;

  ProfileCubit({
    required AuthRepository authRepository,
    required ServicesRepository servicesRepository,
  }) : _getCurrentUser = GetCurrentUser(authRepository),
       _getServicesWithStatus = GetServicesWithStatus(servicesRepository),
       super(const ProfileInitial());

  Future<void> loadProfile() async {
    emit(const ProfileLoading());
    late final User user;
    try {
      user = await _getCurrentUser();
    } catch (e) {
      emit(ProfileError('Failed to load user profile'));
      return;
    }
    String displayName = '';
    if (user.email.isNotEmpty) {
      displayName = user.email.split('@')[0];
    }
    final servicesEither = await _getServicesWithStatus(null);
    servicesEither.fold(
      (failure) {
        emit(
          ProfileLoaded(
            user: user,
            displayName: displayName,
            services: List.empty(),
          ),
        );
      },
      (serviceList) {
        emit(
          ProfileLoaded(
            user: user,
            displayName: displayName,
            services: List.from(serviceList),
          ),
        );
      },
    );
  }

  List<ServiceWithStatus> getSubscribedServices() {
    if (state is! ProfileLoaded) return const [];
    final current = state as ProfileLoaded;
    return current.services.where((s) => s.isSubscribed).toList();
  }

  Future<bool> updateProfile({
    required String newName,
    required String newEmail,
  }) async {
    if (state is! ProfileLoaded) return false;
    final current = state as ProfileLoaded;
    final updatedUser = User(id: current.user.id, email: newEmail);
    emit(
      ProfileLoaded(
        user: updatedUser,
        displayName: newName,
        services: current.services,
      ),
    );
    return true;
  }
}
