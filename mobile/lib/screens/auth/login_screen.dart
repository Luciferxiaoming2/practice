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
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Background blurred gradient blobs
            Positioned(
              top: -80,
              left: -100,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE9D5FF).withOpacity(0.5), // purple-200/50
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              right: -100,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5D0FE).withOpacity(0.5), // fuchsia-200/50
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Logo text
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 36, letterSpacing: 4),
                          children: [
                            TextSpan(
                              text: 'END',
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF1E293B), // slate-800
                              ),
                            ),
                            TextSpan(
                              text: 'PAGE',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED), // purple-600
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '熵析云枢打卡系统',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B), // slate-500
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form
                      AppTextField(
                        label: '工号 / 账号',
                        controller: _usernameCtrl,
                        hint: '请输入账号',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: '密码',
                        controller: _passwordCtrl,
                        hint: '请输入密码',
                        obscure: true,
                        prefixIcon: Icons.lock_outline,
                        onSubmitted: (_) => _submit(),
                      ),

                      if (auth.error != null) ...[
                        const SizedBox(height: 14),
                        Text(auth.error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                      ],
                      const SizedBox(height: 28),

                      PrimaryButton(label: '验证登录', loading: auth.loading, onPressed: _submit),

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text.rich(TextSpan(
                          text: '没有账号？',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          children: [
                            TextSpan(
                              text: '立即注册',
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                      ),

                      const SizedBox(height: 60),
                      const Text(
                        '首次登录系统将强制要求修改密码及录入人脸',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
