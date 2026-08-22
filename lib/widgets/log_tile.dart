import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../utils/date_format.dart';

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
        subtitle: Text([_dateTime(log.detectedAt), if (hasSensor) '센서: ${log.sensorDetail}'].join('\n')),
        trailing: Text(_statusLabel(log.status), style: TextStyle(color: color, fontSize: 12)),
        isThreeLine: hasSensor,
      ),
    );
  }

  // logType → (색상, 표시 라벨). status로 심각도 색을 구분.
  (Color, String) _badge(LogEntry log) {
    switch (log.logType) {
      case LogTypes.fallEvent:
        return (_statusColor(log.status), '낙상 감지');
      case LogTypes.sensorFailure:
        return (Colors.orange, '센서 장애');
      case LogTypes.emergencyCall:
        return (Colors.red, '119 연결');
      default:
        return (Colors.grey, '알 수 없는 이벤트');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case MemberStatuses.danger:
        return Colors.red;
      case MemberStatuses.warning:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // status 한글 라벨 (영문 enum 노출 방지)
  String _statusLabel(String status) {
    switch (status) {
      case MemberStatuses.danger:
        return '위험';
      case MemberStatuses.warning:
        return '경고';
      case MemberStatuses.safe:
        return '안전';
      default:
        return status;
    }
  }

  String _dateTime(DateTime? d) => d == null ? '-' : mdHm(d);
}
