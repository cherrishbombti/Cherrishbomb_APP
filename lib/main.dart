import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/app_router.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

/// 백그라운드(앱 종료·최소화)에서 푸시가 올 때 실행되는 최상위 핸들러.
/// 알림 배너 표시는 OS가 처리하므로 여기선 초기화만 보장한다.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// 앱의 시작점. Firebase·알림 초기화 후 앱을 실행한다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // iOS는 GoogleService-Info.plist, Android는 google-services.json 을 자동으로 읽어 초기화된다.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await NotificationService.init();
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
