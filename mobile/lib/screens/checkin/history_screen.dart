import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/api.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    try {
      final res = await dio.get('/checkins/', queryParameters: {'user_id': user.id});
      setState(() => _records = res.data as List);
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  String _fmtTime(String ts) {
    final d = DateTime.tryParse(ts);
    if (d == null) return ts;
    return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'ok': return '正常';
      case 'location_fail': return '位置异常';
      case 'time_fail': return '时间异常';
      case 'face_fail': return '人脸异常';
      default: return s;
    }
  }

  Color _statusColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'ok': return Colors.green;
      case 'location_fail': return scheme.error;
      case 'time_fail': return Colors.orange;
      case 'face_fail': return scheme.error;
      default: return scheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('打卡记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Text('暂无打卡记录', style: TextStyle(color: scheme.onSurface.withOpacity(0.4))),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final r = _records[i];
                      final status = r['status'] ?? 'ok';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: scheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              status == 'ok' ? Icons.check_circle_outline : Icons.error_outline,
                              color: _statusColor(status, scheme),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fmtTime(r['timestamp'] ?? ''),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  if (r['lat'] != null && r['lng'] != null)
                                    Text(
                                      '${(r['lat'] as num).toStringAsFixed(4)}, ${(r['lng'] as num).toStringAsFixed(4)}',
                                      style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.4)),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: _statusColor(status, scheme).withOpacity(0.1),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _statusColor(status, scheme),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
