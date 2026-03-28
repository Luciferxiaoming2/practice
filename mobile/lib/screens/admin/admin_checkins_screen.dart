import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/empty_state.dart';

class AdminCheckinsScreen extends StatefulWidget {
  const AdminCheckinsScreen({super.key});
  @override
  State<AdminCheckinsScreen> createState() => _AdminCheckinsScreenState();
}

class _AdminCheckinsScreenState extends State<AdminCheckinsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _records = await adminService.getCheckins(
        dateFrom: _dateFrom != null ? _fmtDate(_dateFrom!) : null,
        dateTo: _dateTo != null ? _fmtDate(_dateTo!) : null,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      Text('打卡记录', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      SizedBox(height: 4),
                      Text('所有用户的打卡记录', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
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
                    '${_records.length} 条',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                  ),
                ),
              ],
            ),
          ),

          // Date filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _DateChip(
                label: _dateFrom != null ? '${_dateFrom!.month}/${_dateFrom!.day}' : '开始日期',
                active: _dateFrom != null,
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) { _dateFrom = d; _load(); }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
              _DateChip(
                label: _dateTo != null ? '${_dateTo!.month}/${_dateTo!.day}' : '结束日期',
                active: _dateTo != null,
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) { _dateTo = d; _load(); }
                },
              ),
              const Spacer(),
              if (_dateFrom != null || _dateTo != null)
                GestureDetector(
                  onTap: () { _dateFrom = null; _dateTo = null; _load(); },
                  child: const Text('重置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                ),
            ]),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : _error != null
                    ? EmptyState(icon: Icons.cloud_off, title: '加载失败', subtitle: _error, actionLabel: '重试', onAction: _load)
                    : _records.isEmpty
                        ? const EmptyState(icon: Icons.history, title: '暂无打卡记录')
                        : RefreshIndicator(
                            color: const Color(0xFF7C3AED),
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _records.length,
                              itemBuilder: (_, i) => _CheckinCard(record: _records[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _CheckinCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.tryParse(record['timestamp'] ?? '') ?? DateTime.now();
    final status = record['status'] ?? 'ok';
    final isOk = status == 'ok';
    final userName = record['user_name'] ?? record['user']?['full_name'] ?? '用户${record['user_id']}';

    final statusLabel = switch (status) {
      'ok' => '正常',
      'location_fail' => '位置异常',
      'time_fail' => '时间异常',
      'face_fail' => '人脸异常',
      _ => status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOk ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
            ),
            child: Icon(
              isOk ? Icons.check_circle : Icons.error,
              size: 18,
              color: isOk ? const Color(0xFF10B981) : const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(
                  '${ts.month}/${ts.day} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isOk ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isOk ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: isOk ? const Color(0xFF065F46) : const Color(0xFF9A3412),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? const Color(0xFFF5F3FF) : const Color(0xFFF1F5F9),
          border: Border.all(color: active ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFFE2E8F0)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 13, color: active ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? const Color(0xFF7C3AED) : const Color(0xFF64748B)),
          ),
        ]),
      ),
    );
  }
}
