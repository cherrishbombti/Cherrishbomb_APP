import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/ward_service.dart';
import '../widgets/logout_button.dart';
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

  @override
  void dispose() {
    for (final c in [
      _guardianName, _guardianPhone, _relationship,
      _wardName, _address, _wardPhone, _disease, _deviceMac,
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
    setState(() => _loading = true);
    try {
      await WardService.registerWard(
        name: _wardName.text.trim(),
        birthDate: '', // 생년월일/나이 미수집 → 빈 값 (백엔드 age 계산 스킵)
        address: _address.text.trim(),
        phone: _wardPhone.text.trim(),
        relationship: _relationship.text.trim(),
        deviceMac: _deviceMac.text.trim().toUpperCase(),
        // TODO(백엔드): 보호자 이름/연락처, 기저질환(_disease) 저장 필드 연동
      );
      if (!mounted) return;
      _snack('회원가입이 완료되었습니다.');
      context.go('/home');
    } catch (e) {
      debugPrint('회원가입 실패: $e');
      if (!mounted) return;
      _snack('등록에 실패했습니다. 입력값을 확인하고 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입'), actions: const [LogoutButton()]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('STEP ${_step + 1} / 2',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('회원가입',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('보호자와 피보호자 정보를 입력해주세요',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _tabToggle(),
            const SizedBox(height: 20),
            IndexedStack(index: _step, children: [
              RegStep1(
                formKey: _form1,
                name: _guardianName,
                phone: _guardianPhone,
                relationship: _relationship,
              ),
              RegStep2(
                formKey: _form2,
                name: _wardName,
                address: _address,
                phone: _wardPhone,
                disease: _disease,
                deviceMac: _deviceMac,
              ),
            ]),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()) else _nav(),
          ],
        ),
      ),
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
          child: OutlinedButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('이전')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(onPressed: _submit, child: const Text('가입 완료')),
        ),
      ],
    );
  }
}
