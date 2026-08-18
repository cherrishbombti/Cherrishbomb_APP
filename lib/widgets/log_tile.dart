import 'package:flutter/material.dart';
import '../models/log_entry.dart';

/// 활동 로그 한 건을 카드로 표시.
/// 색상·라벨은 백엔드 logType + status 기준. (와이어프레임 아님)
class LogTile extends StatelessWidget {
  final LogEntry log;
  const LogTile(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _badge(log);
    final hasSensor = log.sensorDetail != null && log.sensorDetail!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 14),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text([
          _dateTime(log.detectedAt),
          if (hasSensor) '센서: ${log.sensorDetail}',
        ].join('\n')),
        trailing:
            Text(log.status, style: TextStyle(color: color, fontSize: 12)),
        isThreeLine: hasSensor,
      ),
    );
  }

  // logType → (색상, 표시 라벨). status로 심각도 색을 구분.
  (Color, String) _badge(LogEntry log) {
    switch (log.logType) {
      case 'FALL_EVENT':
        return (_statusColor(log.status), '낙상 감지');
      case 'SENSOR_FAILURE':
        return (Colors.orange, '센서 장애');
      case 'EMERGENCY_CALL':
        return (Colors.red, '119 연결');
      default:
        return (Colors.grey, log.logType);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'DANGER':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _dateTime(DateTime? d) => d == null
      ? '-'
      : '${_pad2(d.month)}-${_pad2(d.day)} ${_pad2(d.hour)}:${_pad2(d.minute)}';

  String _pad2(int n) => n.toString().padLeft(2, '0');
}
