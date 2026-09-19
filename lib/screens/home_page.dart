import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 전화 걸기
import '../utils/phone_format.dart';
import '../models/ward_summary.dart';
import '../models/ward_sensor.dart';
import '../services/notification_store.dart';
import '../services/ward_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/app_header.dart';
import '../widgets/home_widgets.dart';

/// 홈(보호자 모드). 피보호자 상태 요약 + 낙상 감지 센서 상태를 표시.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _loading = true; // 데이터 불러오는 중
  String? _error; // 에러 메시지 (없으면 null)
  WardSummary? _summary;
  WardSensor? _sensor;

  Timer? _poll; // 자동 새로고침 타이머
  bool _paused = false; // 앱이 백그라운드면 true → 폴링 스케줄 금지

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 포그라운드/백그라운드 감지
    _load().then((_) => _schedulePoll()); // 첫 로드 후 자동 새로고침 시작
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 앱이 백그라운드면 폴링 중지(배터리·네트워크 절약), 돌아오면 즉시 갱신 후 재개.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      _tick(); // 즉시 한 번 갱신하고, 끝나면 스케줄 재개
    } else {
      _paused = true;
      _poll?.cancel();
    }
  }

  // 상태에 따라 새로고침 간격을 정한다.
  // 낙상을 빨리 잡아야 하므로 평소(SAFE)에도 짧게, 주의·위험이면 더 자주.
  Duration get _pollInterval {
    final st = _summary?.status;
    return (st == 'DANGER' || st == 'WARNING') ? const Duration(seconds: 2) : const Duration(seconds: 5);
  }

  // 스케줄 함수 자체에서 lifecycle을 확인한다.
  // 백그라운드로 간 뒤 진행 중이던 _tick·_load가 뒤늦게 호출해도 새 타이머가 안 생긴다.
  void _schedulePoll() {
    _poll?.cancel();
    if (_paused || !mounted) return;
    _poll = Timer(_pollInterval, _tick);
  }

  Future<void> _tick() async {
    await _silentRefresh();
    _schedulePoll(); // 매번 현재 상태 기준으로 다음 간격 재설정 (paused면 내부에서 중단)
  }

  // 스피너 없이 조용히 최신값만 반영. 실패해도 기존 화면 유지.
  Future<void> _silentRefresh() async {
    try {
      final results = await Future.wait([WardService.getSummary(force: true), WardService.getSensors(force: true)]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as WardSummary;
        _sensor = results[1] as WardSensor;
      });
    } catch (_) {
      // 요약/센서 실패는 조용히 무시 (다음 주기에 재시도)
    } finally {
      // 홈 요약/센서 실패와 무관하게 안읽음 배지는 갱신한다.
      // await 해서 미완료 갱신이 다음 폴링과 겹치지 않게 한다.
      await NotificationStore.refresh();
    }
  }

  // 요약 + 센서 데이터를 서버에서 불러온다. (두 요청은 독립적이라 병렬 호출)
  // force=true 는 캐시를 건너뛰고 서버에서 새로 받는다. (당겨서 새로고침)
  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([WardService.getSummary(force: force), WardService.getSensors(force: force)]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as WardSummary;
        _sensor = results[1] as WardSensor;
        _loading = false;
      });
    } catch (e) {
      debugPrint('홈 데이터 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '정보를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: const AppHeader(), body: _buildBody());
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
    // 성공 — 데이터 표시 (아래로 당기면 새로고침)
    final s = _summary!;
    final sensor = _sensor!;
    // 기기가 오프라인이면 지금 상태는 '마지막 수신값'이라 현재 상태가 아님(stale)
    final isOffline = !s.deviceOnline;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('현재 안전 상태 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('실시간으로 확인하는 어르신의 안전 상태입니다', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          // 오프라인이면 상태가 신뢰할 수 없다는 안내 배너
          if (isOffline) ...[_offlineBanner(), const SizedBox(height: 12)],
          // 오프라인이면 흐리게(반투명) 처리 — 현재 상태가 아님을 시각적으로 표현
          Opacity(
            opacity: isOffline ? 0.5 : 1.0,
            child: Column(
              children: [
                _statusCard(s),
                const SizedBox(height: 16),
                EmergencyCallCard(onCall: () => _callPhone('119')),
                const SizedBox(height: 16),
                _sensorCard(sensor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 기기 미연결 안내 배너
  Widget _offlineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text('기기 미연결 — 아래는 마지막으로 수신된 상태입니다.', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 상태 카드 (색상 + 이름/관계 + 전화 걸기 버튼)
  Widget _statusCard(WardSummary s) {
    final st = StatusStyle.of(s.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: st.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: st.color,
                child: Icon(st.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      st.label,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: st.color),
                    ),
                    const SizedBox(height: 2),
                    Text('${s.relationship} (${s.wardName})', style: const TextStyle(color: AppColors.textPrimary)),
                    if (s.deviceLastSeen != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '마지막 업데이트: ${_lastSeen(s.deviceLastSeen)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _callPhone(s.phone),
              icon: const Icon(Icons.call),
              label: const Text('전화 걸기'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: st.color,
                side: BorderSide(color: st.color.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lastSeen(String? raw) {
    if (raw == null) return '수신 없음';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : mdHm(d);
  }

  String _signal(int? rssi) {
    if (rssi == null) return '-';
    if (rssi >= -60) return '강함';
    if (rssi >= -75) return '보통';
    return '약함';
  }

  // 낙상 감지 센서 카드
  Widget _sensorCard(WardSensor sensor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('낙상 감지 센서', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                _connBadge(sensor.deviceOnline),
              ],
            ),
            const SizedBox(height: 16),
            // 배터리·신호·위치 — 백엔드 미제공이라 '-'(비활성)로 표시. 제공 시 실제값으로 교체.
            Row(
              children: [
                Expanded(child: _stat('배터리', sensor.batteryPct != null ? '${sensor.batteryPct}%' : '-')),
                Expanded(child: _stat('신호', _signal(sensor.rssi))),
                Expanded(child: _stat('최근 수신', _lastSeen(sensor.deviceLastSeen))),
              ],
            ),
            const Divider(height: 24),
            // 실제 센서 상태 (null=미확인 / true=정상 / false=이상)
            _sensorRow('진동 센서', sensor.vibrator),
            _sensorRow('레이더 센서', sensor.radar),
            _sensorRow('열화상 센서', sensor.thermal),
          ],
        ),
      ),
    );
  }

  // 기기 연결 배지
  Widget _connBadge(bool online) {
    final c = online ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.shade50, borderRadius: BorderRadius.circular(8)),
      child: Text(online ? '연결됨' : '연결 안 됨', style: TextStyle(fontSize: 12, color: c.shade700)),
    );
  }

  // 통계 자리 (배터리/신호/위치)
  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _sensorRow(String label, bool? state) {
    // null: 미확인(회색), true: 정상(초록), false: 이상(빨강)
    final (IconData icon, Color color, String text) = switch (state) {
      true => (Icons.check_circle, Colors.green, '정상'),
      false => (Icons.cancel, Colors.red, '이상'),
      null => (Icons.help_outline, Colors.grey, '미확인'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // 전화 걸기 — 전화 앱을 연다.
  Future<void> _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phoneDigits(phone));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('전화를 걸 수 없습니다.')));
    }
  }
}
