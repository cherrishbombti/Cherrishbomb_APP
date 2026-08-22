import 'package:flutter/material.dart';
import '../models/ward_sensor.dart';
import '../services/ward_service.dart';
import '../utils/date_format.dart';
import '../widgets/device_widgets.dart';

/// 기기 관리 화면 (와이어프레임 07).
/// 온라인 상태·마지막 신호는 백엔드 getSensors 실데이터.
/// 배터리·신호·설치위치·연결이력은 백엔드 미제공 → 임시 표시(연동 예정).
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
          const Center(
            child: Text('라즈베리파이 낙상 감지 센서', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          DeviceOnlineCard(online: s.deviceOnline, lastSeen: _lastSeen(s.deviceLastSeen)),
          const SizedBox(height: 12),
          // 배터리·신호는 백엔드 미제공 → 임시 표시
          const Row(
            children: [
              Expanded(
                child: DeviceStatBox(value: '—', label: '배터리'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DeviceStatBox(value: '—', label: '신호'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const DeviceInstallCard(location: '미설정'),
          const SizedBox(height: 12),
          const DeviceHistoryCard(),
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
