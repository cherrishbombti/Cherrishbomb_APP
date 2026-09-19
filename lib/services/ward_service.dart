import 'package:dio/dio.dart';
import 'api_client.dart';
import 'mock_data.dart';
import '../models/ward_summary.dart';
import '../models/ward_sensor.dart';
import '../models/ward_contact.dart';
import '../models/log_entry.dart';
import '../models/ward_health.dart';
import '../models/app_notification.dart';
import '../models/organization_link.dart';
import '../utils/date_format.dart';

/// 값 하나를 짧게 보관하는 아주 단순한 캐시.
/// 화면을 다시 열 때마다 같은 서버 호출을 반복하지 않도록 쓴다.
class _Cache<T> {
  T? _value;
  DateTime? _at;

  bool fresh(Duration ttl) => _value != null && _at != null && DateTime.now().difference(_at!) < ttl;
  T get value => _value as T;
  void set(T v) {
    _value = v;
    _at = DateTime.now();
  }

  void clear() {
    _value = null;
    _at = null;
  }
}

/// 피보호자(ward) 관련 API 담당. (#2의 ApiClient 사용 → 토큰 자동 첨부)
class WardService {
  // TODO(미리보기): 디자인 확인용 목데이터. 커밋 전 반드시 false 로.
  static const bool mock = false;

  // ---- 간단 캐시 ----
  // 화면 재방문 시 매번 서버를 다시 부르지 않도록 짧게 보관한다.
  // 값을 바꾸는 요청(추가·수정·삭제) 뒤에는 해당 캐시를 비워 최신값을 다시 받는다.
  // 강제로 새로 받고 싶으면 각 조회에 force: true (당겨서 새로고침 등).
  static const Duration _ttl = Duration(seconds: 30);
  static final _Cache<WardSummary> _summaryC = _Cache();
  static final _Cache<WardSensor> _sensorC = _Cache();
  static final _Cache<List<WardContact>> _contactsC = _Cache();
  static final _Cache<WardHealth> _healthC = _Cache();
  static final _Cache<OrganizationLink> _orgC = _Cache();

  /// 로그아웃 등 사용자가 바뀔 때 모든 캐시를 비운다.
  static void clearCache() {
    _summaryC.clear();
    _sensorC.clear();
    _contactsC.clear();
    _healthC.clear();
    _orgC.clear();
  }

  /// 피보호자 상태 요약 조회. GET /api/wards/me/summary
  static Future<WardSummary> getSummary({bool force = false}) async {
    if (mock) return MockData.summary();
    if (!force && _summaryC.fresh(_ttl)) return _summaryC.value;
    final res = await ApiClient.dio.get('/api/wards/me/summary');
    final v = WardSummary.fromJson(res.data);
    _summaryC.set(v);
    return v;
  }

  /// 낙상감지 센서 상태 조회. GET /api/wards/me/sensors
  /// 홈·기기 화면이 공유하므로 캐시로 중복 호출을 막는다.
  static Future<WardSensor> getSensors({bool force = false}) async {
    if (mock) return MockData.sensor();
    if (!force && _sensorC.fresh(_ttl)) return _sensorC.value;
    final res = await ApiClient.dio.get('/api/wards/me/sensors');
    final v = WardSensor.fromJson(res.data);
    _sensorC.set(v);
    return v;
  }

  /// 피보호자 등록. POST /api/wards/me
  static Future<void> registerWard({
    required String name,
    String? birthDate, // 미수집 시 생략 (빈 문자열 대신 필드 자체를 안 보냄)
    required String address,
    required String phone,
    required String relationship,
    required String deviceMac,
    String? guardianName,
    String? guardianPhone,
    String? disease,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
      'relationship': relationship,
      'deviceMac': deviceMac,
    };
    // 빈 값은 필드 자체를 안 보낸다 (서버에서 null 처리)
    if (birthDate != null && birthDate.isNotEmpty) data['birthDate'] = birthDate;
    if (guardianName != null && guardianName.isNotEmpty) {
      data['guardianName'] = guardianName;
    }
    if (guardianPhone != null && guardianPhone.isNotEmpty) {
      data['guardianPhone'] = guardianPhone;
    }
    if (disease != null && disease.isNotEmpty) data['disease'] = disease;
    await ApiClient.dio.post('/api/wards/me', data: data);
    clearCache(); // 새 피보호자 등록 → 이전 캐시는 전부 무효
  }

  /// 비상 연락처 목록 조회. GET /api/wards/me/contacts
  static Future<List<WardContact>> getContacts({bool force = false}) async {
    if (mock) return MockData.contacts();
    if (!force && _contactsC.fresh(_ttl)) return _contactsC.value;
    final res = await ApiClient.dio.get('/api/wards/me/contacts');
    // 응답은 리스트(JSON 배열) → 각 항목을 WardContact로 변환
    final list = res.data as List;
    final v = list.map((e) => WardContact.fromJson(e)).toList();
    _contactsC.set(v);
    return v;
  }

  /// 비상 연락처 추가. POST /api/wards/me/contacts
  static Future<void> addContact({required String name, required String phone, required String relationship}) async {
    await ApiClient.dio.post(
      '/api/wards/me/contacts',
      data: {'name': name, 'phone': phone, 'relationship': relationship},
    );
    _contactsC.clear(); // 목록이 바뀌었으니 다음 조회는 새로
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
    _contactsC.clear();
  }

  /// 비상 연락처 삭제. DELETE /api/wards/me/contacts/{id}
  static Future<void> deleteContact(int contactId) async {
    await ApiClient.dio.delete('/api/wards/me/contacts/$contactId');
    _contactsC.clear();
  }

  /// 활동·낙상 이력 조회. GET /api/wards/me/logs
  /// page/size는 페이지네이션, from/to는 날짜 필터(선택).
  static Future<LogPage> getLogs({int page = 0, int size = 20, DateTime? from, DateTime? to}) async {
    if (mock) return MockData.logs();
    // 값이 있는 쿼리만 골라 담는다. (null이면 서버에 안 보냄)
    final query = <String, dynamic>{'page': page, 'size': size};
    if (from != null) query['from'] = ymd(from);
    if (to != null) query['to'] = ymd(to);

    final res = await ApiClient.dio.get('/api/wards/me/logs', queryParameters: query);
    return LogPage.fromJson(res.data);
  }

  // ---- 건강 정보 (#20) ----

  /// 건강 정보 조회. GET /api/wards/me/health
  static Future<WardHealth> getHealth({bool force = false}) async {
    if (mock) return MockData.health();
    if (!force && _healthC.fresh(_ttl)) return _healthC.value;
    final res = await ApiClient.dio.get('/api/wards/me/health');
    final v = WardHealth.fromJson(res.data);
    _healthC.set(v);
    return v;
  }

  /// 건강 정보 전체 저장(upsert). PUT /api/wards/me/health
  /// 세 필드 모두 필수 — 비우려면 빈 문자열을 보낸다.
  static Future<void> putHealth({required String disease, required String medication, required String memo}) async {
    await ApiClient.dio.put('/api/wards/me/health', data: {'disease': disease, 'medication': medication, 'memo': memo});
    _healthC.clear(); // 저장했으니 다음 조회는 새 값으로
  }

  // ---- 알림 (#21) ----

  /// 알림 목록 조회. GET /api/wards/me/notifications
  static Future<NotiPage> getNotifications({int page = 0, int size = 20}) async {
    if (mock) return MockData.notifications();
    final res = await ApiClient.dio.get('/api/wards/me/notifications', queryParameters: {'page': page, 'size': size});
    return NotiPage.fromJson(res.data);
  }

  /// 단건 읽음 처리. PATCH /api/wards/me/notifications/{id}/read
  static Future<void> readNotification(int id) async {
    if (mock) {
      MockData.markRead(id);
      return;
    }
    await ApiClient.dio.patch('/api/wards/me/notifications/$id/read');
  }

  /// 전체 읽음 처리. PATCH /api/wards/me/notifications/read-all
  static Future<void> readAllNotifications() async {
    if (mock) {
      MockData.markAllRead();
      return;
    }
    await ApiClient.dio.patch('/api/wards/me/notifications/read-all');
  }

  // ---- 기관 연동 ----
  // #46 머지·배포 완료로 실제 API 사용. 목 코드는 서버 없이 볼 때만 true로.
  static const bool _orgMock = false;

  /// 연동 상태 조회. GET /api/wards/me/organization
  static Future<OrganizationLink> getOrganization({bool force = false}) async {
    if (_orgMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return OrganizationLink(linked: false); // 초기: 미연동
    }
    if (!force && _orgC.fresh(_ttl)) return _orgC.value;
    final res = await ApiClient.dio.get('/api/wards/me/organization');
    final v = OrganizationLink.fromJson(res.data);
    _orgC.set(v);
    return v;
  }

  /// 기관 연동/변경. PATCH /api/wards/me/organization {orgCode: 숫자}
  static Future<OrganizationLink> linkOrganization(int orgCode) async {
    if (_orgMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (orgCode == 10001001) {
        return OrganizationLink(linked: true, organizationId: 3, organizationName: '○○종합사회복지관', orgCode: 10001001);
      }
      throw _mockError(404, 'O003', '존재하지 않는 기관번호입니다.');
    }
    final res = await ApiClient.dio.patch('/api/wards/me/organization', data: {'orgCode': orgCode});
    final v = OrganizationLink.fromJson(res.data);
    _orgC.set(v); // 방금 받은 최신 상태로 캐시 갱신
    return v;
  }

  /// 기관 연동 해제. DELETE /api/wards/me/organization (멱등)
  static Future<void> unlinkOrganization() async {
    if (_orgMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }
    await ApiClient.dio.delete('/api/wards/me/organization');
    _orgC.clear();
  }

  // 목 에러: 실제 서버 에러(DioException + {code,message})와 같은 형태로 던짐.
  static DioException _mockError(int status, String code, String message) {
    final opts = RequestOptions(path: '/api/wards/me/organization');
    return DioException(
      requestOptions: opts,
      response: Response(
        requestOptions: opts,
        statusCode: status,
        data: {'status': status, 'code': code, 'message': message},
      ),
    );
  }
}
