import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

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
    await auth.register(
      _usernameCtrl.text.trim(),
      _fullNameCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;
    if (auth.error != null) {
      setState(() => _error = auth.error);
      return;
    }
    // 注册成功，自动登录并进入设置流程
    context.go('/setup/password');
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: scheme.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text('创建账号', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text('注册后即可使用打卡系统', style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 32),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
                        BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 0, offset: const Offset(0, 1), spreadRadius: 0),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Field(label: '账号', controller: _usernameCtrl, hint: '请输入账号'),
                        const SizedBox(height: 16),
                        _Field(label: '姓名', controller: _fullNameCtrl, hint: '请输入真实姓名'),
                        const SizedBox(height: 16),
                        _Field(label: '密码', controller: _passwordCtrl, hint: '请输入密码（至少6位）', obscure: true),
                        const SizedBox(height: 16),
                        _Field(label: '确认密码', controller: _confirmCtrl, hint: '请再次输入密码', obscure: true),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: '注册',
                          loading: auth.loading,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text.rich(
                              TextSpan(
                                text: '已有账号？',
                                style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5)),
                                children: [
                                  TextSpan(
                                    text: '返回登录',
                                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
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

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  const _Field({required this.label, required this.controller, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.35), fontSize: 14),
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
