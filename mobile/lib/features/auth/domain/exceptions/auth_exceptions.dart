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

class UserNotAuthenticatedException extends AuthException {
  UserNotAuthenticatedException()
      : super("No user is currently authenticated.");
}

class AccountNotVerifiedException extends AuthException {
  AccountNotVerifiedException()
      : super("Account not verified. Please check your email.");
}

class TokenExpiredException extends AuthException {
  TokenExpiredException()
      : super("Verification token has expired. Please request a new one.");
}
