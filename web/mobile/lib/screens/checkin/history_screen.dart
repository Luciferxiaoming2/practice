import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/checkin.dart';
import '../../providers/checkin_provider.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CheckinProvider>().loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final checkin = context.watch<CheckinProvider>();
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '打卡记录',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${now.year}年${now.month}月',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Date filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              _DateChip(
                label: checkin.filterDateFrom != null ? _fmt(checkin.filterDateFrom!) : '开始日期',
                active: checkin.filterDateFrom != null,
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) checkin.setDateFilter(d, checkin.filterDateTo);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ),
              _DateChip(
                label: checkin.filterDateTo != null ? _fmt(checkin.filterDateTo!) : '结束日期',
                active: checkin.filterDateTo != null,
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) checkin.setDateFilter(checkin.filterDateFrom, d);
                },
              ),
              const Spacer(),
              if (checkin.filterDateFrom != null || checkin.filterDateTo != null)
                GestureDetector(
                  onTap: checkin.clearFilter,
                  child: const Text('重置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                ),
            ]),
          ),

          // Stats summary
          if (!checkin.loading && checkin.error == null && checkin.records.isNotEmpty)
            _StatsSummary(records: checkin.records),

          // List
          Expanded(
            child: checkin.loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                : checkin.error != null
                    ? EmptyState(icon: Icons.cloud_off, title: '加载失败', subtitle: checkin.error, actionLabel: '重试', onAction: () => checkin.loadHistory())
                    : checkin.records.isEmpty
                        ? const EmptyState(icon: Icons.history, title: '暂无打卡记录', subtitle: '打卡后记录会显示在这里')
                        : RefreshIndicator(
                            color: const Color(0xFF7C3AED),
                            onRefresh: () => checkin.loadHistory(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: checkin.records.length,
                              itemBuilder: (_, i) {
                                final r = checkin.records[i];
                                final isLast = i == checkin.records.length - 1;
                                return _TimelineItem(
                                  isSuccess: r.isSuccess,
                                  time: '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                                  date: '${r.timestamp.month}月${r.timestamp.day}日',
                                  status: r.statusLabel,
                                  location: r.lat != null && r.lng != null
                                      ? '${r.lat!.toStringAsFixed(4)}, ${r.lng!.toStringAsFixed(4)}'
                                      : null,
                                  showLine: !isLast,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

// ── Timeline item ──
class _TimelineItem extends StatelessWidget {
  final bool isSuccess;
  final String time;
  final String date;
  final String status;
  final String? location;
  final bool showLine;

  const _TimelineItem({
    required this.isSuccess,
    required this.time,
    required this.date,
    required this.status,
    this.location,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isSuccess ? const Color(0xFF10B981) : const Color(0xFFF97316);
    final dotBgColor = isSuccess ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5);
    final statusColor = isSuccess ? const Color(0xFF065F46) : const Color(0xFF9A3412);
    final statusBg = isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);
    final statusBorder = isSuccess ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot & line
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotBgColor,
                    border: Border.all(color: const Color(0xFFF8FAFC), width: 3),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    size: 18,
                    color: dotColor,
                  ),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Text(
                          isSuccess ? '正常打卡' : status,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  if (location != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(location!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date chip ──
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
          border: Border.all(
            color: active ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 13, color: active ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Stats summary ──
class _StatsSummary extends StatelessWidget {
  final List<CheckIn> records;
  const _StatsSummary({required this.records});

  @override
  Widget build(BuildContext context) {
    final total = records.length;
    final success = records.where((r) => r.isSuccess).length;
    final fail = total - success;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.12)),
      ),
      child: Row(
        children: [
          _StatItem(label: '总计', value: '$total', color: const Color(0xFF7C3AED)),
          _statDivider(),
          _StatItem(label: '正常', value: '$success', color: const Color(0xFF10B981)),
          _statDivider(),
          _StatItem(label: '异常', value: '$fail', color: const Color(0xFFF97316)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: const Color(0xFF7C3AED).withOpacity(0.1),
      );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
