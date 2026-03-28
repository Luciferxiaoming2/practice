import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    await auth.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (auth.error != null) return;
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.surface, scheme.primary.withOpacity(0.08)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Logo
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
                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('熵析云枢', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text('打卡系统', style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 40),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(label: '账号', controller: _usernameCtrl, hint: '请输入账号', prefixIcon: Icons.person_outline),
                        const SizedBox(height: 16),
                        AppTextField(label: '密码', controller: _passwordCtrl, hint: '请输入密码', obscure: true, prefixIcon: Icons.lock_outline, onSubmitted: (_) => _submit()),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Text(auth.error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(label: '登录', loading: auth.loading, onPressed: _submit),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text.rich(TextSpan(
                              text: '没有账号？',
                              style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5)),
                              children: [TextSpan(text: '立即注册', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600))],
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
