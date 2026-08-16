import 'package:flutter/material.dart';
import 'core/app_globals.dart';
import 'screens/splash_page.dart';
import 'screens/login_page.dart';

// 앱의 시작점. 여기서 앱 전체를 실행한다.
void main() {
  runApp(const CherrishbombApp());
}

// 앱의 뿌리(root) 위젯.
class CherrishbombApp extends StatelessWidget {
  const CherrishbombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 전역 리모컨 (401·로그아웃 시 화면 이동에 사용)
      title: '낙상감지 핫 라인 시스템',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashPage(), // 시작 화면 (토큰 확인 후 홈/로그인 분기)
      // 이름있는 경로 — 화면 밖(통신 코드)에서도 이동할 수 있게
      routes: {'/login': (_) => const LoginPage()},
    );
  }
}
