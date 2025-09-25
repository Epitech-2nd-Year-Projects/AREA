import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/register_user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/value_objects/email.dart';
import '../../../domain/value_objects/password.dart';
import '../../../domain/exceptions/auth_exceptions.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  late final RegisterUser _registerUser;

  RegisterCubit(AuthRepository repository) : super(RegisterInitial()) {
    _registerUser = RegisterUser(repository);
  }

  Future<void> register(String emailStr, String passwordStr, String confirm) async {
    if (passwordStr != confirm) {
      emit(RegisterError('Passwords do not match'));
      return;
    }

    try {
      emit(RegisterLoading());

      final email = Email(emailStr);
      final password = Password(passwordStr);

      final user = await _registerUser(email, password);

      emit(RegisterSuccess(user));
    } on InvalidEmailException {
      emit(RegisterError('Invalid email format'));
    } on WeakPasswordException {
      emit(RegisterError('Password must be at least 6 chars'));
    } on UserAlreadyExistsException {
      emit(RegisterError('A user with this email already exists'));
    } catch (e) {
      emit(RegisterError('Unexpected error: $e'));
    }
  }
}