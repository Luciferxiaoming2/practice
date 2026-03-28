class CheckIn {
  final int id;
  final int userId;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final String status;

  CheckIn({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.lat,
    this.lng,
    required this.status,
  });

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'],
        userId: j['user_id'],
        timestamp: DateTime.parse(j['timestamp']),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        status: j['status'] ?? 'ok',
      );

  bool get isSuccess => status == 'ok';

  String get statusLabel => switch (status) {
        'ok' => '正常',
        'location_fail' => '位置异常',
        'time_fail' => '时间异常',
        'face_fail' => '人脸异常',
        _ => status,
      };
}
