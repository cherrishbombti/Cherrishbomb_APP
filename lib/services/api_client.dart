import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'session.dart';
import 'token_storage.dart';
import '../core/app_router.dart'; // appRouter

/// 앱 전체가 공유하는 서버 통신 창구. (웹 axiosInstance.ts 대응)
class ApiClient {
  // 앱 어디서나 ApiClient.dio 로 같은 통신 객체를 사용 (싱글톤).
  // final을 빼서 테스트 시 mock으로 교체 가능하게 함 (ApiClient.dio = mockDio).
  static Dio dio = _create();

  // 401로 인한 로그인 이동이 동시에 여러 번 실행되지 않도록 막는 플래그
  static bool _redirecting = false;
  // 재발급 동시 실행 방지
  static bool _refreshing = false;

  static Dio _create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // 요청이 나가기 직전: 저장된 토큰을 자동으로 헤더에 첨부
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options); // 다음 단계(실제 요청 전송)로 넘김
        },
        // 정상 응답이 오면 = 다시 인증된 상태 → 플래그 해제
        onResponse: (response, handler) {
          _redirecting = false;
          handler.next(response);
        },
        // 에러 발생 시: 401이면 리프레시 토큰으로 재발급 시도 → 성공하면 원 요청 재시도.
        // 재발급 실패/불가면 그때 토큰 삭제 + 로그인 화면으로.
        onError: (error, handler) async {
          final req = error.requestOptions;
          final is401 = error.response?.statusCode == 401;
          final isRefreshCall = req.path.contains('/api/auth/refresh');
          final alreadyRetried = req.extra['retried'] == true;

          if (is401 && !isRefreshCall && !alreadyRetried) {
            final newToken = await _tryRefresh();
            if (newToken != null) {
              // 새 토큰으로 원 요청 한 번 재시도
              req.extra['retried'] = true;
              req.headers['Authorization'] = 'Bearer $newToken';
              try {
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              } catch (_) {
                // 재시도도 실패 → 아래 로그아웃 처리로
              }
            }
            // 재발급 실패 → 세션 만료 처리 (한 번만)
            // 토큰뿐 아니라 캐시·알림 배지까지 정리해, 다음 로그인에서
            // 이전 사용자의 상태가 남아있지 않게 한다. (로그아웃과 동일 루틴)
            if (!_redirecting) {
              _redirecting = true;
              await Session.clear();
              appRouter.go('/login');
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// 리프레시 토큰으로 새 액세스 토큰 발급. 실패 시 null.
  /// 인터셉터 없는 별도 Dio를 써서 재귀(401 루프)를 막는다.
  static Future<String?> _tryRefresh() async {
    if (_refreshing) return null;
    _refreshing = true;
    try {
      final refresh = await TokenStorage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) return null;

      final plain = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl, headers: {'Content-Type': 'application/json'}));
      final res = await plain.post('/api/auth/refresh', data: {'refreshToken': refresh});

      String? newAccess;
      String? newRefresh;
      final data = res.data;
      if (data is Map) {
        newAccess = (data['token'] ?? data['accessToken']) as String?;
        newRefresh = data['refreshToken'] as String?;
      }
      // 헤더로 오는 경우 폴백
      newAccess ??= res.headers.value('Authorization')?.replaceFirst('Bearer ', '');

      if (newAccess == null || newAccess.isEmpty) return null;
      await TokenStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      return newAccess;
    } catch (_) {
      return null;
    } finally {
      _refreshing = false;
    }
  }
}
