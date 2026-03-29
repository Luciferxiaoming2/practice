class CheckIn {
  final int id;
  final int userId;
  final DateTime timestamp;
  final double? lat;
  final double? lng;
  final String? address;
  final String status;
  final String type;

  CheckIn({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.lat,
    this.lng,
    this.address,
    required this.status,
    this.type = 'sign_in',
  });

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'],
        userId: j['user_id'],
        timestamp: DateTime.parse(j['timestamp']),
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        address: j['address'] as String?,
        status: j['status'] ?? 'ok',
        type: j['type'] ?? 'sign_in',
      );

  bool get isSuccess => status == 'ok';

  String get typeLabel => type == 'sign_out' ? '签退' : '签到';

  String get statusLabel => switch (status) {
        'ok' => '正常',
        'location_fail' => '位置异常',
        'time_early' => '早到',
        'time_late' => '迟到',
        'time_fail' => '迟到',
        'face_fail' => '人脸异常',
        _ => status,
      };

  bool get isTimeIssue => status == 'time_early' || status == 'time_late' || status == 'time_fail';
}
