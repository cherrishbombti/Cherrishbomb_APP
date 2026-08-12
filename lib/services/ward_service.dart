import 'api_client.dart';

/// 피보호자(ward) 관련 API 담당. (#2의 ApiClient 사용 → 토큰 자동 첨부)
class WardService {
  /// 피보호자 등록. POST /api/wards/me
  static Future<void> registerWard({
    required String name,
    required String birthDate,
    required String address,
    required String phone,
    required String relationship,
    required String deviceMac,
  }) async {
    await ApiClient.dio.post(
      '/api/wards/me',
      data: {
        'name': name,
        'birthDate': birthDate,
        'address': address,
        'phone': phone,
        'relationship': relationship,
        'deviceMac': deviceMac,
      },
    );
  }
}
