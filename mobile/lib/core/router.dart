import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/setup_password_screen.dart';
import '../screens/auth/setup_face_screen.dart';
import '../screens/checkin/home_screen.dart';
import '../screens/checkin/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final onAuth = loc == '/login' || loc == '/register';
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth) return auth.needsSetup ? '/setup/password' : '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/setup/password', builder: (_, __) => const SetupPasswordScreen()),
        GoRoute(path: '/setup/face', builder: (_, __) => const SetupFaceScreen()),
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => ShellScreen(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
