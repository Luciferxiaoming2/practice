import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final checkin = context.watch<CheckinProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('打卡记录')),
      body: Column(
        children: [
          // Date filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _DateChip(
                label: checkin.filterDateFrom != null ? _fmt(checkin.filterDateFrom!) : '开始日期',
                active: checkin.filterDateFrom != null,
                onTap: () async {
                  final d = await showDatePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
                  if (d != null) checkin.setDateFilter(d, checkin.filterDateTo);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(color: scheme.onSurface.withOpacity(0.4))),
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
                TextButton(onPressed: checkin.clearFilter, child: const Text('重置', style: TextStyle(fontSize: 13))),
            ]),
          ),

          // List
          Expanded(
            child: checkin.loading
                ? const Center(child: CircularProgressIndicator())
                : checkin.error != null
                    ? EmptyState(icon: Icons.cloud_off, title: '加载失败', subtitle: checkin.error, actionLabel: '重试', onAction: () => checkin.loadHistory())
                    : checkin.records.isEmpty
                        ? const EmptyState(icon: Icons.history, title: '暂无打卡记录', subtitle: '打卡后记录会显示在这里')
                        : RefreshIndicator(
                            onRefresh: () => checkin.loadHistory(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: checkin.records.length,
                              itemBuilder: (_, i) {
                                final r = checkin.records[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: scheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (r.isSuccess ? Colors.green : scheme.error).withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        r.isSuccess ? Icons.check : Icons.close,
                                        color: r.isSuccess ? Colors.green.shade600 : scheme.error, size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r.timestamp.month}月${r.timestamp.day}日 ${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        if (r.lat != null && r.lng != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${r.lat!.toStringAsFixed(4)}, ${r.lng!.toStringAsFixed(4)}',
                                            style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.4)),
                                          ),
                                        ],
                                      ],
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: (r.isSuccess ? Colors.green : scheme.error).withOpacity(0.1),
                                      ),
                                      child: Text(
                                        r.statusLabel,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: r.isSuccess ? Colors.green.shade700 : scheme.error),
                                      ),
                                    ),
                                  ]),
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

class _DateChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DateChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: active ? scheme.primary.withOpacity(0.1) : scheme.surfaceContainerHighest.withOpacity(0.5),
          border: Border.all(color: active ? scheme.primary.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 14, color: active ? scheme.primary : scheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: active ? scheme.primary : scheme.onSurface.withOpacity(0.5))),
        ]),
      ),
    );
  }
}
