import 'package:dio/dio.dart';
import '../core/api.dart' show dio;

class AdminService {
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final res = await dio.get('/users/');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取用户列表失败');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String username,
    required String fullName,
    required String password,
    int? roleId,
    int? departmentId,
  }) async {
    try {
      final res = await dio.post('/users/', data: {
        'username': username,
        'full_name': fullName,
        'password': password,
        if (roleId != null) 'role_id': roleId,
        if (departmentId != null) 'department_id': departmentId,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '创建用户失败');
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final res = await dio.patch('/users/$id', data: data);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '更新用户失败');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await dio.delete('/users/$id');
    } on DioException catch (e) {
      throw _handleError(e, fallback: '删除用户失败');
    }
  }

  Future<void> resetPassword(int id, String newPassword) async {
    try {
      await dio.post('/users/$id/reset-password', data: {'new_password': newPassword});
    } on DioException catch (e) {
      throw _handleError(e, fallback: '重置密码失败');
    }
  }

  Future<void> resetFace(int id) async {
    try {
      await dio.post('/users/$id/reset-face');
    } on DioException catch (e) {
      throw _handleError(e, fallback: '重置人脸失败');
    }
  }

  Future<List<Map<String, dynamic>>> getCheckins({
    int? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (userId != null) params['user_id'] = userId;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      final res = await dio.get('/checkins/', queryParameters: params);
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取打卡记录失败');
    }
  }

  Future<void> deleteCheckin(int id) async {
    try {
      await dio.delete('/checkins/$id');
    } on DioException catch (e) {
      throw _handleError(e, fallback: '删除记录失败');
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final res = await dio.get('/departments/');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取部门列表失败');
    }
  }

  Future<Map<String, dynamic>> createDepartment(String name, String? description) async {
    try {
      final res = await dio.post('/departments/', data: {
        'name': name,
        if (description != null) 'description': description,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '创建部门失败');
    }
  }

  Future<Map<String, dynamic>> updateDepartment(int id, Map<String, dynamic> data) async {
    try {
      final res = await dio.patch('/departments/$id', data: data);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '更新部门失败');
    }
  }

  Future<void> deleteDepartment(int id) async {
    try {
      await dio.delete('/departments/$id');
    } on DioException catch (e) {
      throw _handleError(e, fallback: '删除部门失败');
    }
  }

  Future<void> batchDepartmentRules(int departmentId, Map<String, dynamic> rules) async {
    try {
      await dio.post('/departments/$departmentId/batch-rules', data: rules);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '批量设置规则失败');
    }
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final res = await dio.get('/roles/');
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取角色列表失败');
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
    }
    return fallback;
  }
}

final adminService = AdminService();
