import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/login_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/value_objects/email.dart';
import '../../../domain/value_objects/password.dart';
import '../../../domain/exceptions/auth_exceptions.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  late final LoginUser _loginUser;

  LoginCubit(AuthRepository repository) : super(LoginInitial()) {
    _loginUser = LoginUser(repository);
  }

  Future<void> login(String emailStr, String passwordStr) async {
    try {
      emit(LoginLoading());

      final email = Email(emailStr);
      final password = Password(passwordStr);

      final user = await _loginUser(email, password);

      emit(LoginSuccess(user));
    } on InvalidEmailException {
      emit(LoginError('Invalid email format'));
    } on WeakPasswordException {
      emit(LoginError('Password must be at least 6 characters'));
    } on InvalidCredentialsException {
      emit(LoginError('Invalid email or password'));
    } catch (e) {
      emit(LoginError('Unexpected error: $e'));
    }
  }
}