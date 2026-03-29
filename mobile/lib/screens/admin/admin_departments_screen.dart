import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/empty_state.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  const AdminDepartmentsScreen({super.key});
  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  List<Map<String, dynamic>> _departments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _departments = await adminService.getDepartments();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_outlined, size: 20),
        label: const Text('新建部门', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24, right: 24, bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('部门管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('管理所有部门信息', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_departments.length} 个',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : _error != null
                    ? EmptyState(icon: Icons.cloud_off, title: '加载失败', subtitle: _error, actionLabel: '重试', onAction: _load)
                    : _departments.isEmpty
                        ? const EmptyState(icon: Icons.business_outlined, title: '暂无部门')
                        : RefreshIndicator(
                            color: const Color(0xFF7C3AED),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                              itemCount: _departments.length,
                              itemBuilder: (_, i) => _DepartmentCard(
                                department: _departments[i],
                                onAction: () => _showActionSheet(_departments[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── Action sheet ──
  void _showActionSheet(Map<String, dynamic> dept) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (dept['name'] as String? ?? '?').isNotEmpty ? (dept['name'] as String)[0] : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dept['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      if (dept['description'] != null && (dept['description'] as String).isNotEmpty)
                        Text(dept['description'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _ActionTile(icon: Icons.edit_outlined, label: '编辑部门', color: const Color(0xFF2563EB), onTap: () {
              Navigator.pop(ctx);
              _showEditSheet(dept);
            }),
            _ActionTile(icon: Icons.tune, label: '批量打卡规则', color: const Color(0xFF7C3AED), onTap: () {
              Navigator.pop(ctx);
              _showBatchRulesSheet(dept);
            }),
            _ActionTile(icon: Icons.delete_outline, label: '删除部门', color: Colors.red, onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(dept);
            }),
          ],
        ),
      ),
    );
  }

  // ── Create department ──
  void _showCreateSheet() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool saving = false;
    String? msg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('新建部门', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                AppTextField(label: '部门名称', controller: nameCtrl, prefixIcon: Icons.business_outlined),
                const SizedBox(height: 14),
                AppTextField(label: '部门描述', controller: descCtrl, prefixIcon: Icons.description_outlined),
                if (msg != null) ...[
                  const SizedBox(height: 12),
                  Text(msg!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(label: '创建', loading: saving, onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    setS(() => msg = '请填写部门名称');
                    return;
                  }
                  setS(() { saving = true; msg = null; });
                  try {
                    final desc = descCtrl.text.trim();
                    await adminService.createDepartment(name, desc.isNotEmpty ? desc : null);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('部门创建成功'), backgroundColor: Color(0xFF059669)),
                      );
                    }
                  } catch (e) {
                    setS(() { saving = false; msg = e.toString(); });
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit department ──
  void _showEditSheet(Map<String, dynamic> dept) {
    final nameCtrl = TextEditingController(text: dept['name'] ?? '');
    final descCtrl = TextEditingController(text: dept['description'] ?? '');
    bool saving = false;
    String? msg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('编辑部门 - ${dept['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                AppTextField(label: '部门名称', controller: nameCtrl, prefixIcon: Icons.business_outlined),
                const SizedBox(height: 14),
                AppTextField(label: '部门描述', controller: descCtrl, prefixIcon: Icons.description_outlined),
                if (msg != null) ...[
                  const SizedBox(height: 12),
                  Text(msg!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(label: '保存', loading: saving, onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    setS(() => msg = '请填写部门名称');
                    return;
                  }
                  setS(() { saving = true; msg = null; });
                  try {
                    await adminService.updateDepartment(dept['id'], {
                      'name': name,
                      'description': descCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('部门已更新'), backgroundColor: Color(0xFF059669)),
                      );
                    }
                  } catch (e) {
                    setS(() { saving = false; msg = e.toString(); });
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Batch rules sheet ──
  void _showBatchRulesSheet(Map<String, dynamic> dept) {
    bool reqSignIn = true;
    bool reqSignOut = false;
    bool reqLoc = false;
    bool reqTime = false;
    bool reqFace = false;
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '200');
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final signOutStartCtrl = TextEditingController();
    final signOutEndCtrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('批量打卡规则 - ${dept['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                const Text('将规则应用到该部门所有成员', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),

                // Sign in / Sign out
                _RuleToggle(
                  icon: Icons.login,
                  label: '要求签到',
                  value: reqSignIn,
                  onChanged: (v) => setS(() => reqSignIn = v),
                ),
                const SizedBox(height: 16),
                _RuleToggle(
                  icon: Icons.logout,
                  label: '要求签退',
                  value: reqSignOut,
                  onChanged: (v) => setS(() => reqSignOut = v),
                ),
                const SizedBox(height: 16),

                // Location
                _RuleToggle(
                  icon: Icons.location_on_outlined,
                  label: '要求地点打卡',
                  value: reqLoc,
                  onChanged: (v) => setS(() => reqLoc = v),
                ),
                if (reqLoc) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AppTextField(label: '纬度', controller: latCtrl, prefixIcon: Icons.my_location)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: '经度', controller: lngCtrl, prefixIcon: Icons.my_location)),
                  ]),
                  const SizedBox(height: 10),
                  AppTextField(label: '半径(米)', controller: radiusCtrl, prefixIcon: Icons.radar),
                ],
                const SizedBox(height: 16),

                // Time
                _RuleToggle(
                  icon: Icons.schedule_outlined,
                  label: '要求时间段打卡',
                  value: reqTime,
                  onChanged: (v) => setS(() => reqTime = v),
                ),
                if (reqTime) ...[
                  const SizedBox(height: 12),
                  const Text('签到时间窗口', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: AppTextField(label: '开始时间', controller: startCtrl, prefixIcon: Icons.login, hint: '09:00')),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: '结束时间', controller: endCtrl, prefixIcon: Icons.logout, hint: '10:00')),
                  ]),
                  const SizedBox(height: 12),
                  const Text('签退时间窗口', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: AppTextField(label: '开始时间', controller: signOutStartCtrl, prefixIcon: Icons.login, hint: '17:00')),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: '结束时间', controller: signOutEndCtrl, prefixIcon: Icons.logout, hint: '18:00')),
                  ]),
                ],
                const SizedBox(height: 16),

                // Face
                _RuleToggle(
                  icon: Icons.face_outlined,
                  label: '要求人脸识别',
                  value: reqFace,
                  onChanged: (v) => setS(() => reqFace = v),
                ),
                const SizedBox(height: 24),

                PrimaryButton(label: '应用规则', loading: saving, onPressed: () async {
                  setS(() => saving = true);
                  try {
                    await adminService.batchDepartmentRules(dept['id'], {
                      'require_sign_in': reqSignIn,
                      'require_sign_out': reqSignOut,
                      'require_location': reqLoc,
                      'location_lat': reqLoc && latCtrl.text.isNotEmpty ? double.tryParse(latCtrl.text) : null,
                      'location_lng': reqLoc && lngCtrl.text.isNotEmpty ? double.tryParse(lngCtrl.text) : null,
                      'location_radius': reqLoc && radiusCtrl.text.isNotEmpty ? double.tryParse(radiusCtrl.text) : null,
                      'require_time': reqTime,
                      'checkin_time_start': reqTime ? startCtrl.text : null,
                      'checkin_time_end': reqTime ? endCtrl.text : null,
                      'sign_out_time_start': reqTime ? signOutStartCtrl.text : null,
                      'sign_out_time_end': reqTime ? signOutEndCtrl.text : null,
                      'require_face': reqFace,
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('规则已应用到部门所有成员'), backgroundColor: Color(0xFF059669)),
                      );
                    }
                  } catch (e) {
                    setS(() => saving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete confirm ──
  void _confirmDelete(Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除部门'),
        content: Text('确定删除 ${dept['name']} ？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await adminService.deleteDepartment(dept['id']);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已删除'), backgroundColor: Color(0xFF059669)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}

// ── Department card ──
class _DepartmentCard extends StatelessWidget {
  final Map<String, dynamic> department;
  final VoidCallback onAction;
  const _DepartmentCard({required this.department, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final name = department['name'] as String? ?? '';
    final description = department['description'] as String? ?? '';
    final userCount = department['user_count'] ?? 0;

    return GestureDetector(
      onTap: onAction,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // User count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 14, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 4),
                  Text('$userCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets (same pattern as admin_users_screen) ──
class _RuleToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RuleToggle({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? const Color(0xFFDDD6FE) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: value ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: value ? const Color(0xFF1E293B) : const Color(0xFF64748B)))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
