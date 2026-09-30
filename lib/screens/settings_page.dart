import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import 'contacts_page.dart';
import 'health_page.dart';
import 'organization_page.dart';

/// 설정 화면. 비상 연락망 등 설정 항목으로 이동.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('비상 연락망'),
            subtitle: const Text('연락처 조회 · 추가'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('건강 정보 관리'),
            subtitle: const Text('기저질환 · 복용약 · 병력'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.apartment),
            title: const Text('기관 연동'),
            subtitle: const Text('사회복지사 기관과 연동'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationPage()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('로그아웃', style: TextStyle(color: AppColors.danger)),
            onTap: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              context.go('/login'); // 스택 갈아끼움
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_remove_outlined, color: AppColors.textSecondary),
            title: const Text('회원탈퇴', style: TextStyle(color: AppColors.textSecondary)),
            subtitle: const Text('계정과 모든 데이터 영구 삭제'),
            onTap: () => _withdraw(context),
          ),
        ],
      ),
    );
  }

  /// 회원탈퇴: 되돌릴 수 없음을 확인받은 뒤 서버 삭제 → 로그인 화면으로.
  Future<void> _withdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text(
          '계정과 모든 데이터(피보호자·연락처·건강정보·알림)가 영구 삭제됩니다.\n'
          '되돌릴 수 없습니다. 탈퇴하시겠습니까?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AuthService.withdraw();
      if (!context.mounted) return;
      context.go('/login');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }
}
