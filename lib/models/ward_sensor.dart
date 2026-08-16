/// 낙상감지 센서 상태. GET /api/wards/me/sensors 응답을 담는다.
class WardSensor {
  final String status; // 전체 상태: SAFE / WARNING / DANGER
  // 센서 값은 null 보존 — null: 아직 신호 없음(미확인), true: 정상, false: 이상
  final bool? vibrator; // 진동 센서
  final bool? radar; // 레이더 센서
  final bool? thermal; // 열화상 센서
  final bool deviceOnline; // 기기 연결 여부
  final String? deviceLastSeen; // 마지막 신호 시각(없으면 null)

  WardSensor({
    required this.status,
    required this.vibrator,
    required this.radar,
    required this.thermal,
    required this.deviceOnline,
    required this.deviceLastSeen,
  });

  factory WardSensor.fromJson(Map<String, dynamic> json) {
    return WardSensor(
      status: json['status'] ?? 'SAFE',
      // ?? false 제거 — null(미확인)과 false(이상)를 구분하기 위해 그대로 보존
      vibrator: json['vibrator'],
      radar: json['radar'],
      thermal: json['thermal'],
      deviceOnline: json['deviceOnline'] ?? false,
      deviceLastSeen: json['deviceLastSeen'],
    );
  }
}
