import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class VerifyEmail {
  final AuthRepository repository;

  VerifyEmail(this.repository);

  Future<User> call(String token) async {
    return await repository.verifyEmail(token);
  }
}