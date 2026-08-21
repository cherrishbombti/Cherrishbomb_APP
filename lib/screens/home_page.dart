import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 전화 걸기
import 'notifications_page.dart';
import '../utils/phone_format.dart';
import '../models/ward_summary.dart';
import '../models/ward_sensor.dart';
import '../services/ward_service.dart';
import '../widgets/logout_button.dart';

/// 홈(보호자 모드). 피보호자 상태 요약 + 낙상 감지 센서 상태를 표시.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true; // 데이터 불러오는 중
  String? _error; // 에러 메시지 (없으면 null)
  WardSummary? _summary;
  WardSensor? _sensor;
  int _unread = 0; // 미읽음 알림 개수 (벨 배지)

  @override
  void initState() {
    super.initState();
    _load(); // 화면 뜨자마자 데이터 불러오기
    _loadUnread(); // 알림 배지 (홈 로딩과 독립)
  }

  // 미읽음 알림 개수만 별도로. 실패해도 홈 화면엔 영향 없게 무시.
  Future<void> _loadUnread() async {
    try {
      // 배지는 unreadCount만 필요 → 목록 페이로드 최소화(size:1)
      final n = await WardService.getNotifications(size: 1);
      if (mounted) setState(() => _unread = n.unreadCount);
    } catch (_) {
      // 배지는 부가 정보라 실패 시 조용히 무시
    }
  }

  // 요약 + 센서 데이터를 서버에서 불러온다. (두 요청은 독립적이라 병렬 호출)
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        WardService.getSummary(),
        WardService.getSensors(),
      ]);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('보호자 모드'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: '알림함',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ).then((_) => _loadUnread()), // 알림함 다녀오면 배지 갱신
          ),
          const LogoutButton(),
        ],
      ),
      body: _buildBody(),
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
    // 성공 — 데이터 표시 (아래로 당기면 새로고침)
    final s = _summary!;
    final sensor = _sensor!;
    // 기기가 오프라인이면 지금 상태는 '마지막 수신값'이라 현재 상태가 아님(stale)
    final isOffline = !s.deviceOnline;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '현재 안전 상태 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '실시간으로 확인하는 어르신의 안전 상태입니다',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // 오프라인이면 상태가 신뢰할 수 없다는 안내 배너
          if (isOffline) ...[
            _offlineBanner(),
            const SizedBox(height: 12),
          ],
          // 오프라인이면 흐리게(반투명) 처리 — 현재 상태가 아님을 시각적으로 표현
          Opacity(
            opacity: isOffline ? 0.5 : 1.0,
            child: Column(
              children: [
                _statusCard(s),
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
            child: Text(
              '기기 미연결 — 아래는 마지막으로 수신된 상태입니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // 상태 카드 (색상 + 이름/관계 + 전화 걸기 버튼)
  Widget _statusCard(WardSummary s) {
    final (color, label, icon) = _statusStyle(s.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${s.relationship} (${s.wardName})'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _callPhone(s.phone),
              icon: const Icon(Icons.call),
              label: const Text('전화 걸기'),
            ),
          ),
        ],
      ),
    );
  }

  (MaterialColor, String, IconData) _statusStyle(String status) {
    switch (status) {
      case 'DANGER':
        return (Colors.red, '위험', Icons.warning);
      case 'WARNING':
        return (Colors.orange, '주의', Icons.error_outline);
      case 'SAFE':
      default:
        return (Colors.green, '안전', Icons.check_circle);
    }
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
                const Text(
                  '낙상 감지 센서',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 8),
                _connBadge(sensor.deviceOnline),
              ],
            ),
            const SizedBox(height: 16),
            // 배터리·신호·위치 — 백엔드 미제공이라 '-'(비활성)로 표시. 제공 시 실제값으로 교체.
            Row(
              children: [
                Expanded(child: _stat('배터리', '-')),
                Expanded(child: _stat('신호', '-')),
                Expanded(child: _stat('위치', '-')),
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
      decoration: BoxDecoration(
        color: c.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        online ? '연결됨' : '연결 안 됨',
        style: TextStyle(fontSize: 12, color: c.shade700),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화를 걸 수 없습니다.')),
      );
    }
  }
}
