/// 알림 종류 상수 (서버 notificationType 값).
class NotiTypes {
  static const fall = 'FALL';
  static const warning = 'WARNING';
  static const deviceOffline = 'DEVICE_OFFLINE';
  static const emergency = 'EMERGENCY';
}

/// 알림 한 건. GET /api/wards/me/notifications 응답의 content 항목.
class AppNotification {
  final int id;
  final String notificationType; // FALL / WARNING / DEVICE_OFFLINE / EMERGENCY
  final String memberName; // 누구에 관한 알림인지
  final int? logId; // 연결된 이력 (없으면 null)
  final bool isRead;
  final String? createdAt; // ISO 문자열

  AppNotification({
    required this.id,
    required this.notificationType,
    required this.memberName,
    required this.logId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      notificationType: json['notificationType'] ?? '',
      memberName: json['memberName'] ?? '',
      logId: json['logId'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'],
    );
  }
}

/// 알림 목록 + 미읽음 개수 + 페이지 정보. 응답 전체.
class NotiPage {
  final int unreadCount;
  final List<AppNotification> content;
  final int page;
  final int totalPages;
  final bool last;

  NotiPage({
    required this.unreadCount,
    required this.content,
    required this.page,
    required this.totalPages,
    required this.last,
  });

  factory NotiPage.fromJson(Map<String, dynamic> json) {
    final list = (json['content'] as List?) ?? [];
    return NotiPage(
      unreadCount: json['unreadCount'] ?? 0,
      content: list.map((e) => AppNotification.fromJson(e)).toList(),
      page: json['page'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}
