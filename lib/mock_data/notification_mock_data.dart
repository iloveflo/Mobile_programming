import '../models/notification_model.dart';

class NotificationMockData {
  static final List<NotificationModel> notificationsDatabase = [
    NotificationModel(
      id: 1,
      userId: 1,
      scheduleId: 2,
      type: 'PAYMENT_REMINDER',
      channel: 'PUSH',
      title: 'Nhắc lịch thanh toán',
      message: 'Khoản thanh toán kỳ 2 sẽ đến hạn vào ngày 10/03/2026.',
      scheduledAt: DateTime(2026, 3, 7, 8),
      sentAt: DateTime(2026, 3, 7, 8, 0, 5),
      status: 'SENT',
      createdAt: DateTime(2026, 3, 6, 8),
    ),
  ];
}
