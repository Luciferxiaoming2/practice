class AppConfig {
  static const amapAndroidKey = '您的高德Android_Key';
  static const amapIosKey = '您的高德iOS_Key';

  // 后端 API 地址 — 真机通过 adb reverse tcp:8000 tcp:8000 连接
  static const apiBaseUrl = 'http://127.0.0.1:8000';

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 10);
}
