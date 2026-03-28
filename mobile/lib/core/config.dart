/// 应用配置 — 本地开发阶段
/// TODO: 后期从远程配置或环境变量读取
class AppConfig {
  // 高德地图 Key（Android 和 iOS 各有独立 Key，此处为 Flutter 端统一初始化用）
  static const amapAndroidKey = '您的高德Android_Key';
  static const amapIosKey = '您的高德iOS_Key';

  // TODO: 后期替换为服务器地址
  // static const apiBaseUrl = 'https://api.your-domain.com';
  static const apiBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const apiBaseUrl = 'http://localhost:8000'; // iOS simulator
}
