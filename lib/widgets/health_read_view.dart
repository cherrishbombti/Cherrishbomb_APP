import 'package:flutter/material.dart';
import '../models/ward_health.dart';
import '../utils/date_format.dart';

/// 건강 정보 조회(읽기 전용) 뷰.
class HealthReadView extends StatelessWidget {
  final WardHealth health;
  const HealthReadView(this.health, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _row(Icons.medical_services_outlined, '기저질환', health.disease),
        _row(Icons.medication_outlined, '복용약', health.medication),
        _row(Icons.notes_outlined, '기타 병력·메모', health.memo),
        const SizedBox(height: 8),
        if (health.updatedAt != null)
          Text(
            '최종 수정: ${_fmt(health.updatedAt)}'
            '${health.updatedByName != null ? ' (${health.updatedByName})' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    final empty = value.trim().isEmpty;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(empty ? '미입력' : value, style: TextStyle(fontSize: 16, color: empty ? Colors.grey : null)),
      ),
    );
  }

  String _fmt(String? raw) {
    if (raw == null) return '-';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : ymd(d);
  }
}
