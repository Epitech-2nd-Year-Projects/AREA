import 'dart:convert';
import '../../../../core/storage/local_prefs_manager.dart';
import '../../../../core/storage/storage_keys.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);

  Future<UserModel?> getCachedUser();

  Future<void> clearCache();

  Future<bool> hasAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalPrefsManager _prefs;

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> cacheUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs.writeString(StorageKeys.userProfile, userJson);
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = _prefs.readString(StorageKeys.userProfile);
      if (userJson == null) return null;

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _prefs.delete(StorageKeys.userProfile);
  }

  @override
  Future<bool> hasAuthData() async {
    final user = await getCachedUser();
    return user != null;
  }
}