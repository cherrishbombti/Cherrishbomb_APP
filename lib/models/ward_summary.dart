/// 피보호자 상태 요약. GET /api/wards/me/summary 응답을 담는다.
class WardSummary {
  final String wardName; // 피보호자 이름
  final String relationship; // 관계
  final String phone; // 전화번호
  final String status; // 상태: SAFE / WARNING / DANGER
  final int totalActivityMinutes; // 오늘 총 활동 시간(분) — 현재 백엔드 0
  final int lastActivityMinutes; // 마지막 활동 경과(분) — 현재 백엔드 0
  final bool deviceOnline; // 기기 연결 여부
  final String? deviceLastSeen; // 마지막 신호 시각(없으면 null)

  WardSummary({
    required this.wardName,
    required this.relationship,
    required this.phone,
    required this.status,
    required this.totalActivityMinutes,
    required this.lastActivityMinutes,
    required this.deviceOnline,
    required this.deviceLastSeen,
  });

  // 서버가 준 JSON(Map)을 WardSummary 객체로 변환
  factory WardSummary.fromJson(Map<String, dynamic> json) {
    return WardSummary(
      wardName: json['wardName'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'] ?? 'SAFE',
      totalActivityMinutes: json['totalActivityMinutes'] ?? 0,
      lastActivityMinutes: json['lastActivityMinutes'] ?? 0,
      deviceOnline: json['deviceOnline'] ?? false,
      deviceLastSeen: json['deviceLastSeen'],
    );
  }
}
