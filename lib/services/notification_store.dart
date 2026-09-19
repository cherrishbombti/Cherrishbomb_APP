import 'package:flutter/foundation.dart';

import 'ward_service.dart';

/// 안읽음 알림 개수를 앱 전역에서 공유하는 저장소.
/// - 모든 탭의 헤더가 이 값을 구독하므로, 어느 탭에서 읽든 배지가 동시에 갱신된다.
/// - 조회는 최초 1회만(ensureLoaded) 하고, 이후 탭 이동에서는 서버를 다시 안 부른다.
/// - 사용자 전환(reset) 시 세대(generation)를 올려, 이전 세션에서 시작된 응답이
///   뒤늦게 도착해도 새 세션 상태를 덮어쓰지 못하게 격리한다.
class NotificationStore {
  NotificationStore._();

  /// 현재 안읽음 개수. 헤더는 ValueListenableBuilder로 이 값을 구독한다.
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);

  // 최초 1회 로드 여부. 탭마다 헤더가 새로 생겨도 중복 조회를 막는다.
  static bool _loaded = false;

  // 진행 중인 최초 로드 Future. 첫 응답 전에 다른 헤더가 생겨도 이걸 await 하게 해
  // 문서화된 "최초 1회 조회"를 실제로 보장한다.
  static Future<void>? _inflight;

  // 세션 세대. reset() 때 증가한다. 이 값이 바뀌면 이전 세션의 응답은 폐기한다.
  static int _gen = 0;

  /// 현재 세대 번호. 외부(알림함)에서 조회 시작 시점을 캡처해 set에 넘기는 용도.
  static int get generation => _gen;

  /// 외부에서 최신 개수를 직접 반영한다. (알림함 조회 등)
  /// gen을 넘기면, 그 조회가 시작된 이후 reset이 일어났을 경우 무시한다.
  static void set(int count, {int? gen}) {
    if (gen != null && gen != _gen) return; // 지난 세션의 응답 → 버림
    unread.value = count < 0 ? 0 : count;
    _loaded = true;
  }

  /// 아직 한 번도 안 불렀으면 그때만 서버에서 개수를 받아온다.
  /// 진행 중인 로드가 있으면 새 요청을 만들지 않고 그 Future를 함께 기다린다.
  static Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _inflight ??= _fetchOnce();
  }

  static Future<void> _fetchOnce() async {
    try {
      await refresh();
    } finally {
      _inflight = null;
    }
  }

  /// 강제로 최신 개수를 다시 받아온다. (알림함 다녀온 뒤 등)
  /// 요청 시작 시점의 세대를 캡처해, 응답 도착 시 세대가 그대로일 때만 반영한다.
  static Future<void> refresh() async {
    final gen = _gen;
    try {
      final n = await WardService.getNotifications(size: 1);
      set(n.unreadCount, gen: gen);
    } catch (_) {
      // 배지는 부가 정보라 실패 시 조용히 무시
    }
  }

  /// 로그아웃 등 사용자 전환 시 초기화.
  /// 세대를 올려 이전 세션에서 진행 중이던 응답을 모두 무효화한다.
  static void reset() {
    _gen++;
    _loaded = false;
    _inflight = null;
    unread.value = 0;
  }
}
