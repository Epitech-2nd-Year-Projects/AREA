import 'user_model.dart';

class AuthResponseModel {
  final UserModel user;

  const AuthResponseModel({required this.user});

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson()};
  }
}
