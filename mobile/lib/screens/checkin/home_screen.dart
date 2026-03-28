import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  double? _lat;
  double? _lng;
  String? _address;
  bool _locationReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final granted = await _locationService.requestPermission();
    if (!granted) return;
    _locationService.onLocationChanged = (lat, lng, address) {
      if (mounted) {
        setState(() {
          _lat = lat;
          _lng = lng;
          _address = address;
          _locationReady = true;
        });
      }
    };
    _locationService.startListening();
  }

  @override
  void dispose() {
    _locationService.stopListening();
    super.dispose();
  }

  Future<void> _doCheckin() async {
    final checkin = context.read<CheckinProvider>();
    await checkin.doCheckin(_lat, _lng);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().currentUser;
    final checkin = context.watch<CheckinProvider>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '上午好' : (hour < 18 ? '下午好' : '晚上好');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [scheme.primary.withOpacity(0.08), scheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Greeting
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$greeting，${user?.fullName ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_todayStr(), style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.5))),
                    ],
                  )),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withOpacity(0.7)]),
                    ),
                    child: Center(child: Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    )),
                  ),
                ]),

                const SizedBox(height: 24),

                // Location card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, color: _locationReady ? scheme.primary : scheme.onSurface.withOpacity(0.3), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      _locationReady
                          ? (_address ?? '${_lat?.toStringAsFixed(4)}, ${_lng?.toStringAsFixed(4)}')
                          : '正在获取定位...',
                      style: TextStyle(fontSize: 13, color: _locationReady ? scheme.onSurface : scheme.onSurface.withOpacity(0.4)),
                    )),
                    if (_locationReady) Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
                  ]),
                ),

                const Spacer(),

                // Check-in button
                GestureDetector(
                  onTap: checkin.checkinLoading ? null : _doCheckin,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: checkin.checkinSuccess && checkin.checkinResult != null
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.3)!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (checkin.checkinSuccess && checkin.checkinResult != null ? Colors.green : scheme.primary).withOpacity(0.4),
                          blurRadius: 24, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(child: checkin.checkinLoading
                        ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              checkin.checkinSuccess && checkin.checkinResult != null ? Icons.check : Icons.fingerprint,
                              color: Colors.white, size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              checkin.checkinSuccess && checkin.checkinResult != null ? '已打卡' : '打卡',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ])),
                  ),
                ),

                const SizedBox(height: 24),

                // Result
                if (checkin.checkinResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: (checkin.checkinSuccess ? Colors.green : scheme.error).withOpacity(0.1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        checkin.checkinSuccess ? Icons.check_circle_outline : Icons.error_outline,
                        color: checkin.checkinSuccess ? Colors.green.shade600 : scheme.error, size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        checkin.checkinResult!,
                        style: TextStyle(color: checkin.checkinSuccess ? Colors.green.shade700 : scheme.error, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ),

                const Spacer(),

                // Rules summary
                if (user != null) _RulesSummary(user: user),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    const weeks = ['一', '二', '三', '四', '五', '六', '日'];
    return '${now.month}月${now.day}日 周${weeks[now.weekday - 1]}';
  }
}

class _RulesSummary extends StatelessWidget {
  final dynamic user;
  const _RulesSummary({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rules = <_Rule>[];
    if (user.requireLocation) {
      rules.add(_Rule(Icons.location_on_outlined, '位置验证', '${user.locationRadius?.toInt() ?? 0}m 范围内'));
    }
    if (user.requireTime) {
      rules.add(_Rule(Icons.schedule_outlined, '时间限制', '${user.checkinTimeStart ?? ''} - ${user.checkinTimeEnd ?? ''}'));
    }
    if (user.requireFace) {
      rules.add(_Rule(Icons.face_outlined, '人脸验证', '需要人脸识别'));
    }
    if (rules.isEmpty) {
      rules.add(_Rule(Icons.check_circle_outline, '无特殊要求', '随时随地可打卡'));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('打卡规则', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 10),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(r.icon, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(r.detail, style: TextStyle(fontSize: 12, color: scheme.onSurface.withOpacity(0.5))),
                ]),
              )),
        ],
      ),
    );
  }
}

class _Rule {
  final IconData icon;
  final String label;
  final String detail;
  _Rule(this.icon, this.label, this.detail);
}
