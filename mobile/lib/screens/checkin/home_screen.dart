import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
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
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && !user.faceEnrolled) {
      _showFaceEnrollDialog();
      return;
    }

    // If face verification is required, show face capture first
    if (user != null && user.requireFace) {
      final passed = await _showFaceVerification();
      if (!passed) return;
    }

    final checkin = context.read<CheckinProvider>();
    await checkin.doCheckin(_lat, _lng);
  }

  void _showFaceEnrollDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

                // 人脸未录入提示
                if (user != null && !user.faceEnrolled) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/setup/face'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text('人脸未录入，点击前往录入', style: TextStyle(fontSize: 13, color: Colors.orange.shade800, fontWeight: FontWeight.w500))),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange.shade400),
                      ]),
                    ),
                  ),
                ],

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

/* ── 人脸验证底部弹窗 ──────────────────────────── */
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
    setState(() => _verifying = true);

    await _controller!.takePicture();
    setState(() => _captured = true);

    // Simulate face verification delay (placeholder for real SDK)
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.face, color: Colors.white.withOpacity(0.9), size: 22),
                const SizedBox(width: 10),
                const Text('人脸验证', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Camera preview
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _cameraReady && _controller != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_controller!),
                          // Face guide oval
                          Center(
                            child: Container(
                              width: 200, height: 260,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(120),
                                border: Border.all(
                                  color: _captured ? Colors.green : Colors.white.withOpacity(0.6),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          // Switch camera button
                          if (_cameras.length > 1 && !_verifying)
                            Positioned(
                              top: 12, right: 12,
                              child: GestureDetector(
                                onTap: _switchCamera,
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withOpacity(0.4),
                                  ),
                                  child: const Icon(Icons.cameraswitch_outlined, color: Colors.white, size: 22),
                                ),
                              ),
                            ),
                          // Verifying overlay
                          if (_verifying)
                            Container(
                              color: Colors.black.withOpacity(0.3),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_captured)
                                      Icon(Icons.check_circle, color: Colors.green.shade400, size: 48)
                                    else
                                      CircularProgressIndicator(color: scheme.primary),
                                    const SizedBox(height: 12),
                                    Text(
                                      _captured ? '验证通过' : '正在验证...',
                                      style: TextStyle(
                                        color: _captured ? Colors.green.shade300 : Colors.white,
                                        fontSize: 15, fontWeight: FontWeight.w500,
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
                            CircularProgressIndicator(color: scheme.primary),
                            const SizedBox(height: 12),
                            Text('正在启动相机...', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Hint
          Text(
            '请将面部置于框内，点击按钮验证',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Capture button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_cameraReady && !_verifying) ? _captureAndVerify : null,
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                label: Text(_verifying ? '验证中...' : '拍摄验证'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
