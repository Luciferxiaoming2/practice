import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../providers/auth_provider.dart';
import '../../providers/checkin_provider.dart';
import '../../services/location_service.dart';
import '../../services/face_service.dart';

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
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  String _checkinType = 'sign_in';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // 进入页面时检查今日打卡状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTodayCheckin();
    });
  }

  Future<void> _checkTodayCheckin() async {
    final checkin = context.read<CheckinProvider>();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await checkin.loadHistory(dateFrom: dateStr, dateTo: dateStr);
  }

  Future<void> _initLocation() async {
    final granted = await _locationService.requestPermission();
    if (!granted) {
      debugPrint('[HomeScreen] Location permission denied, retrying in 3s...');
      // 权限被拒，3秒后重试（用户可能正在授权对话框上）
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_locationReady) _initLocation();
      });
      return;
    }
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
    debugPrint('[HomeScreen] Location listening started');
  }

  @override
  void dispose() {
    _locationService.stopListening();
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _doCheckin() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && !user.faceEnrolled) {
      _showFaceEnrollDialog();
      return;
    }
    if (user != null && user.requireFace) {
      final passed = await _showFaceVerification();
      if (!passed) return;
    }
    final checkin = context.read<CheckinProvider>();
    await checkin.doCheckin(_lat, _lng, type: _checkinType);
  }

  void _showFaceEnrollDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('请先录入人脸'),
        content: const Text('打卡前需要完成人脸录入，是否现在去录入？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('稍后')),
          FilledButton(onPressed: () { Navigator.pop(ctx); context.go('/setup/face'); }, child: const Text('去录入')),
        ],
      ),
    );
  }

  Future<bool> _showFaceVerification() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FaceVerificationSheet(),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final checkin = context.watch<CheckinProvider>();
    final hour = _now.hour;
    final greeting = hour < 12 ? '早安' : (hour < 18 ? '下午好' : '晚上好');
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final screenH = MediaQuery.of(context).size.height;
    final mapH = screenH * 0.45;
    final sheetTop = screenH * 0.45;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Map background (top 45%) ──
          Positioned(
            top: 0, left: 0, right: 0, height: mapH + 40, // +40 留出被 sheet 遮住的过渡区
            child: Container(
              color: const Color(0xFFE2E8F0),
              child: Stack(
                children: [
                  if (_locationReady && _lat != null && _lng != null)
                    Positioned.fill(
                      child: Image.network(
                        'https://restapi.amap.com/v3/staticmap'
                        '?location=${_lng!.toStringAsFixed(6)},${_lat!.toStringAsFixed(6)}'
                        '&zoom=15&size=750*500&scale=2'
                        '&markers=mid,0x7C3AED,A:${_lng!.toStringAsFixed(6)},${_lat!.toStringAsFixed(6)}'
                        '&key=66947be73f9b49d62c7db4de4f8de9f2',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => CustomPaint(painter: _MapGridPainter()),
                      ),
                    )
                  else
                    Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
                  // Purple tint
                  Positioned.fill(
                    child: Container(color: const Color(0xFF7C3AED).withValues(alpha: 0.05)),
                  ),
                  // Top gradient
                  Positioned(
                    left: 0, right: 0, top: 0, height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  // Bottom gradient (fades into white sheet)
                  Positioned(
                    left: 0, right: 0, bottom: 0, height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.white.withValues(alpha: 0.9)],
                        ),
                      ),
                    ),
                  ),
                  // Range circle
                  Center(
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                  // "打卡范围" badge
                  Positioned(
                    top: topPadding + 80, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Text('打卡范围', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Floating header ──
          Positioned(
            top: topPadding + 8, left: 16, right: 16,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$greeting，${user?.fullName ?? ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _address ?? '定位中...',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF334155))),
                      Positioned(
                        top: 10, right: 10,
                        child: Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 3. Bottom sheet (white, rounded top) ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            top: sheetTop,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -8))],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 24, right: 24, top: 80, bottom: bottomPadding + 12),
                child: Column(
                  children: [
                    // Clock
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w200,
                        color: Color(0xFF1E293B),
                        letterSpacing: -1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _todayStr(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Sign-in / Sign-out toggle
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _checkinType = 'sign_in'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: _checkinType == 'sign_in'
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(11),
                                  bottomLeft: Radius.circular(11),
                                ),
                              ),
                              child: Text(
                                '签到',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _checkinType == 'sign_in'
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _checkinType = 'sign_out'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                color: _checkinType == 'sign_out'
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(11),
                                  bottomRight: Radius.circular(11),
                                ),
                              ),
                              child: Text(
                                '签退',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _checkinType == 'sign_out'
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Result message
                    if (checkin.checkinResult != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: (checkin.checkinSuccess ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.08),
                          border: Border.all(
                            color: (checkin.checkinSuccess ? const Color(0xFF10B981) : Colors.red).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            checkin.checkinSuccess ? Icons.check_circle_outline : Icons.error_outline,
                            color: checkin.checkinSuccess ? const Color(0xFF059669) : Colors.red.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            checkin.checkinResult!,
                            style: TextStyle(
                              color: checkin.checkinSuccess ? const Color(0xFF059669) : Colors.red.shade700,
                              fontSize: 13, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                      ),
                    ],

                    // Face enroll warning
                    if (user != null && !user.faceEnrolled) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.go('/setup/face'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Row(children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('人脸未录入，点击前往录入',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9A3412), fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange.shade400),
                          ]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Status cards
                    if (user != null) _StatusCards(user: user, locationReady: _locationReady),
                  ],
                ),
              ),
            ),
          ),

          // ── 4. Check-in button (overlapping map and sheet junction) ──
          Positioned(
            top: sheetTop - 70,
            left: 0, right: 0,
            child: Center(
              child: _CheckInButton(
                state: checkin.checkinLoading
                    ? _CheckInState.scanning
                    : (_hasTodayCheckin(checkin) || (checkin.checkinSuccess && checkin.checkinResult != null))
                        ? _CheckInState.success
                        : _CheckInState.idle,
                onTap: _doCheckin,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
    const weeks = ['一', '二', '三', '四', '五', '六', '日'];
    return '${_now.month}月${_now.day}日 周${weeks[_now.weekday - 1]}';
  }

  bool _hasTodayCheckin(CheckinProvider checkin) {
    if (checkin.records.isEmpty) return false;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    // 检查是否有今天的打卡记录（根据当前选择的类型）
    return checkin.records.any((r) {
      final recordDate = r.timestamp.toIso8601String().substring(0, 10);
      final recordType = r.type ?? 'sign_in';
      return recordDate == todayStr && recordType == _checkinType;
    });
  }
}

// ── Check-in button states ──
enum _CheckInState { idle, scanning, success }

class _CheckInButton extends StatelessWidget {
  final _CheckInState state;
  final VoidCallback onTap;
  const _CheckInButton({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state == _CheckInState.idle ? onTap : null,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (state == _CheckInState.idle) ...[
              _PulseRing(size: 140, delay: 0),
              _PulseRing(size: 126, delay: 1000),
            ],
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state == _CheckInState.success
                    ? const Color(0xFFF0FDF4)
                    : state == _CheckInState.scanning
                        ? const Color(0xFFF5F3FF)
                        : Colors.white,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: state == _CheckInState.success
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (state) {
      case _CheckInState.idle:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDE9FE)),
              child: const Icon(Icons.face_outlined, size: 24, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 4),
            const Text('立即打卡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          ],
        );
      case _CheckInState.scanning:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: const Color(0xFF7C3AED).withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            const Text('检测中', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED), letterSpacing: 2)),
          ],
        );
      case _CheckInState.success:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD1FAE5)),
              child: const Icon(Icons.check_circle, size: 28, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 4),
            const Text('已打卡', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
          ],
        );
    }
  }
}

// ── Pulse ring animation ──
class _PulseRing extends StatefulWidget {
  final double size;
  final int delay; // milliseconds
  const _PulseRing({required this.size, required this.delay});
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (widget.delay > 0) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) _ctrl.repeat();
      });
    } else {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + _ctrl.value * 0.25;
        final opacity = (1.0 - _ctrl.value).clamp(0.0, 0.4);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE9D5FF), width: 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Status cards ──
class _StatusCards extends StatelessWidget {
  final dynamic user;
  final bool locationReady;
  const _StatusCards({required this.user, required this.locationReady});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            icon: Icons.location_on_outlined,
            label: '定位围栏',
            value: user.requireLocation ? (locationReady ? '已在范围内' : '定位中...') : '未要求',
            iconColor: const Color(0xFF059669),
            valueColor: locationReady ? const Color(0xFF065F46) : const Color(0xFF64748B),
            valueBg: locationReady ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusCard(
            icon: Icons.schedule_outlined,
            label: '时间窗口',
            value: user.requireTime ? '${user.checkinTimeStart ?? ''}-${user.checkinTimeEnd ?? ''}' : '未要求',
            iconColor: const Color(0xFF059669),
            valueColor: const Color(0xFF065F46),
            valueBg: const Color(0xFFD1FAE5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatusCard(
            icon: Icons.shield_outlined,
            label: '人脸验证',
            value: user.requireFace ? '要求活体' : '未要求',
            iconColor: const Color(0xFF7C3AED),
            valueColor: const Color(0xFF5B21B6),
            valueBg: const Color(0xFFEDE9FE),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color valueColor;
  final Color valueBg;
  const _StatusCard({
    required this.icon, required this.label, required this.value,
    required this.iconColor, required this.valueColor, required this.valueBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: valueBg.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
            child: Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: valueColor),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/* ── Face verification bottom sheet ──────────────────────────── */
class _FaceVerificationSheet extends StatefulWidget {
  const _FaceVerificationSheet();
  @override
  State<_FaceVerificationSheet> createState() => _FaceVerificationSheetState();
}

class _FaceVerificationSheetState extends State<_FaceVerificationSheet> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraReady = false;
  bool _captured = false;
  bool _verifying = false;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    _cameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
    if (_cameraIndex < 0) _cameraIndex = 0;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    await _controller?.dispose();
    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) setState(() { _cameraReady = true; _switching = false; });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _switching) return;
    setState(() { _switching = true; _cameraReady = false; });
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() { _verifying = true; _error = null; });
    final xFile = await _controller!.takePicture();

    try {
      final (matched, similarity) = await FaceService.verifyFace(xFile.path);
      if (matched) {
        setState(() => _captured = true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _verifying = false;
          _error = '人脸不匹配 (${(similarity * 100).toStringAsFixed(0)}%)，请重试';
        });
      }
    } catch (e) {
      String msg = '验证失败，请重试';
      if (e.toString().contains('未检测到人脸')) {
        msg = '未检测到人脸，请正对摄像头';
      } else if (e.toString().contains('尚未录入')) {
        msg = '请先录入人脸';
      }
      setState(() { _verifying = false; _error = msg; });
    }
  }

  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.face_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('人脸验证', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                    child: const Icon(Icons.close, color: Colors.white60, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: _cameraReady && _controller != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_controller!),
                        Center(
                          child: Container(
                            width: 200, height: 260,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(120),
                              border: Border.all(
                                color: _captured ? const Color(0xFF10B981) : Colors.white.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        if (_cameras.length > 1 && !_verifying)
                          Positioned(
                            top: 12, right: 12,
                            child: GestureDetector(
                              onTap: _switchCamera,
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.4)),
                                child: const Icon(Icons.cameraswitch_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        if (_verifying)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_captured)
                                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48)
                                  else
                                    const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _captured ? '验证通过' : '正在验证...',
                                    style: TextStyle(
                                      color: _captured ? const Color(0xFF6EE7B7) : Colors.white,
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                          const SizedBox(height: 12),
                          Text('正在启动相机...', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_error!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            )
          else
            Text('请将面部置于框内，点击按钮验证', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: (_cameraReady && !_verifying) ? _captureAndVerify : null,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(_verifying ? '验证中...' : '拍摄验证'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF7C3AED).withOpacity(0.4),
                  disabledForegroundColor: Colors.white60,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ── Map grid painter ──
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1).withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
