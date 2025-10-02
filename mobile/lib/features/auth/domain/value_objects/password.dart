import '../exceptions/auth_exceptions.dart';

class Password {
  final String value;

  Password._(this.value);

  factory Password(String input) {
    if (!_isValidPassword(input)) {
      throw WeakPasswordException(input);
    }
    return Password._(input);
  }

  static bool _isValidPassword(String password) {
    return password.length >= 12;
  }

  @override
  String toString() => 'Password(*******)';
}