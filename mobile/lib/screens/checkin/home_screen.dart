import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../core/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checking = false;
  String? _result;
  bool _success = false;

  Future<void> _doCheckin() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() { _checking = true; _result = null; });

    try {
      double? lat, lng;

      // Location check
      if (user.requireLocation) {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;

        if (user.locationLat != null && user.locationLng != null && user.locationRadius != null) {
          final dist = Geolocator.distanceBetween(lat, lng, user.locationLat!, user.locationLng!);
          if (dist > user.locationRadius!) {
            setState(() { _result = '不在允许打卡范围内（距离 ${dist.toStringAsFixed(0)}m）'; _success = false; });
            return;
          }
        }
      }

      // Time check
      if (user.requireTime && user.checkinTimeStart != null && user.checkinTimeEnd != null) {
        final now = TimeOfDay.now();
        final start = _parseTime(user.checkinTimeStart!);
        final end = _parseTime(user.checkinTimeEnd!);
        final nowMin = now.hour * 60 + now.minute;
        final startMin = start.hour * 60 + start.minute;
        final endMin = end.hour * 60 + end.minute;
        if (nowMin < startMin || nowMin > endMin) {
          setState(() { _result = '不在允许打卡时间段内'; _success = false; });
          return;
        }
      }

      // Submit checkin
      await dio.post('/checkins/', data: {
        'user_id': user.id,
        'lat': lat,
        'lng': lng,
        'status': 'ok',
      });

      setState(() { _result = '打卡成功 ✓'; _success = true; });
    } catch (e) {
      setState(() { _result = '打卡失败，请重试'; _success = false; });
    } finally {
      setState(() => _checking = false);
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary.withOpacity(0.06), scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('你好，${user?.fullName ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(_todayString(), style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/history'),
                          icon: CircleAvatar(
                            backgroundColor: scheme.primary.withOpacity(0.12),
                            child: Icon(Icons.history, color: scheme.primary, size: 20),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/profile'),
                          icon: CircleAvatar(
                            backgroundColor: scheme.primary.withOpacity(0.12),
                            child: Icon(Icons.person_outline, color: scheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Checkin button
                Center(
                  child: GestureDetector(
                    onTap: _checking ? null : _doCheckin,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _success
                              ? [Colors.green.shade400, Colors.green.shade700]
                              : [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.3)!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_success ? Colors.green : scheme.primary).withOpacity(0.4),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: _checking
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_success ? Icons.check_circle_outline : Icons.fingerprint, color: Colors.white, size: 52),
                                const SizedBox(height: 8),
                                const Text('点击打卡', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Result
                if (_result != null)
                  AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _success ? Colors.green.withOpacity(0.1) : scheme.error.withOpacity(0.1),
                      ),
                      child: Text(
                        _result!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _success ? Colors.green.shade700 : scheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                const Spacer(),

                // Rules summary
                if (user != null) _RulesSummary(user: user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}年${now.month}月${now.day}日';
  }
}

class _RulesSummary extends StatelessWidget {
  final dynamic user;
  const _RulesSummary({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest.withOpacity(0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('打卡要求', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 8),
          _RuleRow(icon: Icons.location_on_outlined, label: '地点验证', enabled: user.requireLocation),
          _RuleRow(icon: Icons.access_time_outlined, label: '时间限制', enabled: user.requireTime),
          _RuleRow(icon: Icons.face_outlined, label: '人脸识别', enabled: user.requireFace),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  const _RuleRow({required this.icon, required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: enabled ? scheme.primary : scheme.onSurface.withOpacity(0.3)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, color: enabled ? scheme.onSurface : scheme.onSurface.withOpacity(0.3))),
          const Spacer(),
          Text(enabled ? '已开启' : '未要求', style: TextStyle(fontSize: 12, color: enabled ? scheme.primary : scheme.onSurface.withOpacity(0.3))),
        ],
      ),
    );
  }
}
