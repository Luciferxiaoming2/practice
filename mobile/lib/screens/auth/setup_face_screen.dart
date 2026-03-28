import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

class SetupFaceScreen extends StatefulWidget {
  const SetupFaceScreen({super.key});
  @override
  State<SetupFaceScreen> createState() => _SetupFaceScreenState();
}

class _SetupFaceScreenState extends State<SetupFaceScreen> {
  XFile? _photo;
  bool _loading = false;
  String? _error;

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.front);
    if (img != null) setState(() => _photo = img);
  }

  Future<void> _submit() async {
    if (_photo == null) {
      setState(() => _error = '请先拍摄人脸照片');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: upload photo to backend face recognition endpoint
      // For now, mark as enrolled directly
      await context.read<AuthProvider>().markFaceEnrolled();
      if (mounted) context.go('/home');
    } catch (_) {
      setState(() => _error = '录入失败，请重试');
    } finally {
      setState(() => _loading = false);
    }
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
              const SizedBox(height: 40),
              StepIndicator(current: 2, total: 2),
              const SizedBox(height: 32),
              const Text('录入人脸', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('用于打卡时身份验证', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 40),

              // Face preview
              GestureDetector(
                onTap: _takeSelfie,
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: scheme.surfaceContainerHighest.withOpacity(0.5),
                    border: Border.all(
                      color: _photo != null ? scheme.primary : scheme.outline.withOpacity(0.3),
                      width: _photo != null ? 2 : 1,
                    ),
                  ),
                  child: _photo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.face_retouching_natural, size: 56, color: scheme.primary.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text('点击拍摄人脸', style: TextStyle(color: scheme.onSurface.withOpacity(0.5), fontSize: 14)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.file(File(_photo!.path), fit: BoxFit.cover, width: double.infinity),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _takeSelfie,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(_photo == null ? '拍摄照片' : '重新拍摄'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
              ],
              const Spacer(),
              PrimaryButton(label: '完成录入', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
