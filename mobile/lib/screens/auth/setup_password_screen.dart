import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

class SetupPasswordScreen extends StatefulWidget {
  const SetupPasswordScreen({super.key});
  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (_pwdCtrl.text != _confirmCtrl.text) {
      setState(() => _error = '两次密码不一致');
      return;
    }
    if (_pwdCtrl.text.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthProvider>().changePassword(_pwdCtrl.text);
      if (mounted) context.go('/setup/face');
    } catch (_) {
      setState(() => _error = '修改失败，请重试');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              StepIndicator(current: 1, total: 2),
              const SizedBox(height: 32),
              const Text('设置新密码', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('首次登录需要修改初始密码', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 32),
              _buildField('新密码', _pwdCtrl, obscure: true),
              const SizedBox(height: 16),
              _buildField('确认密码', _confirmCtrl, obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
              ],
              const Spacer(),
              PrimaryButton(label: '下一步', loading: _loading, onPressed: _submit),
            ],
          ),
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

