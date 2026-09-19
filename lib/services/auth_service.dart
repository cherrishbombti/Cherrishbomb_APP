import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/api_config.dart';
import 'api_client.dart';
import 'session.dart';
import 'token_storage.dart';

/// 로그인 결과. isNewUser: 아직 피보호자 등록 안 한 신규 사용자인지.
class AuthResult {
  final bool isNewUser;
  AuthResult(this.isNewUser);
}

/// 소셜 로그인 처리 담당. (웹 auth.ts 대응)
class AuthService {
  /// 소셜 로그인 실행. provider: 'google' 또는 'kakao'
  static Future<AuthResult> login(String provider) async {
    // 1) 백엔드 로그인 URL을 앱 내 브라우저(ASWebAuthenticationSession)로 연다.
    //    백엔드가 구글/카카오 로그인을 처리한 뒤,
    //    cherrishbomb://login?token=JWT&isNewUser=... 로 앱에 복귀시킨다.
    //    ?state=app 은 "앱에서 왔다"는 신호 (백엔드가 앱 주소로 돌려보내게 하는 용도).
    final result = await FlutterWebAuth2.authenticate(
      url: '${ApiConfig.baseUrl}/api/auth/$provider?state=app',
      callbackUrlScheme: 'cherrishbomb',
    );

    // 2) 복귀한 주소에서 token, isNewUser 값을 꺼낸다.
    final uri = Uri.parse(result);
    final token = uri.queryParameters['token'];
    // 백엔드가 함께 내려주는 리프레시 토큰(있으면 저장)
    final refreshToken = uri.queryParameters['refreshToken'];
    final isNewUser = uri.queryParameters['isNewUser'] == 'true';

    if (token == null) {
      throw Exception('로그인 응답에 토큰이 없습니다.');
    }

    // 3) 액세스 + 리프레시 토큰을 보안 저장소에 저장한다.
    await TokenStorage.saveTokens(accessToken: token, refreshToken: refreshToken);

    return AuthResult(isNewUser);
  }

  /// 로그아웃. 서버에 폐기 요청 후 로컬 토큰 삭제.
  static Future<void> logout() async {
    try {
      // 서버의 리프레시 토큰도 폐기 (실패해도 로컬은 반드시 정리)
      await ApiClient.dio.post('/api/auth/logout');
    } catch (_) {
      // 네트워크 실패 등은 무시 — 로컬 정리가 우선
    }
    // 토큰·캐시·알림 배지까지 한 번에 정리 (401 만료 경로와 동일 루틴)
    await Session.clear();
  }
}
