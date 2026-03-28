class User {
  final int id;
  final String username;
  final String fullName;
  final bool isActive;
  final bool isAdmin;
  final bool faceEnrolled;
  final int? roleId;
  final String? roleName;
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
    this.roleId,
    this.roleName,
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
        fullName: j['full_name'] ?? '',
        isActive: j['is_active'] ?? false,
        isAdmin: j['is_admin'] ?? false,
        faceEnrolled: j['face_enrolled'] ?? false,
        roleId: j['role_id'],
        roleName: (j['role'] is Map) ? j['role']['name'] : j['role_name'],
        requireLocation: j['require_location'] ?? false,
        locationLat: (j['location_lat'] as num?)?.toDouble(),
        locationLng: (j['location_lng'] as num?)?.toDouble(),
        locationRadius: (j['location_radius'] as num?)?.toDouble(),
        requireTime: j['require_time'] ?? false,
        checkinTimeStart: j['checkin_time_start'],
        checkinTimeEnd: j['checkin_time_end'],
        requireFace: j['require_face'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'is_active': isActive,
        'is_admin': isAdmin,
        'face_enrolled': faceEnrolled,
        'role_id': roleId,
        'role_name': roleName,
        'require_location': requireLocation,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'location_radius': locationRadius,
        'require_time': requireTime,
        'checkin_time_start': checkinTimeStart,
        'checkin_time_end': checkinTimeEnd,
        'require_face': requireFace,
      };

  User copyWith({
    bool? isActive,
    bool? faceEnrolled,
    String? fullName,
  }) =>
      User(
        id: id,
        username: username,
        fullName: fullName ?? this.fullName,
        isActive: isActive ?? this.isActive,
        isAdmin: isAdmin,
        faceEnrolled: faceEnrolled ?? this.faceEnrolled,
        roleId: roleId,
        roleName: roleName,
        requireLocation: requireLocation,
        locationLat: locationLat,
        locationLng: locationLng,
        locationRadius: locationRadius,
        requireTime: requireTime,
        checkinTimeStart: checkinTimeStart,
        checkinTimeEnd: checkinTimeEnd,
        requireFace: requireFace,
      );
}
