import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PlatformException 사용
import 'services/auth_service.dart';
import 'services/token_storage.dart';

// 화면 밖(통신 코드 등)에서도 화면 이동을 할 수 있게 하는 전역 리모컨.
final navigatorKey = GlobalKey<NavigatorState>();

// 앱의 시작점. 여기서 앱 전체를 실행한다.
void main() {
  runApp(const CherrishbombApp());
}

// 앱의 뿌리(root) 위젯. 화면이 바뀌지 않는 껍데기라 StatelessWidget.
class CherrishbombApp extends StatelessWidget {
  const CherrishbombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // 전역 리모컨 연결 (401 시 화면 이동에 사용)
      title: '낙상감지 핫 라인 시스템',
      // 앱 전체의 기본 색/폰트 테마
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // 앱을 켜면 처음 보이는 화면 (토큰 확인 후 홈/로그인으로 분기)
      home: const SplashPage(),
    );
  }
}

// 앱 시작 시 저장된 토큰을 확인해 첫 화면을 정하는 화면.
// 토큰 있음 → 홈으로 바로, 토큰 없음 → 로그인 화면으로.
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => token != null ? const HomePage() : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 토큰 확인은 순식간이지만, 그동안 잠깐 로딩 표시
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// 로그인 화면. 로딩 상태가 바뀌므로 StatefulWidget.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false; // 로그인 진행 중이면 true

  // 소셜 로그인 버튼을 눌렀을 때 실행.
  Future<void> _handleLogin(String provider) async {
    setState(() => _loading = true);
    try {
      final result = await AuthService.login(provider);
      if (!mounted) return; // 화면이 이미 사라졌으면 중단
      // 신규 사용자면 피보호자 등록 화면, 기존이면 홈으로.
      // pushReplacement: 로그인 화면을 치우고 새 화면으로 (뒤로가기로 로그인 못 돌아오게)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              result.isNewUser ? const WardRegisterPage() : const HomePage(),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      // 사용자가 로그인 창을 그냥 닫음(취소) → 에러 아님, 조용히 넘김
      if (e.code == 'CANCELED') return;
      // 그 외 플랫폼 오류만 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      // 그 밖의 오류 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.favorite, size: 72, color: Colors.deepPurple),
              const SizedBox(height: 16),
              const Text(
                '낙상감지 핫 라인 시스템',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '보호자 로그인',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // 로그인 중이면 로딩 표시, 아니면 버튼들 표시
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  onPressed: () => _handleLogin('kakao'),
                  child: const Text('카카오로 로그인'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _handleLogin('google'),
                  child: const Text('구글로 로그인'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// 피보호자 등록 화면 (임시 stub — 실제 구현은 이슈 4).
class WardRegisterPage extends StatelessWidget {
  const WardRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피보호자 등록'),
        actions: const [LogoutButton()],
      ),
      body: const Center(child: Text('피보호자 등록 화면 (이슈 4에서 구현)')),
    );
  }
}

// 임시 홈 화면. 로그인 성공 후 보여줄 화면 (지금은 뼈대만).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: const [LogoutButton()],
      ),
      body: const Center(
        child: Text('로그인 성공! 홈 화면입니다.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// 여러 화면에서 재사용하는 로그아웃 버튼.
// 토큰 삭제 후 로그인 화면으로 이동한다.
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      },
    );
  }
}
