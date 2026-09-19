import 'package:flutter/material.dart';
import '../screens/notifications_page.dart';
import '../services/notification_store.dart';
import '../theme/app_colors.dart';

/// 메인 탭 공통 상단 헤더. 와이어프레임의 "보호자 모드 + 벨(배지)".
/// 탭마다 동일하게 얹어 고정된 것처럼 보이게 한다.
/// 미읽음 개수는 NotificationStore(전역)에서 구독한다.
/// - 어느 탭에서 읽어도 모든 탭 배지가 동시에 갱신된다.
/// - 서버 조회는 최초 1회(ensureLoaded)뿐이라, 탭을 옮겨도 알림 API를 반복 호출하지 않는다.
class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  void initState() {
    super.initState();
    // 최초 1회만 실제 조회. 이미 로드됐으면 캐시된 값을 그대로 쓴다.
    NotificationStore.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('보호자 모드'),
      // 본문(회색)과 헤더를 구분하는 옅은 하단 경계선
      shape: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      actions: [
        IconButton(
          tooltip: '알림함',
          icon: ValueListenableBuilder<int>(
            valueListenable: NotificationStore.unread,
            builder: (_, unread, child) => Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: child),
            child: const Icon(Icons.notifications_none),
          ),
          // 알림함에서 읽고 돌아오면 배지를 최신화
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ).then((_) => NotificationStore.refresh()),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
