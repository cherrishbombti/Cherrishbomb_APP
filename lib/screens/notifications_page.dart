import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_store.dart';
import '../services/ward_service.dart';
import '../theme/app_colors.dart';
import '../utils/date_format.dart';
import '../widgets/status_badge.dart';

/// 알림함 화면. 낙상/경고/기기 알림 목록 + 읽음 처리.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _loading = true;
  String? _error;
  NotiPage? _data;
  int _pageNum = 0; // 현재 페이지 (0부터)

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _goPage(int p) {
    _pageNum = p;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gen = NotificationStore.generation; // 조회 시작 시점의 세션 세대
      final data = await WardService.getNotifications(page: _pageNum);
      if (!mounted) return; // dispose(로그아웃 등) 뒤면 전역 상태를 건드리지 않음
      NotificationStore.set(data.unreadCount, gen: gen); // 지난 세션 응답이면 무시됨
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint('알림 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _error = '알림을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  Future<void> _readAll() async {
    try {
      await WardService.readAllNotifications();
      if (!mounted) return;
      _load();
    } catch (e) {
      debugPrint('전체 읽음 실패: $e');
    }
  }

  Future<void> _tap(AppNotification n) async {
    if (n.isRead) return;
    try {
      await WardService.readNotification(n.id);
      if (!mounted) return;
      _load();
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림함'),
        actions: [TextButton(onPressed: _readAll, child: const Text('전체 읽음'))],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    final items = _data?.content ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('알림이 없습니다.', style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + 1, // 마지막 칸은 페이지네이션
        itemBuilder: (_, i) => i < items.length ? _card(items[i]) : _pagination(),
      ),
    );
  }

  // 하단 페이지 이동 (이전 / 현재·전체 / 다음)
  Widget _pagination() {
    final d = _data;
    if (d == null || d.totalPages <= 1) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: d.page > 0 ? () => _goPage(d.page - 1) : null),
          Text('${d.page + 1} / ${d.totalPages}'),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: !d.last ? () => _goPage(d.page + 1) : null),
        ],
      ),
    );
  }

  Widget _card(AppNotification n) {
    final (color, badge, title) = _meta(n.notificationType);
    return Card(
      // 미읽음은 상태색 옅은 배경으로 구분
      color: n.isRead ? null : color.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _tap(n),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(label: badge, color: color),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${n.memberName} · ${_time(n.createdAt)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // notificationType → (상태색, 배지 라벨, 한국어 제목)
  // 배지는 SAFE/WARNING/DANGER 축, 기기 문제(DEVICE_OFFLINE)는 회색 "기기".
  (Color, String, String) _meta(String type) {
    switch (type) {
      case NotiTypes.fall:
        return (AppColors.danger, 'DANGER', '낙상 감지');
      case NotiTypes.emergency:
        return (AppColors.danger, 'DANGER', '긴급 연결');
      case NotiTypes.warning:
        return (AppColors.warning, 'WARNING', '활동 경고');
      case NotiTypes.deviceOffline:
        return (AppColors.device, '기기', '기기 연결 끊김');
      default:
        return (AppColors.device, type, type);
    }
  }

  String _time(DateTime? d) => d == null ? '-' : mdHm(d);
}
