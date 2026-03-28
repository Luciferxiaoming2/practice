import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationProvider { geolocator, amap }

class LocationService {
  LocationProvider provider;
  LocationService({this.provider = LocationProvider.geolocator});

  // 通用状态
  double? lat;
  double? lng;
  String? address;
  void Function(double lat, double lng, String? address)? onLocationChanged;

  // geolocator
  StreamSubscription<Position>? _geoSub;

  // 高德
  AMapFlutterLocation? _amapLocation;
  StreamSubscription? _amapSub;

  Future<bool> requestPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  void startListening() {
    if (provider == LocationProvider.amap) {
      _startAmap();
    } else {
      _startGeolocator();
    }
  }

  void stopListening() {
    _stopGeolocator();
    _stopAmap();
  }

  // ── Geolocator ──────────────────────────────────

  void _startGeolocator() {
    _geoSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      lat = pos.latitude;
      lng = pos.longitude;
      address = null; // geolocator 不提供地址，显示坐标
      onLocationChanged?.call(lat!, lng!, address);
    });

    // 先获取一次当前位置
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((pos) {
      lat = pos.latitude;
      lng = pos.longitude;
      onLocationChanged?.call(lat!, lng!, null);
    }).catchError((_) {});
  }

  void _stopGeolocator() {
    _geoSub?.cancel();
    _geoSub = null;
  }

  // ── 高德定位 ──────────────────────────────────

  void _startAmap() {
    _amapLocation = AMapFlutterLocation();
    _amapLocation!.setLocationOption(AMapLocationOption(
      onceLocation: false,
      locationInterval: 5000,
      needAddress: true,
    ));
    _amapSub = _amapLocation!.onLocationChanged().listen((map) {
      final la = map['latitude'];
      final lo = map['longitude'];
      if (la is num && lo is num && la != 0 && lo != 0) {
        lat = la.toDouble();
        lng = lo.toDouble();
        address = map['address'] as String?;
        onLocationChanged?.call(lat!, lng!, address);
      }
    });
    _amapLocation!.startLocation();
  }

  void _stopAmap() {
    _amapLocation?.stopLocation();
    _amapSub?.cancel();
    _amapLocation?.destroy();
    _amapLocation = null;
    _amapSub = null;
  }
}
