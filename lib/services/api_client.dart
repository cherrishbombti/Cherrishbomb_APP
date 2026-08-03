import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'token_storage.dart';
import '../main.dart'; // navigatorKey, LoginPage 사용

/// 앱 전체가 공유하는 서버 통신 창구. (웹 axiosInstance.ts 대응)
class ApiClient {
  // 앱 어디서나 ApiClient.dio 로 같은 통신 객체를 사용 (싱글톤)
  static final Dio dio = _create();

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
        // 에러 발생 시: 401(인증 만료)이면 토큰 삭제 + 로그인 화면으로 이동
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await TokenStorage.deleteToken();
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false, // 이전 화면 스택을 모두 비움
            );
          }
          handler.next(error); // 에러를 다음 단계로 넘김
        },
      ),
    );

    return dio;
  }
}
