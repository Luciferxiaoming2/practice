import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/api.dart' show storage;

class AuthProvider extends ChangeNotifier {
  User? currentUser;
  bool loading = false;
  String? error;

  bool get isLoggedIn => currentUser != null;
  bool get needsSetup => currentUser != null && !currentUser!.isActive;

  Future<void> init() async {
    final token = await storage.read(key: 'token');
    if (token == null) return;

    final userIdStr = await storage.read(key: 'userId');
    if (userIdStr == null) return;

    try {
      final raw = await authService.getMe(int.parse(userIdStr));
      currentUser = User.fromJson(raw);
      // 缓存到本地
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(raw));
    } catch (_) {
      // API 不通时尝试离线缓存
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_user');
      if (cached != null) {
        currentUser = User.fromJson(jsonDecode(cached));
      }
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final token = await authService.login(username, password);
      await storage.write(key: 'token', value: token);

      // 从 JWT 解析 userId
      final userId = _parseUserIdFromJwt(token);
      await storage.write(key: 'userId', value: userId.toString());

      final raw = await authService.getMe(userId);
      currentUser = User.fromJson(raw);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(raw));
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String fullName, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await authService.register(username, fullName, password);
      // 注册成功后自动登录
      await login(username, password);
      return;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String newPassword) async {
    if (currentUser == null) return;
    await authService.resetPassword(currentUser!.id, newPassword);
  }

  Future<void> markFaceEnrolled() async {
    if (currentUser == null) return;
    final raw = await authService.updateUser(currentUser!.id, {
      'face_enrolled': true,
      'is_active': true,
    });
    currentUser = User.fromJson(raw);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(raw));
    notifyListeners();
  }

  Future<void> updateFullName(String fullName) async {
    if (currentUser == null) return;
    final raw = await authService.updateUser(currentUser!.id, {
      'full_name': fullName,
    });
    currentUser = User.fromJson(raw);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(raw));
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (currentUser == null) return;
    try {
      final raw = await authService.getMe(currentUser!.id);
      currentUser = User.fromJson(raw);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(raw));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'userId');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
    currentUser = null;
    notifyListeners();
  }

  int _parseUserIdFromJwt(String token) {
    final parts = token.split('.');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final data = jsonDecode(payload) as Map<String, dynamic>;
    return int.parse(data['sub'].toString());
  }
}
