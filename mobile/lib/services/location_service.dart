import 'dart:async';
import 'package:amap_flutter_location/amap_flutter_location.dart';
import 'package:amap_flutter_location/amap_location_option.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  AMapFlutterLocation? _location;
  StreamSubscription? _sub;
  double? lat;
  double? lng;
  String? address;
  void Function(double lat, double lng, String? address)? onLocationChanged;

  Future<bool> requestPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }

  void startListening() {
    _location = AMapFlutterLocation();
    _location!.setLocationOption(AMapLocationOption(
      onceLocation: false,
      locationInterval: 5000,
      needAddress: true,
    ));
    _sub = _location!.onLocationChanged().listen((map) {
      final la = map['latitude'];
      final lo = map['longitude'];
      if (la is num && lo is num && la != 0 && lo != 0) {
        lat = la.toDouble();
        lng = lo.toDouble();
        address = map['address'] as String?;
        onLocationChanged?.call(lat!, lng!, address);
      }
    });
    _location!.startLocation();
  }

  void stopListening() {
    _location?.stopLocation();
    _sub?.cancel();
    _location?.destroy();
    _location = null;
    _sub = null;
  }
}
