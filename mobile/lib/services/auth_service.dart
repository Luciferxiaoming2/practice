import 'package:dio/dio.dart';
import '../core/api.dart' show dio;

class AuthService {
  Future<String> login(String username, String password) async {
    try {
      final res = await dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      return res.data['access_token'];
    } on DioException catch (e) {
      throw _handleError(e, fallback: '账号或密码错误');
    }
  }

  Future<Map<String, dynamic>> register(String username, String fullName, String password) async {
    try {
      final res = await dio.post('/auth/register', data: {
        'username': username,
        'full_name': fullName,
        'password': password,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '注册失败');
    }
  }

  Future<Map<String, dynamic>> getMe(int userId) async {
    try {
      final res = await dio.get('/users/$userId');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取用户信息失败');
    }
  }

  Future<void> resetPassword(int userId, String newPassword) async {
    try {
      await dio.post('/users/$userId/reset-password', data: {
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw _handleError(e, fallback: '修改密码失败');
    }
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> updates) async {
    try {
      final res = await dio.patch('/users/$userId', data: updates);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '更新失败');
    }
  }

  String _handleError(DioException e, {required String fallback}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '连接超时，请检查网络';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接服务器';
    }
    if (e.response != null) {
      final detail = e.response?.data;
      if (detail is Map && detail.containsKey('detail')) {
        return detail['detail'].toString();
      }
      return fallback;
    }
    return '网络异常，请重试';
  }
}

final authService = AuthService();
