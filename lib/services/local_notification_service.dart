import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/loan_model.dart';
import '../models/notification_model.dart';
import '../models/notification_preference_model.dart';
import '../models/payment_schedule_model.dart';

/// Dịch vụ xin quyền, hiển thị thông báo hệ thống và điều hướng khi người dùng nhấn vào thông báo
class LocalNotificationService {
  static const MethodChannel _channel = MethodChannel(
    'fincredit/notifications',
  );

  static bool _permissionRequestedThisSession = false;
  static bool _handlerInitialized = false;
  static final Set<String> _notifiedKeysThisSession = <String>{};
  static void Function(int tabIndex, int? scheduleId)? _tapHandler;

  static String _formatCurrency(num amount) {
    final str = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  /// Đăng ký callback xử lý khi người dùng bấm vào thông báo trên thanh trạng thái điện thoại
  static void setTapHandler(
    void Function(int tabIndex, int? scheduleId)? handler,
  ) {
    _tapHandler = handler;
    if (!_handlerInitialized) {
      _handlerInitialized = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onNotificationTap' && call.arguments is Map) {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          final tabIndex = (args['tabIndex'] as num?)?.toInt() ?? 2;
          final scheduleId = (args['scheduleId'] as num?)?.toInt();
          _tapHandler?.call(tabIndex, scheduleId);
        }
      });
    }
  }

  /// Kiểm tra nếu app được mở từ thao tác bấm vào thông báo (cold start)
  static Future<void> checkInitialLaunch() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final res = await _channel.invokeMethod<dynamic>(
        'getInitialNotificationLaunch',
      );
      if (res is Map) {
        final args = Map<String, dynamic>.from(res);
        final tabIndex = (args['tabIndex'] as num?)?.toInt() ?? 2;
        final scheduleId = (args['scheduleId'] as num?)?.toInt();
        _tapHandler?.call(tabIndex, scheduleId);
      }
    } catch (_) {}
  }

  /// Xin quyền POST_NOTIFICATIONS trên Android 13+ (chỉ hỏi 1 lần mỗi phiên mở app)
  static Future<bool> requestPermissionOnce() async {
    if (_permissionRequestedThisSession) return true;
    _permissionRequestedThisSession = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Đẩy 1 thông báo lên thanh trạng thái / màn hình khóa điện thoại (chống trùng lặp qua dedupeKey)
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? dedupeKey,
    int? scheduleId,
    int tabIndex = 2,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('showNotification', {
        'id': id,
        'title': title,
        'body': body,
        'dedupeKey': ?dedupeKey,
        'scheduleId': ?scheduleId,
        'tabIndex': tabIndex,
      });
    } catch (_) {
      // Bỏ qua an toàn trên môi trường test hoặc thiết bị không hỗ trợ
    }
  }

  /// Tự động đẩy 1 thông báo nhắc nợ/quá hạn hoặc sắp đến hạn ra ngoài điện thoại
  /// (tôn trọng cấu hình pushEnabled & reminderDays của người dùng, chống trùng qua SharedPreferences)
  static Future<void> notifyOverdueOrUrgent({
    required List<NotificationModel> notifications,
    required List<PaymentScheduleModel> schedules,
    List<LoanModel> loans = const [],
    NotificationPreferenceModel? preference,
  }) async {
    if (preference != null && !preference.pushEnabled) {
      return;
    }

    final overdueSchedule = schedules
        .where((s) => s.status.toUpperCase() == 'OVERDUE')
        .firstOrNull;
    if (overdueSchedule != null) {
      final key = 'overdue_sched_${overdueSchedule.id}';
      if (_notifiedKeysThisSession.add(key)) {
        final loanName = loans
            .where((l) => l.id == overdueSchedule.loanId)
            .map((l) => l.loanName)
            .firstOrNull;
        final loanSuffix = loanName != null ? ' • $loanName' : '';
        await showLocalNotification(
          id: 10000 + overdueSchedule.id,
          title: 'Cảnh báo kỳ thanh toán quá hạn',
          body:
              'Kỳ ${overdueSchedule.installmentNumber}$loanSuffix (${_formatCurrency(overdueSchedule.totalAmount)}) đã quá hạn ngày ${_formatDate(overdueSchedule.dueDate)}. Vui lòng thanh toán sớm để bảo vệ điểm tín dụng.',
          dedupeKey: key,
          scheduleId: overdueSchedule.id,
          tabIndex: 2,
        );
      }
      return;
    }

    final reminderDays = preference?.reminderDays ?? 3;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingSchedule = schedules.where((s) {
      final st = s.status.toUpperCase();
      if (st == 'PAID' || st == 'OVERDUE') return false;
      final due = DateTime(s.dueDate.year, s.dueDate.month, s.dueDate.day);
      final diffDays = due.difference(today).inDays;
      return diffDays >= 0 && diffDays <= reminderDays;
    }).firstOrNull;

    if (upcomingSchedule != null) {
      final key = 'upcoming_sched_${upcomingSchedule.id}_d$reminderDays';
      if (_notifiedKeysThisSession.add(key)) {
        final loanName = loans
            .where((l) => l.id == upcomingSchedule.loanId)
            .map((l) => l.loanName)
            .firstOrNull;
        final loanSuffix = loanName != null ? ' • $loanName' : '';
        await showLocalNotification(
          id: 15000 + upcomingSchedule.id,
          title: 'Nhắc lịch thanh toán sắp đến hạn',
          body:
              'Kỳ ${upcomingSchedule.installmentNumber}$loanSuffix (${_formatCurrency(upcomingSchedule.totalAmount)}) sẽ đến hạn vào ngày ${_formatDate(upcomingSchedule.dueDate)}.',
          dedupeKey: key,
          scheduleId: upcomingSchedule.id,
          tabIndex: 2,
        );
      }
      return;
    }

    final overdueNotif = notifications
        .where((n) => n.type.toUpperCase() == 'OVERDUE_ALERT')
        .firstOrNull;
    if (overdueNotif != null) {
      final key = overdueNotif.scheduleId != null
          ? 'overdue_sched_${overdueNotif.scheduleId}'
          : 'overdue_notif_${overdueNotif.id}';
      if (_notifiedKeysThisSession.add(key)) {
        await showLocalNotification(
          id: 20000 + overdueNotif.id,
          title: overdueNotif.title,
          body: overdueNotif.message,
          dedupeKey: key,
          scheduleId: overdueNotif.scheduleId,
          tabIndex: 2,
        );
      }
    }
  }
}
