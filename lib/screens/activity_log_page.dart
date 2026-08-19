import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../services/ward_service.dart';
import '../widgets/log_filter_bar.dart';
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
  final _scroll = ScrollController(); // 페이지 전환 시 상단으로 이동용

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // 목록 조회 공통 경로. 조회/새로고침/페이지이동/초기화 모두 이곳을 탄다.
  // 날짜 가드도 여기서 처리해 어떤 경로로 와도 우회되지 않는다. (리뷰 반영)
  Future<void> _load() async {
    // 시작일 > 종료일이면 조회하지 않고 안내 (서버 INVALID_DATE_RANGE 방지)
    if (_from != null && _to != null && _from!.isAfter(_to!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일이 종료일보다 늦을 수 없습니다.')),
      );
      return;
    }
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
      // 페이지가 바뀌어도 스크롤이 그대로면 전환을 인지하기 어려워 맨 위로 이동
      if (_scroll.hasClients) _scroll.jumpTo(0);
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

  // 조회 버튼: 첫 페이지부터 다시 조회 (가드는 _load에서 처리)
  void _search() {
    _pageNum = 0;
    _load();
  }

  // 날짜 필터 초기화 → 전체 조회
  void _resetFilter() {
    setState(() {
      _from = null;
      _to = null;
    });
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
      appBar: AppBar(
        title: const Text('활동 로그'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            tooltip: '필터 초기화',
            onPressed: _resetFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          LogFilterBar(
            from: _from,
            to: _to,
            onPickFrom: () => _pickDate(isFrom: true),
            onPickTo: () => _pickDate(isFrom: false),
            onSearch: _search,
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
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
      // 필터 유무에 따라 메시지 구분 (필터 안 걸었는데 "해당 기간" 표현은 혼란)
      final hasFilter = _from != null || _to != null;
      return Center(
        child: Text(
          hasFilter ? '해당 기간의 활동 이력이 없습니다.' : '아직 활동 이력이 없습니다.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
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
}
