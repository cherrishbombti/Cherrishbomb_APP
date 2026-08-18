import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../services/ward_service.dart';
import '../widgets/log_tile.dart';

/// 활동·낙상 이력 화면. 날짜 필터 + 로그 목록 + 페이지네이션.
/// 표시 기준은 백엔드 실제 데이터(logType + status)를 따른다. (와이어프레임은 참고용)
class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  bool _loading = true;
  String? _error;
  LogPage? _data;
  int _pageNum = 0; // 현재 조회 중인 페이지 (0부터)
  DateTime? _from; // 시작일 필터 (선택)
  DateTime? _to; // 종료일 필터 (선택)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await WardService.getLogs(
        page: _pageNum,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('활동 이력 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '활동 이력을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  // 날짜 선택 후 필터에 반영 (조회 버튼을 눌러야 실제 조회)
  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  // 조회 버튼: 필터를 적용하고 첫 페이지부터 다시 조회
  void _search() {
    _pageNum = 0;
    _load();
  }

  void _goPage(int p) {
    _pageNum = p;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('활동 로그')),
      body: Column(
        children: [
          _filterBar(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // 상단 날짜 필터 바 (시작일 ~ 종료일 + 조회)
  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _dateField('시작일', _from, () => _pickDate(isFrom: true))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('~'),
          ),
          Expanded(child: _dateField('종료일', _to, () => _pickDate(isFrom: false))),
          const SizedBox(width: 8),
          FilledButton(onPressed: _search, child: const Text('조회')),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(value == null ? label : _ymd(value)),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
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
    final logs = _data?.content ?? [];
    if (logs.isEmpty) {
      return const Center(
        child: Text('해당 기간의 활동 이력이 없습니다.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length + 1, // 마지막 칸은 페이지네이션
        itemBuilder: (_, i) =>
            i < logs.length ? LogTile(logs[i]) : _pagination(),
      ),
    );
  }

  // 하단 페이지 이동 (이전 / 현재/전체 / 다음)
  Widget _pagination() {
    final d = _data;
    if (d == null || d.totalPages <= 1) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: d.page > 0 ? () => _goPage(d.page - 1) : null,
          ),
          Text('${d.page + 1} / ${d.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: !d.last ? () => _goPage(d.page + 1) : null,
          ),
        ],
      ),
    );
  }

  // ---- 날짜 포맷 헬퍼 (intl 패키지 없이 직접) ----
  String _ymd(DateTime d) => '${d.year}-${_pad2(d.month)}-${_pad2(d.day)}';

  String _pad2(int n) => n.toString().padLeft(2, '0');
}
