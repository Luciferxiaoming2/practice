import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  Future<void> _submit() async {
    if (_usernameCtrl.text.trim().isEmpty || _fullNameCtrl.text.trim().isEmpty) {
      setState(() => _error = '请填写完整信息');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    setState(() => _error = null);

    final auth = context.read<AuthProvider>();
    await auth.register(_usernameCtrl.text.trim(), _fullNameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (auth.error != null) {
      setState(() => _error = auth.error);
      return;
    }
    if (auth.needsSetup) {
      context.go('/setup/password');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [scheme.surface, scheme.primary.withOpacity(0.08)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: scheme.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('创建账号', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text('注册后即可使用打卡系统', style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(label: '账号', controller: _usernameCtrl, hint: '请输入账号', prefixIcon: Icons.person_outline),
                        const SizedBox(height: 16),
                        AppTextField(label: '姓名', controller: _fullNameCtrl, hint: '请输入真实姓名', prefixIcon: Icons.badge_outlined),
                        const SizedBox(height: 16),
                        AppTextField(label: '密码', controller: _passwordCtrl, hint: '至少6位', obscure: true, prefixIcon: Icons.lock_outline),
                        const SizedBox(height: 16),
                        AppTextField(label: '确认密码', controller: _confirmCtrl, hint: '请再次输入密码', obscure: true, prefixIcon: Icons.lock_outline),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(label: '注册', loading: auth.loading, onPressed: _submit),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text.rich(TextSpan(
                              text: '已有账号？',
                              style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5)),
                              children: [TextSpan(text: '返回登录', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600))],
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
