import 'package:flutter/material.dart';
import '../utils/date_format.dart';

/// 활동 로그 상단 날짜 필터 바 (시작일 ~ 종료일 + 조회).
class LogFilterBar extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSearch;

  const LogFilterBar({
    super.key,
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(child: _dateField('시작일', from, onPickFrom)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('~'),
          ),
          Expanded(child: _dateField('종료일', to, onPickTo)),
          const SizedBox(width: 8),
          FilledButton(onPressed: onSearch, child: const Text('조회')),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(value == null ? label : ymd(value)),
    );
  }
}
