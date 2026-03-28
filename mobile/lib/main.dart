import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'providers/auth_provider.dart';
import 'providers/checkin_provider.dart';
import 'core/router.dart';
import 'core/config.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 高德隐私合规（必须在 setApiKey 之前）
  AMapFlutterLocation.updatePrivacyShow(true, true);
  AMapFlutterLocation.updatePrivacyAgree(true);
  AMapFlutterLocation.setApiKey(AppConfig.amapAndroidKey, AppConfig.amapIosKey);

  final auth = AuthProvider();
  await auth.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
      ],
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
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
