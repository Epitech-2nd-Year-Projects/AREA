import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/user.dart';
import '../data/auth_repository.dart';
import "../../../core/network/api_client.dart";

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;
  User? _user;

  AuthCubit(this.repo) : super(AuthInitial());

  bool get isLoggedIn => _user != null;

  Future<void> register(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repo.register(email, password);
      _user = user;
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      print("❌ ERROR: $e");
      print("STACKTRACE: $st");
      emit(AuthError(e.toString()));
      emit(AuthError("Register failed: $e"));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await repo.login(email, password);
      _user = user;
      emit(AuthAuthenticated(user));
    } catch (e, st) {
      print("❌ ERROR: $e");
      print("STACKTRACE: $st");
      emit(AuthError(e.toString()));
      emit(AuthError("Login failed: $e"));
    }
  }

  Future<void> logout() async {
    await repo.logout();
    _user = null;
    emit(AuthInitial());
  }

  Future<void> checkSessionOnStartup(ApiClient client) async {
    emit(AuthLoading());
    try {
      final cookies = await client.cookieJar
          .loadForRequest(Uri.parse("http://10.0.2.2:8080"));

      final hasRefresh = cookies.any(
            (c) => c.name == "refresh_token" && c.value.isNotEmpty,
      );
      if (hasRefresh) {
        emit(AuthAuthenticated(User(id: "cached", email: "unknown@email")));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }
}