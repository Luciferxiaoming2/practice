import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
// const _baseUrl = 'http://localhost:8000'; // iOS simulator

final _storage = FlutterSecureStorage();

Dio createDio() {
  final dio = Dio(BaseOptions(baseUrl: _baseUrl));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      if (error.response?.statusCode == 401) {
        _storage.delete(key: 'token');
      }
      handler.next(error);
    },
  ));

  return dio;
}

final dio = createDio();
