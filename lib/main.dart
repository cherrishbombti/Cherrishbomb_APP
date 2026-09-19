import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_router.dart';
import 'theme/app_theme.dart';

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
      debugShowCheckedModeBanner: false, // 우측 상단 DEBUG 리본 숨김
      theme: AppTheme.light,
      // 날짜 선택기 등 Material 기본 UI를 한국어로
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko'), Locale('en')],
      locale: const Locale('ko'),
      // 라우팅은 전부 appRouter(go_router)가 담당
      routerConfig: appRouter,
    );
  }
}
