import 'package:flutter/material.dart';

/// 건강 정보 수정 폼 (입력 필드 + 저장/취소 버튼).
class HealthForm extends StatelessWidget {
  final TextEditingController disease;
  final TextEditingController medication;
  final TextEditingController memo;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const HealthForm({
    super.key,
    required this.disease,
    required this.medication,
    required this.memo,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 백엔드 제한: 질환·약 255자, 메모 2000자
        _field('기저질환', disease, hint: '예: 고혈압, 당뇨', max: 255),
        const SizedBox(height: 12),
        _field('복용약', medication, hint: '예: 메트포르민', max: 255),
        const SizedBox(height: 12),
        _field('기타 병력·메모', memo,
            hint: '예: 2024년 낙상 이력', lines: 4, max: 2000),
        const SizedBox(height: 20),
        if (saving)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: onCancel, child: const Text('취소')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: onSave, child: const Text('저장')),
              ),
            ],
          ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, int lines = 1, required int max}) {
    return TextField(
      controller: c,
      maxLines: lines,
      maxLength: max, // 초과 입력 차단 + 하단 카운터 (서버 400 방지)
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
