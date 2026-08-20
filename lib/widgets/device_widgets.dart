import 'package:flutter/material.dart';

/// 온라인 상태 카드 (초록 점 + 온라인/오프라인 + 마지막 신호).
class DeviceOnlineCard extends StatelessWidget {
  final bool online;
  final String lastSeen;
  const DeviceOnlineCard({super.key, required this.online, required this.lastSeen});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    size: 12, color: online ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(online ? '온라인' : '오프라인',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('마지막 신호: $lastSeen',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// 통계 박스 (배터리·신호 등). 큰 값 + 라벨.
class DeviceStatBox extends StatelessWidget {
  final String value;
  final String label;
  const DeviceStatBox({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// 설치 위치 카드. (백엔드 미제공 → 임시 표시)
class DeviceInstallCard extends StatelessWidget {
  final String location;
  const DeviceInstallCard({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('설치 위치',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(location, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// 기기 연결 이력 카드. (백엔드 미제공 → 연동 예정 안내)
class DeviceHistoryCard extends StatelessWidget {
  const DeviceHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기기 연결 이력',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('연결 이력은 추후 제공 예정입니다.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
