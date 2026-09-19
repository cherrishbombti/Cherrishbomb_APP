import 'package:flutter/material.dart';

import '../models/ward_sensor.dart';
import '../services/ward_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/device_widgets.dart';
import '../widgets/app_header.dart';

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

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await WardService.getSensors(force: force);
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
    final s = _sensor!;
    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('기기 관리', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const Center(
            child: Text('라즈베리파이 낙상 감지 센서', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 12),
          DeviceOnlineCard(online: s.deviceOnline, lastSeen: _lastSeen(s.deviceLastSeen)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DeviceStatBox(value: s.batteryPct != null ? '${s.batteryPct}%' : '—', label: '배터리'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DeviceStatBox(value: _signal(s.rssi), label: '신호'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DeviceSensorCard(vibrator: s.vibrator, radar: s.radar, thermal: s.thermal),
        ],
      ),
    );
  }

  String _lastSeen(String? raw) {
    if (raw == null) return '수신 없음';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : mdHm(d);
  }

  // rssi(dBm) → 강함/보통/약함
  String _signal(int? rssi) {
    if (rssi == null) return '—';
    if (rssi >= -60) return '강함';
    if (rssi >= -75) return '보통';
    return '약함';
  }
}
