import 'package:flutter/foundation.dart'; // defaultTargetPlatform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PlatformException 사용
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/legal_links.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// 로그인 화면. 로딩 상태가 바뀌므로 StatefulWidget.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false; // 로그인 진행 중이면 true

  // Apple 로그인 버튼은 아이폰에서만 보인다 (안드로이드는 카카오·구글만).
  bool get _showApple => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // 소셜 로그인 버튼을 눌렀을 때 실행. provider: 'kakao' | 'google' | 'apple'
  Future<void> _handleLogin(String provider) async {
    setState(() => _loading = true);
    try {
      final result = provider == 'apple' ? await AuthService.loginWithApple() : await AuthService.login(provider);
      if (!mounted) return; // 화면이 이미 사라졌으면 중단
      // 신규 사용자면 피보호자 등록 화면, 기존이면 홈으로.
      context.go(result.isNewUser ? '/register' : '/home');
    } on PlatformException catch (e) {
      if (!mounted) return;
      // 사용자가 로그인 창을 그냥 닫음(취소) → 에러 아님, 조용히 넘김
      if (e.code == 'CANCELED') return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: ${e.message ?? e.code}')));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted) return;
      // Apple 로그인 창을 닫음(취소) → 조용히 넘김
      if (e.code == AuthorizationErrorCode.canceled) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Apple 로그인 실패: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
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
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset('assets/images/logo.png', width: 108, height: 108, fit: BoxFit.cover),
                ),
              ),
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
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (_showApple) ...[_appleButton(), const SizedBox(height: 12)],
                _kakaoButton(),
                const SizedBox(height: 12),
                _googleButton(),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => LegalLinks.open(LegalLinks.privacyPolicy),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  child: const Text('개인정보 처리방침', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Apple: Apple 이 제공하는 공식 버튼 (디자인 가이드 준수)
  Widget _appleButton() {
    return SignInWithAppleButton(
      onPressed: () => _handleLogin('apple'),
      text: 'Apple로 로그인',
      height: 52,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    );
  }

  // 카카오: 브랜드 노란색 + 말풍선 아이콘
  Widget _kakaoButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: () => _handleLogin('kakao'),
        icon: SvgPicture.asset('assets/social/kakao.svg', width: 18, height: 18),
        label: const Text('카카오로 로그인'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF3C1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // 구글: 흰 배경 + 테두리 + 'G' 마크
  Widget _googleButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogin('google'),
        icon: SvgPicture.asset('assets/social/google.svg', width: 18, height: 18),
        label: const Text('구글로 로그인'),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
