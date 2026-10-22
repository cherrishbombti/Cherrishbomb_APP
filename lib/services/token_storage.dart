import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 토큰을 OS 보안 저장소(iOS Keychain 등)에 안전하게 보관하는 도우미.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  static const _refreshKey = 'refreshToken';
  static const _providerKey = 'loginProvider';

  // 토큰 저장 (로그인 성공 시)
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // 토큰 읽기 (없으면 null)
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 토큰 삭제 (로그아웃 / 만료 시)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // 액세스 + 리프레시 토큰 함께 저장 (로그인/재발급 시)
  static Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  // 마지막 로그인 방식 ('kakao' | 'google' | 'apple')
  // Apple 로그인은 이름·이메일을 이미 받으므로 가입 화면에서 다시 묻지 않는 데 쓴다.
  static Future<void> saveLoginProvider(String provider) => _storage.write(key: _providerKey, value: provider);
  static Future<String?> getLoginProvider() => _storage.read(key: _providerKey);

  // 로그아웃 시 전부 삭제
  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _providerKey);
  }
}
