import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

final storage = FlutterSecureStorage();

Future<void> clearSessionStorage() async {
  await storage.delete(key: 'token');
  await storage.delete(key: 'userId');
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('cached_user');
}

Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await clearSessionStorage();
      }
      handler.next(error);
    },
  ));

  return dio;
}

final dio = createDio();
