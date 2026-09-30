import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'ward_service.dart';

/// FCM 푸시 알림 담당.
/// - 권한 요청 / FCM 토큰 발급 / 백엔드 등록
/// - 앱이 켜져 있을 때(foreground) 온 알림을 화면에 직접 표시
/// - 토큰 갱신 시 재등록
///
/// 백그라운드(앱 종료·최소화) 상태의 표시는 OS가 처리하므로 여기서 안 다룬다.
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  // 안드로이드 foreground 알림용 채널. (iOS는 채널 개념이 없어 무시됨)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cherrishbomb_alerts',
    '낙상·긴급 알림',
    description: '낙상 감지 및 긴급 상황 알림',
    importance: Importance.high,
  );

  static bool _inited = false;

  /// 앱 시작 시 한 번 호출. 권한·로컬알림·리스너를 세팅한다.
  /// (로그인 여부와 무관하게 호출해도 안전. 토큰 등록은 로그인 후 registerToken 에서)
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // 1) 알림 권한 요청 (iOS 필수, Android 13+ 도 필요)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2) 로컬 알림 플러그인 초기화 (foreground 표시용)
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3) iOS: 앱이 켜져 있을 때도 배너가 뜨도록
    await _fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // 4) foreground 수신 → 로컬 알림으로 직접 표시
    FirebaseMessaging.onMessage.listen(_showForeground);

    // 5) 토큰 갱신 시 백엔드에 재등록
    _fcm.onTokenRefresh.listen((token) {
      WardService.registerFcmToken(token).catchError((_) {});
    });
  }

  /// 로그인 후 호출. 현재 FCM 토큰을 백엔드에 등록한다.
  static Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await WardService.registerFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM 토큰 등록 실패: $e');
    }
  }

  /// 로그아웃 시 호출. 백엔드에서 이 기기 토큰을 제거하고 로컬 토큰도 폐기한다.
  static Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await WardService.deleteFcmToken(token);
      }
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('FCM 토큰 해제 실패: $e');
    }
  }

  static Future<void> _showForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return; // data-only 메시지는 표시 안 함
    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
