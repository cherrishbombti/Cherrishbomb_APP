import 'package:flutter/material.dart';

import '../models/ward_health.dart';
import '../services/ward_service.dart';
import '../widgets/health_form.dart';
import '../widgets/health_read_view.dart';

/// 건강 정보 관리 화면. 평소엔 조회(읽기 전용), "수정"을 누르면 편집 모드.
class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false; // 조회(false) ↔ 수정(true)
  String? _error;
  final _disease = TextEditingController();
  final _medication = TextEditingController();
  final _memo = TextEditingController();
  WardHealth? _health; // 마지막으로 불러온 값 (취소 시 되돌리기용)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disease.dispose();
    _medication.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final h = await WardService.getHealth();
      if (!mounted) return;
      _bind(h);
      setState(() {
        _health = h;
        _loading = false;
        _editing = false;
      });
    } catch (e) {
      debugPrint('건강정보 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '건강 정보를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  // 컨트롤러에 값 채우기
  void _bind(WardHealth h) {
    _disease.text = h.disease;
    _medication.text = h.medication;
    _memo.text = h.memo;
  }

  void _cancelEdit() {
    if (_health != null) _bind(_health!); // 편집 내용 폐기, 원래 값 복원
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await WardService.putHealth(
        disease: _disease.text.trim(),
        medication: _medication.text.trim(),
        memo: _memo.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
      _load(); // 최종 수정 정보 갱신 + 조회 모드로
    } catch (e) {
      debugPrint('건강정보 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // 수정 모드에서 뒤로가기 시 저장 안 한 변경 폐기 확인
  Future<bool?> _confirmLeave() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('편집 취소'),
        content: const Text('저장하지 않은 변경 내용이 있습니다. 나가시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 편집')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('나가기')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 수정 중이면 바로 못 나가게 막고 확인 다이얼로그
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context); // await 전에 캡처 (context 사용 회피)
        final leave = await _confirmLeave();
        if (leave == true) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('건강 정보 관리'),
          actions: [
            if (!_loading && _error == null && !_editing)
              IconButton(icon: const Icon(Icons.edit), tooltip: '수정', onPressed: () => setState(() => _editing = true)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorView()
            : (_editing
                  ? HealthForm(
                      disease: _disease,
                      medication: _medication,
                      memo: _memo,
                      saving: _saving,
                      onCancel: _cancelEdit,
                      onSave: _save,
                    )
                  : HealthReadView(_health!)),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_error!),
        const SizedBox(height: 12),
        FilledButton(onPressed: _load, child: const Text('다시 시도')),
      ],
    ),
  );
}
