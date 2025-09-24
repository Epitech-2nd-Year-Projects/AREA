class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class InvalidEmailException extends AuthException {
  InvalidEmailException(String email)
      : super("Invalid email format provided: $email");
}

class WeakPasswordException extends AuthException {
  WeakPasswordException(String password)
      : super("Password is too weak. Minimum 6 characters required.");
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException()
      : super("Invalid email or password.");
}

class UserAlreadyExistsException extends AuthException {
  UserAlreadyExistsException()
      : super("A user with this email already exists.");
}

class LogoutFailedException extends AuthException {
  LogoutFailedException() : super("Logout failed.");
}