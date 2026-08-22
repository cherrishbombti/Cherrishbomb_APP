import 'api_client.dart';
import '../models/ward_summary.dart';
import '../models/ward_sensor.dart';
import '../models/ward_contact.dart';
import '../models/log_entry.dart';
import '../models/ward_health.dart';
import '../models/app_notification.dart';
import '../utils/date_format.dart';

/// 피보호자(ward) 관련 API 담당. (#2의 ApiClient 사용 → 토큰 자동 첨부)
class WardService {
  /// 피보호자 상태 요약 조회. GET /api/wards/me/summary
  static Future<WardSummary> getSummary() async {
    final res = await ApiClient.dio.get('/api/wards/me/summary');
    return WardSummary.fromJson(res.data);
  }

  /// 낙상감지 센서 상태 조회. GET /api/wards/me/sensors
  static Future<WardSensor> getSensors() async {
    final res = await ApiClient.dio.get('/api/wards/me/sensors');
    return WardSensor.fromJson(res.data);
  }

  /// 피보호자 등록. POST /api/wards/me
  static Future<void> registerWard({
    required String name,
    String? birthDate, // 미수집 시 생략 (빈 문자열 대신 필드 자체를 안 보냄)
    required String address,
    required String phone,
    required String relationship,
    required String deviceMac,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'relationship': relationship,
      'deviceMac': deviceMac,
    };
    if (birthDate != null && birthDate.isNotEmpty) {
      data['birthDate'] = birthDate;
    }
    await ApiClient.dio.post('/api/wards/me', data: data);
  }

  /// 비상 연락처 목록 조회. GET /api/wards/me/contacts
  static Future<List<WardContact>> getContacts() async {
    final res = await ApiClient.dio.get('/api/wards/me/contacts');
    // 응답은 리스트(JSON 배열) → 각 항목을 WardContact로 변환
    final list = res.data as List;
    return list.map((e) => WardContact.fromJson(e)).toList();
  }

  /// 비상 연락처 추가. POST /api/wards/me/contacts
  static Future<void> addContact({required String name, required String phone, required String relationship}) async {
    await ApiClient.dio.post(
      '/api/wards/me/contacts',
      data: {'name': name, 'phone': phone, 'relationship': relationship},
    );
  }

  /// 비상 연락처 수정. PUT /api/wards/me/contacts/{id}
  static Future<void> updateContact({
    required int contactId,
    required String name,
    required String phone,
    required String relationship,
  }) async {
    await ApiClient.dio.put(
      '/api/wards/me/contacts/$contactId',
      data: {'name': name, 'phone': phone, 'relationship': relationship},
    );
  }

  /// 비상 연락처 삭제. DELETE /api/wards/me/contacts/{id}
  static Future<void> deleteContact(int contactId) async {
    await ApiClient.dio.delete('/api/wards/me/contacts/$contactId');
  }

  /// 활동·낙상 이력 조회. GET /api/wards/me/logs
  /// page/size는 페이지네이션, from/to는 날짜 필터(선택).
  static Future<LogPage> getLogs({int page = 0, int size = 20, DateTime? from, DateTime? to}) async {
    // 값이 있는 쿼리만 골라 담는다. (null이면 서버에 안 보냄)
    final query = <String, dynamic>{'page': page, 'size': size};
    if (from != null) query['from'] = ymd(from);
    if (to != null) query['to'] = ymd(to);

    final res = await ApiClient.dio.get('/api/wards/me/logs', queryParameters: query);
    return LogPage.fromJson(res.data);
  }

  // ---- 건강 정보 (#20) ----

  /// 건강 정보 조회. GET /api/wards/me/health
  static Future<WardHealth> getHealth() async {
    final res = await ApiClient.dio.get('/api/wards/me/health');
    return WardHealth.fromJson(res.data);
  }

  /// 건강 정보 전체 저장(upsert). PUT /api/wards/me/health
  /// 세 필드 모두 필수 — 비우려면 빈 문자열을 보낸다.
  static Future<void> putHealth({required String disease, required String medication, required String memo}) async {
    await ApiClient.dio.put('/api/wards/me/health', data: {'disease': disease, 'medication': medication, 'memo': memo});
  }

  // ---- 알림 (#21) ----

  /// 알림 목록 조회. GET /api/wards/me/notifications
  static Future<NotiPage> getNotifications({int page = 0, int size = 20}) async {
    final res = await ApiClient.dio.get('/api/wards/me/notifications', queryParameters: {'page': page, 'size': size});
    return NotiPage.fromJson(res.data);
  }

  /// 단건 읽음 처리. PATCH /api/wards/me/notifications/{id}/read
  static Future<void> readNotification(int id) async {
    await ApiClient.dio.patch('/api/wards/me/notifications/$id/read');
  }

  /// 전체 읽음 처리. PATCH /api/wards/me/notifications/read-all
  static Future<void> readAllNotifications() async {
    await ApiClient.dio.patch('/api/wards/me/notifications/read-all');
  }
}
