import 'package:flutter/material.dart';

/// 성별 선택 세그먼트 (남성 / 여성).
class GenderSelector extends StatelessWidget {
  final String? value; // '남성' / '여성' / null
  final ValueChanged<String> onChanged;
  const GenderSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('성별', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Row(
          children: [
            Expanded(child: _opt(context, '남성')),
            const SizedBox(width: 8),
            Expanded(child: _opt(context, '여성')),
          ],
        ),
      ],
    );
  }

  Widget _opt(BuildContext context, String g) {
    final selected = value == g;
    final primary = Theme.of(context).colorScheme.primary;
    return OutlinedButton(
      onPressed: () => onChanged(g),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? primary : Colors.black87,
        side: BorderSide(color: selected ? primary : Colors.grey.shade400),
        backgroundColor: selected ? primary.withValues(alpha: 0.08) : null,
      ),
      child: Text(g),
    );
  }
}
