import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/simple_location_picker.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  List<Map<String, dynamic>> _roles = [];
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
      final results = await Future.wait([
        adminService.getUsers(),
        adminService.getRoles(),
        adminService.getDepartments(),
      ]);
      _users = (results[0] as List).map((j) => User.fromJson(j)).toList();
      _roles = List<Map<String, dynamic>>.from(results[1] as List);
      _departments = List<Map<String, dynamic>>.from(results[2] as List);
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
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: const Text('新建账户', style: TextStyle(fontWeight: FontWeight.w700)),
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
                      Text('账户管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('管理所有用户账户', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
                    '${_users.length} 人',
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
                    : _users.isEmpty
                        ? const EmptyState(icon: Icons.people_outline, title: '暂无用户')
                        : RefreshIndicator(
                            color: const Color(0xFF7C3AED),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                              itemCount: _users.length,
                              itemBuilder: (_, i) => _UserCard(
                                user: _users[i],
                                onAction: () => _showActionSheet(_users[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ── User action sheet ──
  void _showActionSheet(User user) {
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
                  _avatar(user, 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      Text('@${user.username}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _ActionTile(icon: Icons.edit, label: '编辑用户', color: const Color(0xFF059669), onTap: () {
              Navigator.pop(ctx);
              _showEditSheet(user);
            }),
            _ActionTile(icon: Icons.tune, label: '打卡规则', color: const Color(0xFF7C3AED), onTap: () {
              Navigator.pop(ctx);
              _showRulesSheet(user);
            }),
            _ActionTile(icon: Icons.lock_reset, label: '重置密码', color: const Color(0xFF2563EB), onTap: () {
              Navigator.pop(ctx);
              _showResetPasswordSheet(user);
            }),
            _ActionTile(icon: Icons.face_retouching_off, label: '重置人脸', color: const Color(0xFFF59E0B), onTap: () {
              Navigator.pop(ctx);
              _confirmResetFace(user);
            }),
            _ActionTile(icon: Icons.delete_outline, label: '删除账户', color: Colors.red, onTap: () {
              Navigator.pop(ctx);
              _confirmDelete(user);
            }),
          ],
        ),
      ),
    );
  }

  // ── Create user ──
  void _showCreateSheet() {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    int? selectedRoleId = _roles.isNotEmpty ? _roles.last['id'] : null;
    int? selectedDepartmentId;
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
                const Text('新建账户', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 20),
                AppTextField(label: '用户名', controller: usernameCtrl, prefixIcon: Icons.person_outline),
                const SizedBox(height: 14),
                AppTextField(label: '姓名', controller: nameCtrl, prefixIcon: Icons.badge_outlined),
                const SizedBox(height: 14),
                AppTextField(label: '初始密码', controller: pwdCtrl, obscure: true, prefixIcon: Icons.lock_outline),
                const SizedBox(height: 14),
                // Role selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedRoleId,
                      isExpanded: true,
                      hint: const Text('选择角色'),
                      items: _roles.map((r) => DropdownMenuItem<int>(
                        value: r['id'],
                        child: Text(r['name'] ?? ''),
                      )).toList(),
                      onChanged: (v) => setS(() => selectedRoleId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Department selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedDepartmentId,
                      isExpanded: true,
                      hint: const Text('选择部门'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('无部门')),
                        ..._departments.map((d) => DropdownMenuItem<int?>(
                          value: d['id'],
                          child: Text(d['name'] ?? ''),
                        )),
                      ],
                      onChanged: (v) => setS(() => selectedDepartmentId = v),
                    ),
                  ),
                ),
                if (msg != null) ...[
                  const SizedBox(height: 12),
                  Text(msg!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                ],
                const SizedBox(height: 20),
                PrimaryButton(label: '创建', loading: saving, onPressed: () async {
                  final username = usernameCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final pwd = pwdCtrl.text.trim();
                  if (username.isEmpty || name.isEmpty || pwd.isEmpty) {
                    setS(() => msg = '请填写所有字段');
                    return;
                  }
                  setS(() { saving = true; msg = null; });
                  try {
                    await adminService.createUser(
                      username: username,
                      fullName: name,
                      password: pwd,
                      roleId: selectedRoleId,
                      departmentId: selectedDepartmentId,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('账户创建成功'), backgroundColor: Color(0xFF059669)),
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

  // ── Edit user ──
  void _showEditSheet(User user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    int? selectedRoleId = user.roleId ?? (_roles.isNotEmpty ? _roles.last['id'] : null);
    int? selectedDepartmentId = user.departmentId;
    bool isActive = user.isActive;
    bool saving = false;
    String? msg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('编辑用户 - ${user.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  const SizedBox(height: 20),
                  AppTextField(label: '姓名', controller: nameCtrl, prefixIcon: Icons.badge_outlined),
                  const SizedBox(height: 14),
                  // Role selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedRoleId,
                        isExpanded: true,
                        hint: const Text('选择角色'),
                        items: _roles.map((r) => DropdownMenuItem<int>(
                          value: r['id'],
                          child: Text(r['name'] ?? ''),
                        )).toList(),
                        onChanged: (v) => setS(() => selectedRoleId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Department selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: selectedDepartmentId,
                        isExpanded: true,
                        hint: const Text('选择部门'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('无部门')),
                          ..._departments.map((d) => DropdownMenuItem<int?>(
                            value: d['id'],
                            child: Text(d['name'] ?? ''),
                          )),
                        ],
                        onChanged: (v) => setS(() => selectedDepartmentId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Active toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.toggle_on_outlined, size: 20, color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('账户激活', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isActive ? const Color(0xFF1E293B) : const Color(0xFF64748B)))),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setS(() => isActive = v),
                          activeColor: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ),
                  if (msg != null) ...[
                    const SizedBox(height: 12),
                    Text(msg!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(label: '保存', loading: saving, onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      setS(() => msg = '请填写姓名');
                      return;
                    }
                    setS(() { saving = true; msg = null; });
                    try {
                      await adminService.updateUser(user.id, {
                        'full_name': name,
                        'role_id': selectedRoleId,
                        'department_id': selectedDepartmentId,
                        'is_active': isActive,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('用户信息已更新'), backgroundColor: Color(0xFF059669)),
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
      ),
    );
  }

  // ── Rules sheet ──
  void _showRulesSheet(User user) {
    bool reqSignIn = user.requireSignIn;
    bool reqSignOut = user.requireSignOut;
    bool reqLoc = user.requireLocation;
    bool reqTime = user.requireTime;
    bool reqFace = user.requireFace;
    final latCtrl = TextEditingController(text: user.locationLat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: user.locationLng?.toString() ?? '');
    final radiusCtrl = TextEditingController(text: user.locationRadius?.toString() ?? '200');
    final startCtrl = TextEditingController(text: user.checkinTimeStart ?? '');
    final endCtrl = TextEditingController(text: user.checkinTimeEnd ?? '');
    final signOutStartCtrl = TextEditingController(text: user.signOutTimeStart ?? '');
    final signOutEndCtrl = TextEditingController(text: user.signOutTimeEnd ?? '');
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
                Text('打卡规则 - ${user.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
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
                  SimpleLocationPicker(
                    initialLat: user.locationLat,
                    initialLng: user.locationLng,
                    radius: user.locationRadius ?? 200,
                    onLocationSelected: (lat, lng, address) {
                      latCtrl.text = lat.toString();
                      lngCtrl.text = lng.toString();
                    },
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    label: '打卡半径(米)',
                    controller: radiusCtrl,
                    prefixIcon: Icons.radar,
                    hint: '200',
                  ),
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

                PrimaryButton(label: '保存规则', loading: saving, onPressed: () async {
                  setS(() => saving = true);
                  try {
                    await adminService.updateUser(user.id, {
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
                        const SnackBar(content: Text('规则已更新'), backgroundColor: Color(0xFF059669)),
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

  // ── Reset password ──
  void _showResetPasswordSheet(User user) {
    final pwdCtrl = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('重置密码 - ${user.fullName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              AppTextField(label: '新密码', controller: pwdCtrl, obscure: true, prefixIcon: Icons.lock_outline),
              if (msg != null) ...[
                const SizedBox(height: 12),
                Text(msg!, style: TextStyle(fontSize: 13, color: Colors.red.shade600)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: '确认重置', loading: saving, onPressed: () async {
                if (pwdCtrl.text.trim().isEmpty) {
                  setS(() => msg = '请输入新密码');
                  return;
                }
                setS(() { saving = true; msg = null; });
                try {
                  await adminService.resetPassword(user.id, pwdCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码已重置'), backgroundColor: Color(0xFF059669)),
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
    );
  }

  // ── Reset face confirm ──
  void _confirmResetFace(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('重置人脸'),
        content: Text('确定重置 ${user.fullName} 的人脸数据？\n账户将被设为未激活，需重新录入人脸。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await adminService.resetFace(user.id);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('人脸已重置'), backgroundColor: Color(0xFF059669)),
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }

  // ── Delete confirm ──
  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('删除账户'),
        content: Text('确定删除 ${user.fullName} ？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await adminService.deleteUser(user.id);
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

  Widget _avatar(User user, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: user.isAdmin
              ? [const Color(0xFFA78BFA), const Color(0xFF7C3AED)]
              : [const Color(0xFF93C5FD), const Color(0xFF3B82F6)],
        ),
      ),
      child: Center(
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0] : '?',
          style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── User card ──
class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onAction;
  const _UserCard({required this.user, required this.onAction});

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: user.isAdmin
                      ? [const Color(0xFFA78BFA), const Color(0xFF7C3AED)]
                      : [const Color(0xFF93C5FD), const Color(0xFF3B82F6)],
                ),
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0] : '?',
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(user.fullName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      if (user.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: const Text('管理员', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('@${user.username}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      if (user.departmentName != null && user.departmentName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Text(user.departmentName!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF9A3412))),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _StatusBadge(active: user.isActive),
                      if (user.faceEnrolled) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.face, size: 14, color: Color(0xFF10B981)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Rules indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (user.requireLocation) const Icon(Icons.location_on, size: 14, color: Color(0xFF059669)),
                  if (user.requireTime) const Icon(Icons.schedule, size: 14, color: Color(0xFF2563EB)),
                  if (user.requireFace) const Icon(Icons.face, size: 14, color: Color(0xFF7C3AED)),
                ]),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD1FAE5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Text(
        active ? '已激活' : '未激活',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: active ? const Color(0xFF065F46) : const Color(0xFF991B1B)),
      ),
    );
  }
}

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
