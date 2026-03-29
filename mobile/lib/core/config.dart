class AppConfig {
  static const amapAndroidKey = '5a44af79a61bba9abbaba1f688cb2be3';
  // TODO: 替换为真实的高德 iOS Key
  static const amapIosKey = '您的高德iOS_Key';

  // 后端 API 地址
  // - Android 模拟器: 使用 10.0.2.2 (映射宿主机 localhost)
  // - iOS 模拟器: 使用 127.0.0.1
  // - 真机调试(推荐): 执行 adb reverse tcp:8000 tcp:8000 后使用 127.0.0.1
  // - 真机调试(备选): 使用电脑局域网 IP，如 http://192.168.x.x:8000
  // TODO: 生产环境替换为正式域名
  static const apiBaseUrl = 'http://127.0.0.1:8000';

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 10);
}
