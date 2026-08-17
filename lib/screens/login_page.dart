import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PlatformException 사용
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'ward_register_page.dart';

/// 로그인 화면. 로딩 상태가 바뀌므로 StatefulWidget.
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
              result.isNewUser ? const WardRegisterPage() : const MainShell(),
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
