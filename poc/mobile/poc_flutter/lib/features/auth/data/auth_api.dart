import 'package:dio/dio.dart';
import 'models/user_model.dart';

import 'package:dio/dio.dart';
import 'models/user_model.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<UserModel> register(String email, String password) async {
    final res = await dio.post(
      '/register',
      data: {"email": email, "password": password},
      options: Options(headers: {"Content-Type": "application/json"}),
    );
    return UserModel.fromJson(res.data);
  }

  Future<(String, String)> login(String email, String password) async {
    final res = await dio.post(
      '/auth',
      data: {"email": email, "password": password},
      options: Options(headers: {"Content-Type": "application/json"}),
    );
    final access = res.data['access_token'] as String;
    final refresh = res.data['refresh_token'] as String;
    return (access, refresh);
  }
}