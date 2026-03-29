import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 管理员底部导航 Shell: 管理 | 记录 | 部门 | 打卡 | 我的
class AdminShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings, size: 26),
              label: '管理',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, size: 26),
              label: '记录',
            ),
            NavigationDestination(
              icon: Icon(Icons.business_outlined),
              selectedIcon: Icon(Icons.business, size: 26),
              label: '部门',
            ),
            NavigationDestination(
              icon: Icon(Icons.fingerprint),
              selectedIcon: Icon(Icons.fingerprint, size: 26),
              label: '打卡',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, size: 26),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}

/// 普通用户底部导航 Shell: 打卡 | 记录 | 我的
class UserShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const UserShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.fingerprint),
              selectedIcon: Icon(Icons.fingerprint, size: 26),
              label: '打卡',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, size: 26),
              label: '记录',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, size: 26),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
