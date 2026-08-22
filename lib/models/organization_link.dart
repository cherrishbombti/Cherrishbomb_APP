/// 기관 연동 상태. GET/PATCH /api/wards/me/organization 응답.
/// 연동 전에도 필드는 다 오고 값만 null → linked를 먼저 확인할 것.
class OrganizationLink {
  final bool linked;
  final int? organizationId;
  final String? organizationName;
  final int? orgCode;

  OrganizationLink({required this.linked, this.organizationId, this.organizationName, this.orgCode});

  factory OrganizationLink.fromJson(Map<String, dynamic> json) {
    return OrganizationLink(
      linked: json['linked'] ?? false,
      organizationId: json['organizationId'],
      organizationName: json['organizationName'],
      orgCode: json['orgCode'],
    );
  }
}
