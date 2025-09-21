import '../domain/entities/user.dart';
import 'auth_api.dart';


class AuthRepository {
  final AuthApi api;
  String? _accessToken;
  String? _refreshToken;

  AuthRepository(this.api);

  Future<User> register(String email, String password) async {
    final model = await api.register(email, password);
    return model.toEntity();
  }

  Future<User> login(String email, String password) async {
    final tokens = await api.login(email, password);
    _accessToken = tokens.$1;
    _refreshToken = tokens.$2;

    return User(id: "unknown", email: email);
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
  }
}