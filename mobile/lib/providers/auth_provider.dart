import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  User? currentUser;
  bool loading = false;
  String? error;

  bool get isLoggedIn => currentUser != null;
  bool get needsSetup => currentUser != null && !currentUser!.isActive;

  Future<void> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final res = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: 'token', value: token);
      await fetchMe(username);
    } catch (e) {
      error = '账号或密码错误';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Fetch user info by username after login
  Future<void> fetchMe(String username) async {
    final res = await dio.get('/users/');
    final list = (res.data as List).map((e) => User.fromJson(e)).toList();
    currentUser = list.firstWhere((u) => u.username == username);
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    if (currentUser == null) return;
    await dio.post('/users/${currentUser!.id}/reset-password', data: {
      'new_password': newPassword,
    });
  }

  Future<void> markFaceEnrolled() async {
    if (currentUser == null) return;
    await dio.patch('/users/${currentUser!.id}', data: {
      'face_enrolled': true,
      'is_active': true,
    });
    await fetchMe(currentUser!.username);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    currentUser = null;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }
}
