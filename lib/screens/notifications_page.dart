import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/ward_service.dart';
import '../utils/date_format.dart';

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
      final data = await WardService.getNotifications(page: _pageNum);
      if (!mounted) return;
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
        actions: [
          TextButton(onPressed: _readAll, child: const Text('전체 읽음')),
        ],
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
        itemBuilder: (_, i) =>
            i < items.length ? _card(items[i]) : _pagination(),
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: d.page > 0 ? () => _goPage(d.page - 1) : null,
          ),
          Text('${d.page + 1} / ${d.totalPages}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: !d.last ? () => _goPage(d.page + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _card(AppNotification n) {
    final (color, label) = _badge(n.notificationType);
    return Card(
      // 미읽음은 옅은 색 배경으로 구분
      color: n.isRead ? null : color.withValues(alpha: 0.08),
      child: ListTile(
        onTap: () => _tap(n),
        leading: Icon(Icons.circle, size: 14, color: color),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text('${n.memberName} · ${_time(n.createdAt)}'),
        trailing: n.isRead
            ? null
            : const Icon(Icons.circle, size: 8, color: Colors.red),
      ),
    );
  }

  // notificationType → (색상, 표시 라벨)
  (Color, String) _badge(String type) {
    switch (type) {
      case NotiTypes.fall:
        return (Colors.red, '낙상 감지');
      case NotiTypes.emergency:
        return (Colors.red, '긴급 연결');
      case NotiTypes.warning:
        return (Colors.orange, '활동 경고');
      case NotiTypes.deviceOffline:
        return (Colors.grey, '기기 연결 끊김');
      default:
        return (Colors.grey, type);
    }
  }

  String _time(String? raw) {
    if (raw == null) return '-';
    final d = DateTime.tryParse(raw);
    return d == null ? raw : mdHm(d);
  }
}
