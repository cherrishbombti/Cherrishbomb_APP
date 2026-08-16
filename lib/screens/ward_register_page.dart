import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter, TextInputType
import '../services/ward_service.dart';
import '../utils/input_formatters.dart';
import '../widgets/logout_button.dart';
import 'home_page.dart';

/// 피보호자 등록 화면. 6개 항목을 입력받아 서버에 등록한다.
class WardRegisterPage extends StatefulWidget {
  const WardRegisterPage({super.key});

  @override
  State<WardRegisterPage> createState() => _WardRegisterPageState();
}

class _WardRegisterPageState extends State<WardRegisterPage> {
  // 여러 입력칸을 한 번에 검증하기 위한 Form 열쇠
  final _formKey = GlobalKey<FormState>();

  // 각 입력칸의 글자를 담는 그릇
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _deviceMac = TextEditingController();

  // 관계는 자유 입력 대신 드롭다운으로 선택
  String? _relationship;
  static const _relationshipOptions = ['자녀', '부모', '배우자', '형제자매', '친척', '기타'];

  bool _loading = false; // 등록 진행 중이면 true

  @override
  void dispose() {
    // 화면이 사라질 때 그릇들 정리 (메모리 누수 방지)
    _name.dispose();
    _birthDate.dispose();
    _address.dispose();
    _phone.dispose();
    _deviceMac.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 모든 입력칸 유효성 검사. 하나라도 실패하면 중단.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await WardService.registerWard(
        name: _name.text.trim(),
        birthDate: _birthDate.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        relationship: _relationship ?? '',
        deviceMac: _deviceMac.text.trim().toUpperCase(), // MAC 대문자로 통일
      );
      if (!mounted) return;
      // 등록 성공 안내 (루트 ScaffoldMessenger라 화면 전환 후에도 표시됨)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피보호자 등록이 완료되었습니다.')),
      );
      // 홈으로 (뒤로가기로 등록 화면 못 돌아오게 pushReplacement)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      debugPrint('피보호자 등록 실패: $e'); // 상세 에러는 개발자 로그에만
      if (!mounted) return;
      // 사용자에겐 일반 안내 문구 (예외 전문 노출 안 함)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록에 실패했습니다. 입력값을 확인하고 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('피보호자 등록'),
        actions: const [LogoutButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_name, '이름', required: true),
              _field(
                _birthDate,
                '생년월일 (YYYY-MM-DD)',
                keyboardType: TextInputType.number,
                inputFormatters: [DashFormatter([4, 2, 2])], // 20000101 → 2000-01-01
                // 월 01~12, 일 01~31 범위 (정규식만으로는 2월 30일 등은 못 거름)
                pattern: r'^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$',
                patternMsg: '생년월일 형식이 올바르지 않습니다. (예: 2000-01-01)',
                // 실제 존재하는 날짜인지 + 미래 날짜 아닌지 검증
                extraCheck: (v) {
                  final parts = v.split('-'); // [연, 월, 일]
                  final date = DateTime.tryParse(v);
                  // 파싱은 되지만 2월 30일처럼 굴러간 날짜면 월/일이 안 맞음
                  if (date == null ||
                      date.month != int.parse(parts[1]) ||
                      date.day != int.parse(parts[2])) {
                    return '존재하지 않는 날짜입니다.';
                  }
                  if (date.isAfter(DateTime.now())) {
                    return '미래 날짜는 입력할 수 없습니다.';
                  }
                  if (date.year < 1900) {
                    return '생년월일을 다시 확인해주세요.';
                  }
                  return null;
                },
              ),
              _field(_address, '주소', required: true),
              _field(
                _phone,
                '전화번호 (010-XXXX-XXXX)',
                required: true,
                keyboardType: TextInputType.number,
                inputFormatters: [DashFormatter([3, 4, 4])], // 01012345678 → 010-1234-5678
                pattern: r'^010-\d{4}-\d{4}$',
                patternMsg: '전화번호 형식이 올바르지 않습니다. (010-XXXX-XXXX)',
              ),
              // 관계: 드롭다운 선택
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _relationship,
                  decoration: const InputDecoration(
                    labelText: '관계',
                    border: OutlineInputBorder(),
                  ),
                  items: _relationshipOptions
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (value) => setState(() => _relationship = value),
                  // 관계는 필수 — 안 고르면 등록 막음
                  validator: (value) => value == null ? '관계를 선택해주세요' : null,
                ),
              ),
              _field(
                _deviceMac,
                '기기 MAC 주소 (AA:BB:CC:DD:EE:FF)',
                required: true,
                inputFormatters: [MacFormatter()], // 16진수만, 2자리마다 ':' 자동 삽입 + 대문자
                pattern: r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$',
                patternMsg: 'MAC 주소 형식이 올바르지 않습니다. (예: AA:BB:CC:DD:EE:FF)',
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                      onPressed: _submit,
                      child: const Text('등록하기'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // 입력칸 하나를 만드는 도우미. required=필수 여부, pattern=형식 검사(선택).
  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    String? pattern,
    String? patternMsg,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? extraCheck, // 형식 통과 후 추가 검증(선택)
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final v = (value ?? '').trim();
          if (required && v.isEmpty) return '$label 입력해주세요';
          if (pattern != null && v.isNotEmpty && !RegExp(pattern).hasMatch(v)) {
            return patternMsg;
          }
          if (extraCheck != null && v.isNotEmpty) {
            final msg = extraCheck(v);
            if (msg != null) return msg;
          }
          return null; // 통과
        },
      ),
    );
  }
}
