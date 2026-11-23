import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/config/app_env.dart';
import '../core/network/api_client.dart';
import 'local_notification_service.dart';

/// Top-level handler bắt buộc cho FCM khi app đang ở chế độ nền hoặc bị tắt hoàn toàn
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

/// Dịch vụ quản lý Firebase Cloud Messaging (FCM) để nhận thông báo đẩy ngay cả khi app đã tắt
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _firebaseReady = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  void Function(int tabIndex, int? scheduleId)? onNotificationTap;

  bool get isFirebaseReady => _firebaseReady;
  String? get currentToken => _currentToken;

  /// Trích xuất tabIndex & scheduleId từ FCM data payload (chuỗi -> số)
  static ({int tabIndex, int? scheduleId}) parsePushPayload(
    Map<String, dynamic> data,
  ) {
    final rawTab = data['tabIndex'] ?? data['tab_index'];
    final tabIndex = int.tryParse(rawTab?.toString() ?? '') ?? 2;
    final rawSchedule = data['scheduleId'] ?? data['schedule_id'];
    final parsedSchedule = int.tryParse(rawSchedule?.toString() ?? '');
    return (
      tabIndex: tabIndex,
      scheduleId: (parsedSchedule != null && parsedSchedule > 0)
          ? parsedSchedule
          : null,
    );
  }

  /// Khởi tạo Firebase & đăng ký background handler (an toàn nếu chưa có google-services.json)
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseReady = true;

      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        final title =
            message.notification?.title ??
            message.data['title']?.toString() ??
            'FinCredit';
        final body =
            message.notification?.body ??
            message.data['body']?.toString() ??
            '';
        final parsed = parsePushPayload(message.data);
        final notifId =
            int.tryParse(message.data['notificationId']?.toString() ?? '') ??
            DateTime.now().millisecondsSinceEpoch.remainder(100000);

        LocalNotificationService.showLocalNotification(
          id: notifId,
          title: title,
          body: body,
          dedupeKey: message.messageId != null
              ? 'fcm_${message.messageId}'
              : null,
          tabIndex: parsed.tabIndex,
          scheduleId: parsed.scheduleId,
        );
      });

      _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final parsed = parsePushPayload(message.data);
        onNotificationTap?.call(parsed.tabIndex, parsed.scheduleId);
      });
    } catch (e) {
      _firebaseReady = false;
      debugPrint('[FCM INIT SKIPPED] $e');
    }
  }

  /// Kiểm tra nếu app được mở từ trạng thái đã tắt hoàn toàn bằng cách nhấn vào thông báo FCM
  Future<void> checkInitialMessage() async {
    if (!_firebaseReady || kIsWeb) return;
    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        final parsed = parsePushPayload(initialMessage.data);
        onNotificationTap?.call(parsed.tabIndex, parsed.scheduleId);
      }
    } catch (_) {}
  }

  /// Lấy FCM token và đồng bộ lên Backend (`POST /api/user/fcm-token`)
  Future<void> registerDeviceToken(ApiClient client) async {
    if (!_firebaseReady || AppEnv.useMock || kIsWeb) return;
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _sendTokenToBackend(client, token);
      }

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) {
        if (newToken.isNotEmpty) {
          _sendTokenToBackend(client, newToken);
        }
      });
    } catch (e) {
      debugPrint('[FCM REGISTER ERROR] $e');
    }
  }

  Future<void> _sendTokenToBackend(ApiClient client, String token) async {
    if (client.authToken == null || client.authToken!.isEmpty) return;
    _currentToken = token;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    try {
      await client.post(
        '/api/user/fcm-token',
        body: {'fcm_token': token, 'platform': platform},
      );
    } catch (e) {
      debugPrint('[FCM SYNC ERROR] $e');
    }
  }

  /// Hủy đăng ký FCM token trên thiết bị khi đăng xuất để tránh nhận nhầm thông báo
  Future<void> unregisterDeviceToken(ApiClient client) async {
    final token = _currentToken;
    _currentToken = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (token == null ||
        token.isEmpty ||
        AppEnv.useMock ||
        client.authToken == null ||
        client.authToken!.isEmpty) {
      return;
    }
    try {
      await client.delete('/api/user/fcm-token', body: {'fcm_token': token});
    } catch (_) {}
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
  }
}
