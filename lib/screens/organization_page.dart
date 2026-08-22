import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 숫자 입력 포맷터
import 'package:dio/dio.dart';
import '../models/organization_link.dart';
import '../services/ward_service.dart';

/// 기관 연동 화면. 연동 전=기관번호(6자리) 입력, 연동 후=연동됨 + 해제/변경.
/// 에러(O003·C001)는 입력창 바로 아래 inline으로 표시.
class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _fieldError; // 입력창 하단 inline 에러
  OrganizationLink? _link;
  bool _showInput = false; // 연동 상태에서 '기관 변경' 눌렀을 때
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final link = await WardService.getOrganization();
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = '연동 상태를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final text = _code.text.trim();
    setState(() => _fieldError = null);
    if (text.length != 6) {
      setState(() => _fieldError = '기관번호 6자리를 입력해주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      final link = await WardService.linkOrganization(int.parse(text));
      if (!mounted) return;
      setState(() {
        _link = link;
        _showInput = false;
        _code.clear();
      });
      _snack('기관과 연동되었습니다.');
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final code = data is Map ? data['code'] : null;
      final msg = (data is Map && data['message'] is String) ? data['message'] as String : '연동에 실패했습니다.';
      // O003(없는 번호)·C001(누락)은 입력창 아래, 그 외는 스낵바
      if (code == 'O003' || code == 'C001') {
        setState(() => _fieldError = msg);
      } else if (code == 'M001') {
        _snack('피보호자를 먼저 등록해주세요.');
      } else {
        _snack(msg);
      }
    } catch (e) {
      if (!mounted) return;
      _snack('연동에 실패했습니다. 네트워크를 확인해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _unlink() async {
    setState(() => _saving = true);
    try {
      await WardService.unlinkOrganization();
      if (!mounted) return;
      setState(() => _link = OrganizationLink(linked: false));
      _snack('연동이 해제되었습니다.');
    } catch (e) {
      if (!mounted) return;
      _snack('해제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기관 연동')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _errorView()
          : (_link!.linked && !_showInput ? _linkedView() : _inputForm()),
    );
  }

  Widget _errorView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_loadError!),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('다시 시도')),
      ],
    ),
  );

  // 연동됨
  Widget _linkedView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text('${_link!.organizationName} 연동됨', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('기관번호 ${_link!.orgCode}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          if (_saving)
            const CircularProgressIndicator()
          else ...[
            FilledButton(onPressed: () => setState(() => _showInput = true), child: const Text('기관 변경')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _unlink, child: const Text('연동 해제')),
          ],
        ],
      ),
    );
  }

  // 기관번호 입력
  Widget _inputForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('기관에서 안내받은 6자리 기관번호를 입력하세요.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '기관번호',
              border: const OutlineInputBorder(),
              errorText: _fieldError, // 입력창 하단 inline 에러
            ),
          ),
          const SizedBox(height: 8),
          if (_saving)
            const Center(child: CircularProgressIndicator())
          else
            FilledButton(onPressed: _submit, child: const Text('연동')),
          if (_link!.linked) TextButton(onPressed: () => setState(() => _showInput = false), child: const Text('취소')),
        ],
      ),
    );
  }
}
