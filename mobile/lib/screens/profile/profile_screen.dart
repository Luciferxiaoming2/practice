import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

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
    final user = context.watch<AuthProvider>().currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/home')),
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
            child: Text('退出', style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.25)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Center(child: Text('@${user?.username ?? ''}', style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5)))),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: (user?.isActive == true ? Colors.green : Colors.orange).withOpacity(0.12),
                ),
                child: Text(
                  user?.isActive == true ? '已激活' : '待激活',
                  style: TextStyle(fontSize: 12, color: user?.isActive == true ? Colors.green.shade700 : Colors.orange.shade700),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Change password
            _SectionTitle('修改密码'),
            const SizedBox(height: 12),
            _buildField('新密码', _pwdCtrl, obscure: true),
            const SizedBox(height: 12),
            _buildField('确认新密码', _confirmCtrl, obscure: true),
            if (_msg != null) ...[
              const SizedBox(height: 10),
              Text(_msg!, style: TextStyle(fontSize: 13, color: _success ? Colors.green.shade700 : scheme.error)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: '确认修改', loading: _loading, onPressed: _changePassword),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool obscure = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
}
