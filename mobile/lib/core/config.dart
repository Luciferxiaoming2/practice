class AppConfig {
  static const amapAndroidKey = '5a44af79a61bba9abbaba1f688cb2be3';
  static const amapIosKey = '您的高德iOS_Key';

  // 真机调试推荐配合 adb reverse tcp:8000 tcp:8000 使用。
  static const apiBaseUrl = 'http://127.0.0.1:8000';

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 10);

  static Uri notificationsUri(String token) {
    final apiUri = Uri.parse(apiBaseUrl);
    return apiUri.replace(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/notifications',
      queryParameters: {'token': token},
    );
  }
}
