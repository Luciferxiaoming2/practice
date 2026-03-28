import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../providers/auth_provider.dart';
import '../../services/face_service.dart';
import '../../widgets/shared_widgets.dart';

class SetupFaceScreen extends StatefulWidget {
  const SetupFaceScreen({super.key});
  @override
  State<SetupFaceScreen> createState() => _SetupFaceScreenState();
}

class _SetupFaceScreenState extends State<SetupFaceScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _cameraReady = false;
  bool _captured = false;
  bool _loading = false;
  bool _switching = false;
  String? _error;
  String? _capturedPath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _error = '未找到可用摄像头');
        return;
      }
      _cameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      if (mounted) setState(() => _error = '无法访问摄像头，请检查权限');
    }
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

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final xFile = await _controller!.takePicture();
    setState(() {
      _captured = true;
      _capturedPath = xFile.path;
    });
  }

  Future<void> _retake() async {
    setState(() {
      _captured = false;
      _capturedPath = null;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_captured || _capturedPath == null) {
      setState(() => _error = '请先拍摄人脸照片');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 上传照片到后端进行人脸录入
      final success = await FaceService.enrollFace(_capturedPath!);
      if (!success) {
        setState(() => _error = '人脸录入失败，请重试');
        return;
      }
      // 更新本地状态
      final auth = context.read<AuthProvider>();
      await auth.markFaceEnrolled();
      if (mounted) {
        // 延迟一帧确保状态更新后再导航，避免 StatefulShellRoute 路由问题
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          final isAdmin = auth.currentUser?.isAdmin ?? false;
          context.go(isAdmin ? '/admin/users' : '/home');
        }
      }
    } catch (e) {
      String msg = '录入失败，请重试';
      if (e.toString().contains('未检测到人脸')) {
        msg = '未检测到人脸，请确保光线充足且面部清晰';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              StepIndicator(current: 2, total: 2),
              const SizedBox(height: 24),
              const Text('录入人脸', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('请将面部置于框内，确保光线充足', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 24),

              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
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
                                      color: _captured ? Colors.green : Colors.white.withOpacity(0.6),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                              if (_cameras.length > 1 && !_captured)
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
                              if (_captured)
                                Positioned(
                                  bottom: 16, left: 0, right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          SizedBox(width: 6),
                                          Text('已采集', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                        ],
                                      ),
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

              const SizedBox(height: 20),

              if (!_captured)
                OutlinedButton.icon(
                  onPressed: _cameraReady ? _capture : null,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('拍摄'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('重新拍摄'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              PrimaryButton(label: '完成录入', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
