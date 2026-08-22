import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/token_storage.dart';

/// 앱 시작 시 저장된 토큰을 확인해 첫 화면을 정하는 화면.
/// 토큰 있음 → 홈으로, 토큰 없음 → 로그인 화면으로.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _decideStart(); // 화면이 생기자마자 한 번 실행
  }

  Future<void> _decideStart() async {
    final token = await TokenStorage.getToken(); // 저장된 토큰 확인
    if (!mounted) return;
    context.go(token != null ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    // 토큰 확인은 순식간이지만, 그동안 잠깐 로딩 표시
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
