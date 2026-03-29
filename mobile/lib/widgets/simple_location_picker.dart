import 'package:flutter/material.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

/// 简化的地址选择器（显示当前位置并支持手动输入）
class SimpleLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final double radius;
  final Function(double lat, double lng, String address) onLocationSelected;

  const SimpleLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.radius = 200,
    required this.onLocationSelected,
  });

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  StreamSubscription? _locationSub;
  double? _currentLat;
  double? _currentLng;
  String? _currentAddress;
  bool _locating = false;
  String? _error;
  Timer? _timeoutTimer;

  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentLat = widget.initialLat;
      _currentLng = widget.initialLng;
      _latCtrl.text = widget.initialLat!.toStringAsFixed(6);
      _lngCtrl.text = widget.initialLng!.toStringAsFixed(6);
      _currentAddress = '已选择位置';
      _addressCtrl.text = _currentAddress!;
    }
  }

  @override
  void dispose() {
    _stopLocation();
    _timeoutTimer?.cancel();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _stopLocation() {
    try {
      _locationPlugin.stopLocation();
      _locationSub?.cancel();
      _locationPlugin.destroy();
    } catch (_) {}
    _locationSub = null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      // 请求定位权限
      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _error = '需要定位权限';
          _locating = false;
        });
        return;
      }

      // 停止之前的定位
      _stopLocation();

      // 设置定位参数 - 使用持续定位模式
      _locationPlugin.setLocationOption(
        AMapLocationOption(
          locationMode: AMapLocationMode.Hight_Accuracy,
          needAddress: true,
          onceLocation: false, // 改为持续定位
          locationInterval: 1000,
        ),
      );

      // 设置超时
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (_locating && _currentLat == null) {
          _stopLocation();
          setState(() {
            _error = '定位超时，请重试';
            _locating = false;
          });
        }
      });

      // 开始定位
      _locationSub = _locationPlugin.onLocationChanged().listen((Map<String, Object> result) {
        if (!mounted) return;

        final errorCode = result['errorCode'];
        if (errorCode != null && errorCode != 0) {
          debugPrint('[SimpleLocationPicker] Error: code=$errorCode, info=${result['errorInfo']}');
          return;
        }

        final lat = result['latitude'] as double?;
        final lng = result['longitude'] as double?;
        final address = result['address'] as String?;

        if (lat != null && lng != null && lat != 0 && lng != 0) {
          _timeoutTimer?.cancel();
          _stopLocation(); // 获取到位置后停止定位

          setState(() {
            _currentLat = lat;
            _currentLng = lng;
            _currentAddress = address ?? '位置已获取';
            _locating = false;
            _latCtrl.text = lat.toStringAsFixed(6);
            _lngCtrl.text = lng.toStringAsFixed(6);
            _addressCtrl.text = _currentAddress!;
          });

          widget.onLocationSelected(lat, lng, _currentAddress!);
        }
      });

      _locationPlugin.startLocation();
    } catch (e) {
      _stopLocation();
      setState(() {
        _error = '定位失败: ${e.toString()}';
        _locating = false;
      });
    }
  }

  void _useManualInput() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    final address = _addressCtrl.text.trim();

    if (lat == null || lng == null) {
      setState(() => _error = '请输入有效的经纬度');
      return;
    }

    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() => _error = '经纬度范围不正确');
      return;
    }

    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _currentAddress = address.isNotEmpty ? address : '手动输入位置';
      _error = null;
    });

    widget.onLocationSelected(lat, lng, _currentAddress!);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 当前位置显示
          if (_currentLat != null && _currentLng != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      const Text(
                        '已选择位置',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress ?? '位置已获取',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '经度: ${_currentLng!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    '纬度: ${_currentLat!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '打卡半径: ${widget.radius.toInt()}米',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 错误提示
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 获取当前位置按钮
          ElevatedButton.icon(
            onPressed: _locating ? null : _getCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location, size: 18),
            label: Text(_locating ? '定位中...' : '获取当前位置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // 手动输入区域
          const Text(
            '或手动输入坐标',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '纬度',
                    hintText: '39.908823',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '经度',
                    hintText: '116.397470',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: '地址描述（可选）',
              hintText: '例如：公司大楼',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _useManualInput,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('使用此坐标'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 提示文字
          const Text(
            '提示：点击"获取当前位置"自动定位，或手动输入经纬度',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
