import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_placement/models/user_model.dart';

class AuthService {
  static const String _userKey = 'current_user';

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    try {
      final map = json.decode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    // TODO: Replace with real API call
    await Future<void>.delayed(const Duration(seconds: 1));
    if (email.isNotEmpty && password.isNotEmpty) {
      final user = UserModel(
        id: '1',
        name: 'Demo User',
        email: email,
        role: UserRole.student,
      );
      await _saveUser(user);
      return user;
    }
    return null;
  }

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // TODO: Replace with real API call
    await Future<void>.delayed(const Duration(seconds: 1));
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
    await _saveUser(user);
    return user;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }
}
