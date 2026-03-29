import 'dart:async';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  double? lat;
  double? lng;
  String? address;
  void Function(double lat, double lng, String? address)? onLocationChanged;

  AMapFlutterLocation? _amapClient;
  StreamSubscription? _amapSub;
  int _retryCount = 0;
  Timer? _retryTimer;
  bool _fallbackRunning = false;

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
      _stopAmap();

      _amapClient = AMapFlutterLocation();
      _amapClient!.setLocationOption(AMapLocationOption(
        onceLocation: false,
        locationInterval: 1000,
        needAddress: true,
        locationMode: AMapLocationMode.Hight_Accuracy,
      ));

      _amapSub = _amapClient!.onLocationChanged().listen((map) {
        final nextLat = _parseDouble(map['latitude']);
        final nextLng = _parseDouble(map['longitude']);
        final errorCode = _parseErrorCode(map['errorCode']);

        debugPrint(
          '[LocationService] AMap data: lat=$nextLat, lng=$nextLng, error=$errorCode',
        );

        if (errorCode != null && errorCode != 0) {
          debugPrint(
            '[LocationService] AMap error: code=$errorCode, info=${map['errorInfo']}',
          );
          _fallbackToGeolocator();
          _scheduleRetry();
          return;
        }

        if (nextLat != null && nextLng != null && nextLat != 0 && nextLng != 0) {
          _emitLocation(nextLat, nextLng, _resolveAddress(map));
        }
      });

      _amapClient!.startLocation();
      debugPrint('[LocationService] AMap startLocation OK');

      _retryTimer = Timer(const Duration(seconds: 3), () {
        if (lat == null) {
          debugPrint('[LocationService] No AMap data after 3s');
          _fallbackToGeolocator();
          _scheduleRetry();
        }
      });
    } catch (e) {
      debugPrint('[LocationService] AMap exception: $e');
      _fallbackToGeolocator();
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

  double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseErrorCode(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _resolveAddress(Map<dynamic, dynamic> map) {
    final directAddress = map['address'];
    if (directAddress is String && directAddress.isNotEmpty) {
      return directAddress;
    }

    final parts = <String>[
      for (final key in const ['province', 'city', 'district', 'street', 'streetNum', 'poiName'])
        if (map[key] is String && (map[key] as String).isNotEmpty) map[key] as String,
    ];

    if (parts.isNotEmpty) {
      return parts.join();
    }

    return null;
  }

  void _emitLocation(double nextLat, double nextLng, String? nextAddress) {
    _retryCount = 0;
    _retryTimer?.cancel();
    lat = nextLat;
    lng = nextLng;
    address = (nextAddress != null && nextAddress.isNotEmpty)
        ? nextAddress
        : '${nextLat.toStringAsFixed(5)}, ${nextLng.toStringAsFixed(5)}';
    onLocationChanged?.call(lat!, lng!, address);
  }

  Future<void> _fallbackToGeolocator() async {
    if (_fallbackRunning) return;
    _fallbackRunning = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (position.latitude != 0 && position.longitude != 0) {
        debugPrint('[LocationService] Geolocator fallback success');
        _emitLocation(position.latitude, position.longitude, null);
      }
    } catch (e) {
      debugPrint('[LocationService] Geolocator fallback failed: $e');
    } finally {
      _fallbackRunning = false;
    }
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
    _fallbackRunning = false;
  }
}
