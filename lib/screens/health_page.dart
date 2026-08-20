import 'package:flutter/material.dart';
import '../services/ward_service.dart';
import '../utils/date_format.dart';

/// 건강 정보 관리 화면. 기저질환·복용약·병력 조회/저장 (member_health).
class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final _disease = TextEditingController();
  final _medication = TextEditingController();
  final _memo = TextEditingController();
  String? _updatedByName;
  String? _updatedAt;

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
      _disease.text = h.disease;
      _medication.text = h.medication;
      _memo.text = h.memo;
      setState(() {
        _updatedByName = h.updatedByName;
        _updatedAt = h.updatedAt;
        _loading = false;
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // 세 필드 모두 필수 — 비운 값은 빈 문자열로 전송
      await WardService.putHealth(
        disease: _disease.text.trim(),
        medication: _medication.text.trim(),
        memo: _memo.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장되었습니다.')),
      );
      _load(); // 최종 수정 정보 갱신
    } catch (e) {
      debugPrint('건강정보 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('건강 정보 관리')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _form(),
    );
  }

  Widget _errorView() {
    return Center(
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

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field('기저질환', _disease, hint: '예: 고혈압, 당뇨'),
        const SizedBox(height: 12),
        _field('복용약', _medication, hint: '예: 메트포르민'),
        const SizedBox(height: 12),
        _field('기타 병력·메모', _memo, hint: '예: 2024년 낙상 이력', lines: 4),
        const SizedBox(height: 8),
        if (_updatedAt != null)
          Text(
            '최종 수정: ${_fmt(_updatedAt)}'
            '${_updatedByName != null ? ' ($_updatedByName)' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        const SizedBox(height: 16),
        _saving
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(onPressed: _save, child: const Text('저장')),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _fmt(String? raw) {
    if (raw == null) return '-';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : ymd(d);
  }
}
