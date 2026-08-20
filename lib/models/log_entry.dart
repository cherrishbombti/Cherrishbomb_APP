/// 서버 logType 값 상수 (하드코딩 방지).
class LogTypes {
  static const fallEvent = 'FALL_EVENT';
  static const sensorFailure = 'SENSOR_FAILURE';
  static const emergencyCall = 'EMERGENCY_CALL';
}

/// 서버 status(피보호자 상태) 값 상수.
class MemberStatuses {
  static const safe = 'SAFE';
  static const warning = 'WARNING';
  static const danger = 'DANGER';
}

/// 활동·낙상 이력 로그 한 건. GET /api/wards/me/logs 응답의 content 항목.
class LogEntry {
  final int id;
  final DateTime? detectedAt; // 발생 시각 (ISO 문자열 → DateTime)
  final String status; // 당시 상태: SAFE / WARNING / DANGER
  final String logType; // FALL_EVENT / SENSOR_FAILURE / EMERGENCY_CALL
  final String? sensorDetail; // 고장 센서명 (SENSOR_FAILURE 시에만, 그 외 null)

  LogEntry({
    required this.id,
    required this.detectedAt,
    required this.status,
    required this.logType,
    required this.sensorDetail,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['detectedAt'];
    return LogEntry(
      id: json['id'] ?? 0,
      // 파싱 실패해도 앱이 죽지 않게 tryParse 사용
      detectedAt: raw != null ? DateTime.tryParse(raw.toString()) : null,
      status: json['status'] ?? '',
      logType: json['logType'] ?? '',
      sensorDetail: json['sensorDetail'],
    );
  }
}

/// 로그 목록 + 페이지네이션 정보. GET /api/wards/me/logs 응답 전체.
class LogPage {
  final List<LogEntry> content; // 이번 페이지의 로그들
  final int page; // 현재 페이지 번호 (0부터)
  final int totalPages; // 전체 페이지 수
  final bool last; // 마지막 페이지 여부

  LogPage({
    required this.content,
    required this.page,
    required this.totalPages,
    required this.last,
  });

  factory LogPage.fromJson(Map<String, dynamic> json) {
    final list = (json['content'] as List?) ?? [];
    return LogPage(
      content: list.map((e) => LogEntry.fromJson(e)).toList(),
      page: json['page'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}
