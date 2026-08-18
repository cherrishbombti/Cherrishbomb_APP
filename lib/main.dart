import 'package:flutter/material.dart';
import 'core/app_router.dart';

// 앱의 시작점. 여기서 앱 전체를 실행한다.
void main() {
  runApp(const CherrishbombApp());
}

// 앱의 뿌리(root) 위젯.
class CherrishbombApp extends StatelessWidget {
  const CherrishbombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '낙상감지 핫 라인 시스템',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // 라우팅은 전부 appRouter(go_router)가 담당
      routerConfig: appRouter,
    );
  }
}
