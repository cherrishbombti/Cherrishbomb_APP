import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../config/legal_links.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/ward_service.dart';
import '../theme/app_colors.dart';
import '../widgets/reg_steps.dart';

/// 회원가입 — 2단계 위저드 (STEP1 보호자 정보 / STEP2 피보호자 정보).
/// 백엔드 미지원 필드(보호자 이름·연락처, 기저질환)는 수집만 하고 저장은 TODO.
class WardRegisterPage extends StatefulWidget {
  const WardRegisterPage({super.key});

  @override
  State<WardRegisterPage> createState() => _WardRegisterPageState();
}

class _WardRegisterPageState extends State<WardRegisterPage> {
  int _step = 0;
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();

  // STEP1 보호자 정보
  final _guardianName = TextEditingController();
  final _guardianPhone = TextEditingController();
  final _relationship = TextEditingController();
  // STEP2 피보호자 정보
  final _wardName = TextEditingController();
  final _address = TextEditingController();
  final _wardPhone = TextEditingController();
  final _disease = TextEditingController();
  final _deviceMac = TextEditingController();

  bool _loading = false;

  // Apple 로그인이면 보호자 이름을 묻지 않는다 (Apple 이 이미 제공)
  bool _isApple = false;

  @override
  void initState() {
    super.initState();
    TokenStorage.getLoginProvider().then((p) {
      if (mounted && p == 'apple') setState(() => _isApple = true);
    });
  }

  // 가입 동의 (개인정보 보호법: 필수/선택·민감정보 별도 동의)
  bool _agreePrivacy = false; // [필수] 개인정보 수집·이용
  bool _agreeWardConsent = false; // [필수] 피보호자·비상연락처 본인 동의 받음 확인
  bool _agreeHealth = false; // [선택] 건강정보(민감정보) 수집·이용

  @override
  void dispose() {
    for (final c in [
      _guardianName,
      _guardianPhone,
      _relationship,
      _wardName,
      _address,
      _wardPhone,
      _disease,
      _deviceMac,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_form1.currentState!.validate()) setState(() => _step = 1);
  }

  Future<void> _submit() async {
    if (!_form2.currentState!.validate()) return;
    if (!_form1.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }
    if (!_agreePrivacy || !_agreeWardConsent) {
      _snack('필수 동의 항목에 체크해주세요.');
      return;
    }
    // 건강정보는 민감정보 — 동의하지 않았으면 보내지 않는다
    final disease = _agreeHealth ? _disease.text.trim() : '';
    if (!_agreeHealth && _disease.text.trim().isNotEmpty) {
      _snack('기저질환을 입력하려면 건강정보 수집·이용에 동의해주세요.');
      return;
    }
    setState(() => _loading = true);
    try {
      await WardService.registerWard(
        name: _wardName.text.trim(),
        // 생년월일/나이 미수집 → birthDate 생략 (서버는 없으면 age 계산 스킵)
        address: _address.text.trim(),
        phone: _wardPhone.text.trim(),
        relationship: _relationship.text.trim(),
        deviceMac: _deviceMac.text.trim().toUpperCase(),
        guardianName: _isApple ? null : _guardianName.text.trim(),
        guardianPhone: _guardianPhone.text.trim(),
        disease: disease,
      );
      if (!mounted) return;
      _snack('회원가입이 완료되었습니다.');
      context.go('/home');
    } on DioException catch (e) {
      // 서버가 내려주는 사유({message})를 그대로 안내 (예: 이미 등록된 피보호자입니다)
      debugPrint('회원가입 실패: ${e.response?.data ?? e.message}');
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['message'] is String)
          ? data['message'] as String
          : '등록에 실패했습니다. 입력값을 확인하고 다시 시도해주세요.';
      _snack(msg);
    } catch (e) {
      debugPrint('회원가입 실패: $e');
      if (!mounted) return;
      _snack('등록에 실패했습니다. 네트워크 상태를 확인해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // 가입 중단 시 안전하게 로그아웃 (토큰 삭제 후 로그인 화면으로)
  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 가입을 중단하려는 사용자를 위한 로그아웃 경로 (상단 AppBar 대체)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('로그아웃'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ),
              Text(
                'STEP ${_step + 1} / 2',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '회원가입',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '보호자와 피보호자 정보를 입력해주세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _tabToggle(),
              const SizedBox(height: 20),
              IndexedStack(
                index: _step,
                children: [
                  RegStep1(
                    formKey: _form1,
                    name: _guardianName,
                    phone: _guardianPhone,
                    relationship: _relationship,
                    showName: !_isApple,
                  ),
                  RegStep2(
                    formKey: _form2,
                    name: _wardName,
                    address: _address,
                    phone: _wardPhone,
                    disease: _disease,
                    deviceMac: _deviceMac,
                  ),
                ],
              ),
              if (_step == 1) ...[const SizedBox(height: 8), _consents()],
              const SizedBox(height: 12),
              if (_loading) const Center(child: CircularProgressIndicator()) else _nav(),
            ],
          ),
        ),
      ),
    );
  }

  /// 가입 동의 체크박스 묶음 (STEP2 하단)
  Widget _consents() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _consentTile(
            value: _agreePrivacy,
            onChanged: (v) => setState(() => _agreePrivacy = v),
            label: '[필수] 개인정보 수집·이용 및 국외 이전(서버·푸시) 동의',
          ),
          _consentTile(
            value: _agreeWardConsent,
            onChanged: (v) => setState(() => _agreeWardConsent = v),
            label: '[필수] 피보호자·비상 연락처 본인(또는 법정대리인)의 동의를 받았습니다',
          ),
          _consentTile(
            value: _agreeHealth,
            onChanged: (v) => setState(() => _agreeHealth = v),
            label: '[선택] 건강정보(민감정보) 수집·이용 동의 — 기저질환·복용약 입력 시 필요',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => LegalLinks.open(LegalLinks.privacyPolicy),
              child: const Text('개인정보 처리방침 전문 보기', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consentTile({required bool value, required ValueChanged<bool> onChanged, required String label}) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _tabToggle() {
    return Row(
      children: [
        Expanded(child: _tab('보호자 정보', 0)),
        const SizedBox(width: 8),
        Expanded(child: _tab('피보호자 정보', 1)),
      ],
    );
  }

  Widget _tab(String label, int index) {
    final selected = _step == index;
    final primary = Theme.of(context).colorScheme.primary;
    return FilledButton(
      onPressed: () => index == 1 ? _next() : setState(() => _step = 0),
      style: FilledButton.styleFrom(
        backgroundColor: selected ? primary : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : Colors.black54,
      ),
      child: Text(label),
    );
  }

  Widget _nav() {
    if (_step == 0) {
      return FilledButton(onPressed: _next, child: const Text('다음'));
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: () => setState(() => _step = 0), child: const Text('이전')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: _submit, child: const Text('가입 완료')),
        ),
      ],
    );
  }
}
