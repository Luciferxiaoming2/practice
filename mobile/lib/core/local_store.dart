import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// 本地数据存储 — 替代服务器 API
/// TODO: 后期替换为服务器API调用，本类仅保留做离线缓存
class LocalStore {
  static const _keyUsers = 'local_users';
  static const _keyCheckins = 'local_checkins';
  static const _keyCurrentUser = 'local_current_user';

  // ── 预置数据 ──────────────────────────────────────────
  static final List<Map<String, dynamic>> _defaultUsers = [
    {
      'id': 1,
      'username': 'admin',
      'full_name': '超级管理员',
      'password': 'admin123',
      'is_active': true,
      'is_admin': true,
      'face_enrolled': true,
      'require_location': false,
      'location_lat': null,
      'location_lng': null,
      'location_radius': null,
      'require_time': false,
      'checkin_time_start': null,
      'checkin_time_end': null,
      'require_face': false,
    },
    {
      'id': 2,
      'username': 'zhangsan',
      'full_name': '张三',
      'password': 'test1234',
      'is_active': true,
      'is_admin': false,
      'face_enrolled': true,
      'require_location': true,
      'location_lat': 39.90923,
      'location_lng': 116.397428,
      'location_radius': 500.0,
      'require_time': true,
      'checkin_time_start': '08:00',
      'checkin_time_end': '18:00',
      'require_face': true,
    },
    {
      'id': 3,
      'username': 'lisi',
      'full_name': '李四',
      'password': 'test1234',
      'is_active': false, // 需要首次设置
      'is_admin': false,
      'face_enrolled': false,
      'require_location': false,
      'location_lat': null,
      'location_lng': null,
      'location_radius': null,
      'require_time': false,
      'checkin_time_start': null,
      'checkin_time_end': null,
      'require_face': false,
    },
  ];

  // ── 初始化 ────────────────────────────────────────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // 首次启动时写入预置用户
    if (!prefs.containsKey(_keyUsers)) {
      await prefs.setString(_keyUsers, jsonEncode(_defaultUsers));
      await prefs.setString(_keyCheckins, jsonEncode([]));
    }
  }

  // ── 用户操作 ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUsers) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final users = await getUsers();
    try {
      final user = users.firstWhere(
        (u) => u['username'] == username && u['password'] == password,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, jsonEncode(user));
      return user;
    } catch (_) {
      return null; // 账号或密码错误
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCurrentUser);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> updateUser(int userId, Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getUsers();
    final idx = users.indexWhere((u) => u['id'] == userId);
    if (idx < 0) return;
    users[idx].addAll(updates);
    await prefs.setString(_keyUsers, jsonEncode(users));
    // 同步更新当前登录用户缓存
    final current = await getCurrentUser();
    if (current != null && current['id'] == userId) {
      await prefs.setString(_keyCurrentUser, jsonEncode(users[idx]));
    }
  }

  static Future<void> changePassword(int userId, String newPassword) async {
    await updateUser(userId, {'password': newPassword});
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  // ── 打卡记录 ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getCheckins({int? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCheckins) ?? '[]';
    final all = List<Map<String, dynamic>>.from(jsonDecode(raw));
    if (userId != null) {
      return all.where((c) => c['user_id'] == userId).toList();
    }
    return all;
  }

  static Future<Map<String, dynamic>> addCheckin({
    required int userId,
    double? lat,
    double? lng,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final checkins = await getCheckins();
    final record = {
      'id': checkins.length + 1,
      'user_id': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'lat': lat,
      'lng': lng,
      'status': status,
    };
    checkins.insert(0, record);
    await prefs.setString(_keyCheckins, jsonEncode(checkins));
    return record;
  }
}
