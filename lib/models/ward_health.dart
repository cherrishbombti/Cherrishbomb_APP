/// 피보호자 건강 정보. GET /api/wards/me/health 응답.
class WardHealth {
  final String disease; // 기저질환
  final String medication; // 복용약
  final String memo; // 기타 병력·메모
  final String? updatedByName; // 마지막 수정자
  final String? updatedAt; // 마지막 수정 시각(ISO)

  WardHealth({required this.disease, required this.medication, required this.memo, this.updatedByName, this.updatedAt});

  factory WardHealth.fromJson(Map<String, dynamic> json) {
    return WardHealth(
      disease: json['disease'] ?? '',
      medication: json['medication'] ?? '',
      memo: json['memo'] ?? '',
      updatedByName: json['updatedByName'],
      updatedAt: json['updatedAt'],
    );
  }
}
