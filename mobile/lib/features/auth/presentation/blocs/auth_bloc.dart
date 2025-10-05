import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/use_cases/logout_user.dart';
import '../../domain/use_cases/get_current_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/exceptions/auth_exceptions.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  late final LogoutUser _logoutUser;
  late final GetCurrentUser _getCurrentUser;

  AuthBloc(AuthRepository repository) : super(AuthInitial()) {
    _logoutUser = LogoutUser(repository);
    _getCurrentUser = GetCurrentUser(repository);

    on<AppStarted>(_onAppStarted);
    add(AppStarted());
    on<UserLoggedIn>(_onUserLoggedIn);
    on<UserLoggedOut>(_onUserLoggedOut);
    on<SessionExpired>(_onSessionExpired);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

   Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    emit(Authenticated(User(
      id: "dev-user-1",
      email: "dev@area.app",
    )));
  }

  Future<void> _onUserLoggedIn(UserLoggedIn event, Emitter<AuthState> emit) async {
    emit(Authenticated(event.user));
  }

  Future<void> _onUserLoggedOut(UserLoggedOut event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      await _logoutUser();
      emit(Unauthenticated());
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) async {
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    try {
      final user = await _getCurrentUser();
      emit(Authenticated(user));
    } catch (_) {
      emit(Unauthenticated());
    }
  }
}