import 'package:dio/dio.dart';
import '../core/api.dart' show dio;

class CheckinService {
  Future<Map<String, dynamic>> createCheckin({double? lat, double? lng}) async {
    try {
      final res = await dio.post('/checkins/', data: {
        'lat': lat,
        'lng': lng,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '打卡失败');
    }
  }

  Future<List<Map<String, dynamic>>> getCheckins({String? dateFrom, String? dateTo}) async {
    try {
      final params = <String, dynamic>{};
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      final res = await dio.get('/checkins/', queryParameters: params);
      return List<Map<String, dynamic>>.from(res.data);
    } on DioException catch (e) {
      throw _handleError(e, fallback: '获取记录失败');
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
    if (e.response?.data is Map && e.response!.data.containsKey('detail')) {
      return e.response!.data['detail'].toString();
    }
    return fallback;
  }
}

final checkinService = CheckinService();
