import 'notification_store.dart';
import 'token_storage.dart';
import 'ward_service.dart';

/// 로컬 세션 정리를 한 곳에 모은다.
/// 명시적 로그아웃과 세션 만료(401 재발급 실패) 양쪽에서 동일하게 호출해,
/// 다음 로그인에서 이전 사용자의 토큰·캐시·알림 배지가 재사용되지 않게 한다.
class Session {
  Session._();

  static Future<void> clear() async {
    await TokenStorage.clear();
    WardService.clearCache();
    NotificationStore.reset();
  }
}
