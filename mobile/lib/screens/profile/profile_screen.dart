import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _msg;
  bool _success = false;

  Future<void> _changePassword() async {
    if (_pwdCtrl.text != _confirmCtrl.text) {
      setState(() { _msg = '两次密码不一致'; _success = false; });
      return;
    }
    if (_pwdCtrl.text.length < 6) {
      setState(() { _msg = '密码至少6位'; _success = false; });
      return;
    }
    setState(() { _loading = true; _msg = null; });
    try {
      await context.read<AuthProvider>().changePassword(_pwdCtrl.text);
      _pwdCtrl.clear();
      _confirmCtrl.clear();
      setState(() { _msg = '密码修改成功'; _success = true; });
    } catch (_) {
      setState(() { _msg = '修改失败，请重试'; _success = false; });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            child: Text('退出', style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + name
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.25)!],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  )),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Center(child: Text('@${user?.username ?? ''}', style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5)))),
              const SizedBox(height: 24),

              // Info cards
              _InfoCard(children: [
                _InfoRow(icon: Icons.shield_outlined, label: '角色', value: user?.roleName ?? '普通用户'),
                _InfoRow(icon: Icons.verified_outlined, label: '状态', value: user?.isActive == true ? '已激活' : '待激活',
                    valueColor: user?.isActive == true ? Colors.green.shade600 : Colors.orange.shade600),
                _InfoRow(icon: Icons.face_outlined, label: '人脸录入', value: user?.faceEnrolled == true ? '已录入' : '未录入',
                    valueColor: user?.faceEnrolled == true ? Colors.green.shade600 : Colors.orange.shade600),
              ]),

              const SizedBox(height: 24),

              // Change password
              Text('修改密码', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.onSurface)),
              const SizedBox(height: 12),
              AppTextField(label: '新密码', controller: _pwdCtrl, obscure: true, prefixIcon: Icons.lock_outline),
              const SizedBox(height: 12),
              AppTextField(label: '确认新密码', controller: _confirmCtrl, obscure: true, prefixIcon: Icons.lock_outline),
              if (_msg != null) ...[
                const SizedBox(height: 10),
                Text(_msg!, style: TextStyle(fontSize: 13, color: _success ? Colors.green.shade700 : scheme.error)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(label: '确认修改', loading: _loading, onPressed: _changePassword),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 14, color: scheme.onSurface.withOpacity(0.7))),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? scheme.onSurface)),
      ]),
    );
  }
}
