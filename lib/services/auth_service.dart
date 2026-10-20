import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/api_config.dart';
import 'api_client.dart';
import 'notification_service.dart';
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

    // 4) 이 기기의 FCM 토큰을 백엔드에 등록 (실패해도 로그인은 진행)
    await NotificationService.registerToken();

    return AuthResult(isNewUser);
  }

  /// Apple 로그인 (iOS 전용, App Store 가이드라인 4.8).
  /// 아이폰 기본 Apple 로그인 창 → 받은 identityToken 을 백엔드가 검증 → 우리 토큰 발급.
  /// 사용자가 창을 닫으면 SignInWithAppleAuthorizationException(canceled) 이 그대로 올라간다.
  static Future<AuthResult> loginWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // 이름은 "처음 로그인할 때만" 온다. 한국식으로 성+이름.
    final name = '${credential.familyName ?? ''}${credential.givenName ?? ''}'.trim();

    final res = await ApiClient.dio.post(
      '/api/auth/apple',
      data: {
        'identityToken': credential.identityToken,
        'authorizationCode': credential.authorizationCode,
        if (name.isNotEmpty) 'name': name,
      },
    );

    final data = res.data as Map;
    final token = data['token'] as String?;
    if (token == null) {
      throw Exception('로그인 응답에 토큰이 없습니다.');
    }
    await TokenStorage.saveTokens(accessToken: token, refreshToken: data['refreshToken'] as String?);
    await NotificationService.registerToken();
    return AuthResult(data['isNewUser'] == true);
  }

  /// 로그아웃. 서버에 폐기 요청 후 로컬 토큰 삭제.
  static Future<void> logout() async {
    // 이 기기 FCM 토큰을 서버에서 제거 (토큰 삭제 전에 = 인증 헤더 살아있을 때)
    await NotificationService.unregisterToken();
    try {
      // 서버의 리프레시 토큰도 폐기 (실패해도 로컬은 반드시 정리)
      await ApiClient.dio.post('/api/auth/logout');
    } catch (_) {
      // 네트워크 실패 등은 무시 — 로컬 정리가 우선
    }
    // 토큰·캐시·알림 배지까지 한 번에 정리 (401 만료 경로와 동일 루틴)
    await Session.clear();
  }

  /// 회원탈퇴. 서버에서 계정·연결 데이터(피보호자·연락처·건강·알림·기기토큰)를 삭제한 뒤
  /// 로컬 세션을 정리한다. 되돌릴 수 없다.
  static Future<void> withdraw() async {
    // 서버 삭제가 성공해야 로컬을 정리한다 (실패 시 예외를 그대로 올림)
    await ApiClient.dio.delete('/api/wards/me/account');
    await Session.clear();
  }
}
