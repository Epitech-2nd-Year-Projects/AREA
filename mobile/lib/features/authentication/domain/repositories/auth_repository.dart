import '../entities/user.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';

abstract class AuthRepository {
  Future<User> login(Email email, Password password);
  Future<User> register(Email email, Password password);
  Future<void> logout();
}