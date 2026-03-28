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

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _ready = false;

  bool _initStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initStarted) {
      _initStarted = true;
      _init();
    }
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final router = buildRouter(auth);

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ENDPAGE',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ],
            ),
          ),
        ),
      );
    }

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
