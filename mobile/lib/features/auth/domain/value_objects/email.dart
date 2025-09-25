import 'package:area/features/auth/domain/exceptions/auth_exceptions.dart';

class Email {
    final String value;

    Email._(this.value);

    factory Email(String input) {
        if (!_isValidEmail(input)) {
          throw InvalidEmailException(input);
        }
        return Email._(input);
    }

    static bool _isValidEmail(String email) {
      final regex = RegExp(r"^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$");
      return regex.hasMatch(email);
    }

    @override
    String toString() => value;
}