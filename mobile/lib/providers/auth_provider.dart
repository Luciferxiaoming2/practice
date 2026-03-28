import 'package:flutter/material.dart';
import '../core/local_store.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? currentUser;
  bool loading = false;
  String? error;

  bool get isLoggedIn => currentUser != null;
  bool get needsSetup => currentUser != null && !currentUser!.isActive;

  Future<void> init() async {
    await LocalStore.init();
    final raw = await LocalStore.getCurrentUser();
    if (raw != null) {
      currentUser = User.fromJson(raw);
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      // TODO: 后期替换为 dio.post('/auth/login', ...)
      final raw = await LocalStore.login(username, password);
      if (raw == null) {
        error = '账号或密码错误';
      } else {
        currentUser = User.fromJson(raw);
      }
    } catch (e) {
      error = '登录失败，请重试';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (currentUser == null) return;
    // TODO: 后期替换为 dio.post('/users/${currentUser!.id}/reset-password', ...)
    await LocalStore.changePassword(currentUser!.id, newPassword);
  }

  Future<void> markFaceEnrolled() async {
    if (currentUser == null) return;
    // TODO: 后期替换为 dio.patch('/users/${currentUser!.id}', ...)
    await LocalStore.updateUser(currentUser!.id, {
      'face_enrolled': true,
      'is_active': true,
    });
    final raw = await LocalStore.getCurrentUser();
    if (raw != null) currentUser = User.fromJson(raw);
    notifyListeners();
  }

  Future<void> logout() async {
    // TODO: 后期清除服务器 token
    await LocalStore.logout();
    currentUser = null;
    notifyListeners();
  }
}
