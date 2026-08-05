import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 토큰을 OS 보안 저장소(iOS Keychain 등)에 안전하게 보관하는 도우미.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'accessToken';

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
}
