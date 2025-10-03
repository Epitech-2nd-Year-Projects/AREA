import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/verify_email.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/exceptions/auth_exceptions.dart';
import 'email_verification_state.dart';

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  late final VerifyEmail _verifyEmail;

  EmailVerificationCubit(AuthRepository repository)
      : super(EmailVerificationInitial()) {
    _verifyEmail = VerifyEmail(repository);
  }

  Future<void> verifyEmail(String token) async {
    try {
      emit(EmailVerificationLoading());
      final user = await _verifyEmail(token);
      emit(EmailVerificationSuccess(user));
    } on TokenExpiredException {
      emit(EmailVerificationError(
        'Verification link has expired. Please request a new one.',
      ));
    } on AuthException catch (e) {
      emit(EmailVerificationError(e.message));
    } catch (e) {
      emit(EmailVerificationError('Verification failed: $e'));
    }
  }
}