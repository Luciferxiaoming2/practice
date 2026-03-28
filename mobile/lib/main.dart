import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'providers/auth_provider.dart';
import 'core/router.dart';
import 'core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化高德定位 SDK
  // TODO: 后期可从服务器动态下发 Key
  AMapFlutterLocation.setApiKey(
    AppConfig.amapAndroidKey,
    AppConfig.amapIosKey,
  );

  final auth = AuthProvider();
  await auth.init(); // 恢复本地登录状态

  runApp(
    ChangeNotifierProvider.value(
      value: auth,
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final router = buildRouter(auth);

    return MaterialApp.router(
      title: '熵析云枢',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
