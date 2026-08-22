import 'package:go_router/go_router.dart';

import '../screens/splash_page.dart';
import '../screens/login_page.dart';
import '../screens/ward_register_page.dart';
import '../screens/main_shell.dart';

/// 앱 전역 라우터. 모든 화면 진입을 이 한 곳에서 관리한다.
/// (기존에 splash/login/ward_register에 흩어져 있던 MainShell 진입 코드를 통합)
///
/// 화면 밖(통신 코드 등)에서도 appRouter.go('/login') 처럼 이동 가능.
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, _) => const WardRegisterPage()),
    GoRoute(path: '/home', builder: (_, _) => const MainShell()),
  ],
);
