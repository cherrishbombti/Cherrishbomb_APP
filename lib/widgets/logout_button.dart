import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

/// 여러 화면에서 재사용하는 로그아웃 버튼.
/// 토큰 삭제 후 로그인 화면('/login')으로 이동한다.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: '로그아웃',
      onPressed: () async {
        await AuthService.logout();
        if (!context.mounted) return;
        // 로그인 화면으로 (스택 갈아끼움)
        context.go('/login');
      },
    );
  }
}
