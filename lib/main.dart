import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PlatformException 사용
import 'services/auth_service.dart';
import 'services/token_storage.dart';
import 'services/ward_service.dart';

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

// 피보호자 등록 화면. 6개 항목을 입력받아 서버에 등록한다.
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
        deviceMac: _deviceMac.text.trim(),
      );
      if (!mounted) return;
      // 등록 성공 → 홈으로 (뒤로가기로 등록 화면 못 돌아오게 pushReplacement)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
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
                inputFormatters: [_DashFormatter([4, 2, 2])], // 20000101 → 2000-01-01
                pattern: r'^\d{4}-\d{2}-\d{2}$',
                patternMsg: '생년월일 형식이 올바르지 않습니다. (예: 2000-01-01)',
              ),
              _field(_address, '주소', required: true),
              _field(
                _phone,
                '전화번호 (010-XXXX-XXXX)',
                required: true,
                keyboardType: TextInputType.number,
                inputFormatters: [_DashFormatter([3, 4, 4])], // 01012345678 → 010-1234-5678
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
                ),
              ),
              _field(
                _deviceMac,
                '기기 MAC 주소 (AA:BB:CC:DD:EE:FF)',
                required: true,
                pattern: r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$',
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
          return null; // 통과
        },
      ),
    );
  }
}

// 숫자만 입력받아 지정한 자리마다 '-'를 자동으로 넣어주는 포매터.
// 예) groups=[3,4,4] → 01012345678 을 010-1234-5678 로,
//     groups=[4,2,2] → 20000101 을 2000-01-01 로 자동 변환.
class _DashFormatter extends TextInputFormatter {
  final List<int> groups;
  _DashFormatter(this.groups);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 숫자만 남기고
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final maxLen = groups.reduce((a, b) => a + b);
    final trimmed =
        digits.length > maxLen ? digits.substring(0, maxLen) : digits;

    // 그룹 단위로 잘라서 '-'로 연결
    final buffer = StringBuffer();
    int idx = 0;
    for (int i = 0; i < groups.length && idx < trimmed.length; i++) {
      if (i > 0) buffer.write('-');
      final end = (idx + groups[i]).clamp(0, trimmed.length);
      buffer.write(trimmed.substring(idx, end));
      idx = end;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length), // 커서 맨 뒤로
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
