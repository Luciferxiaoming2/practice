import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/checkin_provider.dart';
import 'providers/realtime_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AMapFlutterLocation.updatePrivacyShow(true, true);
  AMapFlutterLocation.updatePrivacyAgree(true);
  AMapFlutterLocation.setApiKey(AppConfig.amapAndroidKey, AppConfig.amapIosKey);

  final auth = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => CheckinProvider()),
        ChangeNotifierProvider(create: (_) => RealtimeProvider(auth)),
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
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _ready = false;
  bool _initStarted = false;
  int _lastShownNotificationId = 0;
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= buildRouter(context.read<AuthProvider>());
    if (!_initStarted) {
      _initStarted = true;
      _init();
    }
  }

  Future<void> _init() async {
    await context.read<AuthProvider>().init();
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  void _flushRealtimeNotification(RealtimeProvider realtime) {
    final latest = realtime.latestNotification;
    if (latest == null || latest.id == _lastShownNotificationId) return;

    _lastShownNotificationId = latest.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(latest.message),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.read<RealtimeProvider>().markLatestAsDelivered();
    });
  }

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeProvider>();
    _flushRealtimeNotification(realtime);

    if (!_ready || _router == null) {
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
      routerConfig: _router!,
      scaffoldMessengerKey: _messengerKey,
    );
  }
}
