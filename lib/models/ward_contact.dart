/// 비상 연락처 하나. GET /api/wards/me/contacts 응답의 각 항목.
class WardContact {
  final int contactId;
  final String name; // 연락처 이름
  final String phone; // 전화번호
  final String relationship; // 관계
  final int priority; // 우선순위 (현재 백엔드는 등록순, 추후 정렬 지원 예정)

  WardContact({
    required this.contactId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
  });

  factory WardContact.fromJson(Map<String, dynamic> json) {
    return WardContact(
      contactId: json['contactId'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relationship: json['relationship'] ?? '',
      priority: json['priority'] ?? 0,
    );
  }
}
