import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 상태(SAFE/WARNING/DANGER) → 색·배경·라벨·아이콘 매핑.
class StatusStyle {
  final Color color;
  final Color bg;
  final String label;
  final IconData icon;
  const StatusStyle(this.color, this.bg, this.label, this.icon);

  static StatusStyle of(String status) {
    switch (status) {
      case 'DANGER':
        return const StatusStyle(AppColors.danger, AppColors.dangerBg, '위험', Icons.warning_rounded);
      case 'WARNING':
        return const StatusStyle(AppColors.warning, AppColors.warningBg, '주의', Icons.error_outline);
      default:
        return const StatusStyle(AppColors.safe, AppColors.safeBg, '안전', Icons.check_circle);
    }
  }
}

/// 119 긴급 연결 카드 (빨강).
class EmergencyCallCard extends StatelessWidget {
  final VoidCallback onCall;
  const EmergencyCallCard({super.key, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '119 긴급 연결',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
                SizedBox(height: 4),
                Text('버튼 클릭 이력이 기록됩니다', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call, size: 18),
            label: const Text('전화 걸기'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
