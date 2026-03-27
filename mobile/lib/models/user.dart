class User {
  final int id;
  final String username;
  final String fullName;
  final bool isActive;
  final bool isAdmin;
  final bool faceEnrolled;
  final bool requireLocation;
  final double? locationLat;
  final double? locationLng;
  final double? locationRadius;
  final bool requireTime;
  final String? checkinTimeStart;
  final String? checkinTimeEnd;
  final bool requireFace;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.isActive,
    required this.isAdmin,
    required this.faceEnrolled,
    required this.requireLocation,
    this.locationLat,
    this.locationLng,
    this.locationRadius,
    required this.requireTime,
    this.checkinTimeStart,
    this.checkinTimeEnd,
    required this.requireFace,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'],
        username: j['username'],
        fullName: j['full_name'],
        isActive: j['is_active'],
        isAdmin: j['is_admin'],
        faceEnrolled: j['face_enrolled'],
        requireLocation: j['require_location'],
        locationLat: (j['location_lat'] as num?)?.toDouble(),
        locationLng: (j['location_lng'] as num?)?.toDouble(),
        locationRadius: (j['location_radius'] as num?)?.toDouble(),
        requireTime: j['require_time'],
        checkinTimeStart: j['checkin_time_start'],
        checkinTimeEnd: j['checkin_time_end'],
        requireFace: j['require_face'],
      );
}
