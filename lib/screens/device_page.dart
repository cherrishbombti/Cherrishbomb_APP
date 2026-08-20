import 'package:flutter/material.dart';
import '../models/ward_sensor.dart';
import '../services/ward_service.dart';
import '../utils/date_format.dart';

/// 기기 관리 화면. 낙상 감지 센서(라즈베리파이) 연결·센서 상태를 표시.
/// 표시 항목은 백엔드 getSensors 응답 기준.
/// (배터리·신호·연결이력은 백엔드 미제공이라 이번 범위 제외)
class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool _loading = true;
  String? _error;
  WardSensor? _sensor;

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
      final s = await WardService.getSensors();
      if (!mounted) return;
      setState(() {
        _sensor = s;
        _loading = false;
      });
    } catch (e) {
      debugPrint('기기 상태 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '기기 상태를 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 관리')),
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
    final s = _sensor!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _onlineCard(s),
          const SizedBox(height: 12),
          _sensorCard(s),
        ],
      ),
    );
  }

  // 온라인/오프라인 + 마지막 신호 시각
  Widget _onlineCard(WardSensor s) {
    final online = s.deviceOnline;
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle,
            size: 14, color: online ? Colors.green : Colors.grey),
        title: Text(online ? '온라인' : '오프라인',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('마지막 신호: ${_lastSeen(s.deviceLastSeen)}'),
      ),
    );
  }

  // 센서 3종 상태
  Widget _sensorCard(WardSensor s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('센서 상태',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _sensorRow('진동 센서', s.vibrator),
            _sensorRow('레이더 센서', s.radar),
            _sensorRow('열화상 센서', s.thermal),
          ],
        ),
      ),
    );
  }

  Widget _sensorRow(String name, bool? ok) {
    // null=미확인 / true=정상 / false=이상
    final (color, label) = ok == null
        ? (Colors.grey, '미확인')
        : ok
            ? (Colors.green, '정상')
            : (Colors.red, '이상');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  String _lastSeen(String? raw) {
    if (raw == null) return '수신 없음';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : mdHm(d);
  }
}
