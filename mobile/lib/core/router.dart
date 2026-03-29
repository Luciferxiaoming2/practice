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
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_checkins_screen.dart';
import '../screens/admin/admin_departments_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/shell_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/login',
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;
        final onAuth = loc == '/login' || loc == '/register';
        final onSetup = loc == '/setup/password' || loc == '/setup/face';
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth) {
          if (auth.needsSetup) return '/setup/password';
          return auth.currentUser!.isAdmin ? '/admin/dashboard' : '/home';
        }
        // 已完成设置的用户不应停留在 setup 页面
        if (loggedIn && onSetup && !auth.needsSetup) {
          return auth.currentUser!.isAdmin ? '/admin/dashboard' : '/home';
        }
        // 普通用户不能访问 admin 路由
        if (loggedIn && !auth.needsSetup && loc.startsWith('/admin') && !(auth.currentUser?.isAdmin ?? false)) {
          return '/home';
        }
        // 管理员访问普通用户的 /home 等路由也允许（管理员也可以打卡）
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/setup/password', builder: (_, __) => const SetupPasswordScreen()),
        GoRoute(path: '/setup/face', builder: (_, __) => const SetupFaceScreen()),

        // 管理员 Shell
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => AdminShellScreen(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/admin/checkins', builder: (_, __) => const AdminCheckinsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/admin/departments', builder: (_, __) => const AdminDepartmentsScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/admin/profile', builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),

        // 普通用户 Shell
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => UserShellScreen(navigationShell: shell),
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
