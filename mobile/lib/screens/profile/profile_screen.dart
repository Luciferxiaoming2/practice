import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: const Color(0xFF7C3AED),
        onRefresh: () => auth.refreshUser(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header area
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 28,
                  left: 24,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Stack(
                  children: [
                    // Decorative gradient blob
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEDE9FE).withOpacity(0.6),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Avatar with gradient ring
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_outline,
                                size: 28,
                                color: const Color(0xFFD8B4FE), // purple-300
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? '',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '@${user?.username ?? ''}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: Text(
                                      user?.isActive == true ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: user?.isActive == true ? const Color(0xFF065F46) : const Color(0xFF9A3412),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Info section
                    _SectionCard(
                      children: [
                        _InfoRow(label: '所属角色', value: user?.roleName ?? '普通用户'),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _InfoRow(
                          label: '当前规则',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _rulesLabel(user),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action menu
                    _SectionCard(
                      children: [
                        _ActionRow(
                          icon: Icons.edit_outlined,
                          label: '修改姓名',
                          subtitle: user?.fullName ?? '',
                          onTap: () => _showNameSheet(context),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _ActionRow(
                          icon: Icons.shield_outlined,
                          label: '修改密码',
                          onTap: () => _showPasswordSheet(context),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _ActionRow(
                          icon: Icons.face_outlined,
                          label: '重新录入人脸',
                          subtitle: '需管理员重置状态后可用',
                          onTap: () => context.go('/setup/face'),
                        ),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _ActionRow(
                          icon: Icons.location_on_outlined,
                          label: '定位权限设置',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logout
                    GestureDetector(
                      onTap: () async {
                        // 清除所有Provider状态
                        context.read<CheckinProvider>().clearAllState();
                        await auth.logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2), // red-50
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECACA)), // red-100
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Text(
                              '退出登录',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rulesLabel(dynamic user) {
    if (user == null) return '未配置';
    final parts = <String>[];
    if (user.requireLocation) parts.add('GPS');
    if (user.requireTime) parts.add('时间');
    if (user.requireFace) parts.add('人脸');
    return parts.isEmpty ? '无限制' : '标准验证 (${parts.join('+')})';
  }

  void _showNameSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.currentUser?.fullName ?? '';
    bool saving = false;
    String? nameMsg;
    bool nameSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('修改姓名', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              AppTextField(label: '姓名', controller: _nameCtrl, prefixIcon: Icons.person_outline),
              if (nameMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  nameMsg!,
                  style: TextStyle(fontSize: 13, color: nameSuccess ? const Color(0xFF059669) : Colors.red.shade600),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: '确认修改', loading: saving, onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) {
                  setSheetState(() { nameMsg = '姓名不能为空'; nameSuccess = false; });
                  return;
                }
                setSheetState(() { saving = true; nameMsg = null; });
                try {
                  await auth.updateFullName(name);
                  setSheetState(() { nameMsg = '姓名修改成功'; nameSuccess = true; saving = false; });
                  Future.delayed(const Duration(seconds: 1), () {
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  });
                } catch (_) {
                  setSheetState(() { nameMsg = '修改失败，请重试'; nameSuccess = false; saving = false; });
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('修改密码', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            AppTextField(label: '新密码', controller: _pwdCtrl, obscure: true, prefixIcon: Icons.lock_outline),
            const SizedBox(height: 14),
            AppTextField(label: '确认新密码', controller: _confirmCtrl, obscure: true, prefixIcon: Icons.lock_outline),
            if (_msg != null) ...[
              const SizedBox(height: 12),
              Text(
                _msg!,
                style: TextStyle(fontSize: 13, color: _success ? const Color(0xFF059669) : Colors.red.shade600),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(label: '确认修改', loading: _loading, onPressed: () {
              _changePassword();
            }),
          ],
        ),
      ),
    );
  }
}

// ── Section card ──
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── Info row ──
class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  const _InfoRow({required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const Spacer(),
          valueWidget ?? Text(
            value ?? '',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}

// ── Action row ──
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF475569)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
