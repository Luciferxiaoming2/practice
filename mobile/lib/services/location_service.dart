import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';

class LocationService {
  double? lat;
  double? lng;
  String? address;
  void Function(double lat, double lng, String? address)? onLocationChanged;

  AMapFlutterLocation? _amapClient;
  StreamSubscription? _amapSub;
  int _retryCount = 0;
  Timer? _retryTimer;

  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] Location service disabled');
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    debugPrint('[LocationService] Permission: $perm');
    return perm == LocationPermission.whileInUse || perm == LocationPermission.always;
  }

  void startListening() {
    debugPrint('[LocationService] startListening called');
    _startAmap();
  }

  void _startAmap() {
    try {
      // 销毁旧的
      _stopAmap();

      _amapClient = AMapFlutterLocation();
      _amapClient!.setLocationOption(AMapLocationOption(
        onceLocation: false,
        locationInterval: 1000,
        needAddress: true,
        locationMode: AMapLocationMode.Hight_Accuracy,
      ));

      _amapSub = _amapClient!.onLocationChanged().listen((map) {
        final la = map['latitude'];
        final lo = map['longitude'];
        final errorCode = map['errorCode'];

        debugPrint('[LocationService] AMap data: lat=$la, lng=$lo, error=$errorCode');

        if (errorCode != null && errorCode != 0) {
          debugPrint('[LocationService] AMap error: code=$errorCode, info=${map['errorInfo']}');
          _scheduleRetry();
          return;
        }

        if (la is num && lo is num && la != 0 && lo != 0) {
          _retryCount = 0;
          _retryTimer?.cancel();
          lat = la.toDouble();
          lng = lo.toDouble();
          address = map['address'] as String?;
          if (address == null || address!.isEmpty) {
            address = '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';
          }
          onLocationChanged?.call(lat!, lng!, address);
        }
      });

      _amapClient!.startLocation();
      debugPrint('[LocationService] AMap startLocation OK');

      // 3秒后检查是否有数据
      _retryTimer = Timer(const Duration(seconds: 3), () {
        if (lat == null) {
          debugPrint('[LocationService] No AMap data after 3s');
          _scheduleRetry();
        }
      });
    } catch (e) {
      debugPrint('[LocationService] AMap exception: $e');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= 3) {
      debugPrint('[LocationService] Max retries reached');
      return;
    }
    _retryCount++;
    _retryTimer?.cancel();
    final delaySec = _retryCount == 1 ? 1 : 2 * _retryCount;
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      debugPrint('[LocationService] Retry #$_retryCount');
      _startAmap();
    });
  }

  void _stopAmap() {
    try {
      _amapClient?.stopLocation();
      _amapSub?.cancel();
      _amapClient?.destroy();
    } catch (_) {}
    _amapClient = null;
    _amapSub = null;
  }

  void stopListening() {
    _stopAmap();
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
