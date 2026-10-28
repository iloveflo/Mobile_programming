import '../models/notification_model.dart';

/// Cơ sở dữ liệu mẫu cho Thông báo & Lịch nhắc nợ (Notification Database)
class NotificationMockData {
  static final List<NotificationModel> notificationsDatabase = [
    NotificationModel(
      id: 1,
      userId: 1,
      scheduleId: 3,
      type: 'OVERDUE_ALERT',
      channel: 'PUSH',
      title: 'Cảnh báo kỳ thanh toán quá hạn',
      message:
          'Kỳ 3 khoản vay mua xe của bạn đã quá ngày đến hạn (10/10/2026). Vui lòng thanh toán sớm để bảo đảm điểm tín dụng.',
      scheduledAt: DateTime(2026, 10, 11, 8, 0),
      sentAt: DateTime(2026, 10, 11, 8, 1),
      status: 'SENT',
      createdAt: DateTime(2026, 10, 10, 23, 59),
    ),
    NotificationModel(
      id: 2,
      userId: 1,
      scheduleId: 6,
      type: 'PAYMENT_REMINDER',
      channel: 'PUSH',
      title: 'Nhắc lịch thanh toán thẻ tín dụng',
      message:
          'Kỳ 1 thẻ tín dụng VIB Super Card (3.070.000 đ) sẽ đến hạn vào ngày 05/11/2026.',
      scheduledAt: DateTime(2026, 11, 2, 8, 0),
      sentAt: null,
      status: 'PENDING',
      createdAt: DateTime(2026, 10, 25, 9, 0),
    ),
    NotificationModel(
      id: 3,
      userId: 1,
      scheduleId: 4,
      type: 'PAYMENT_REMINDER',
      channel: 'EMAIL',
      title: 'Thông báo nghĩa vụ thanh toán kỳ 4',
      message:
          'Kỳ 4 hợp đồng Vay mua xe VinFast VF8 số tiền 2.630.208 đ sẽ đến hạn vào 10/11/2026.',
      scheduledAt: DateTime(2026, 11, 7, 8, 0),
      sentAt: null,
      status: 'PENDING',
      createdAt: DateTime(2026, 10, 26, 10, 0),
    ),
    NotificationModel(
      id: 4,
      userId: 1,
      scheduleId: 2,
      type: 'PAYMENT_RECEIPT',
      channel: 'PUSH',
      title: 'Ghi nhận thanh toán thành công',
      message:
          'Bạn đã hoàn tất thanh toán kỳ 2 hợp đồng Vay mua xe số tiền 2.682.291 đ.',
      scheduledAt: DateTime(2026, 9, 10, 10, 0),
      sentAt: DateTime(2026, 9, 10, 10, 2),
      status: 'SENT',
      createdAt: DateTime(2026, 9, 10, 10, 0),
    ),
    NotificationModel(
      id: 5,
      userId: 1,
      scheduleId: 3,
      type: 'OVERDUE_ALERT',
      channel: 'SMS',
      title: 'Nhắc nợ khẩn cấp qua SMS',
      message:
          'Tin nhắn gửi qua SMS không thành công do sự cố mạng viễn thông.',
      scheduledAt: DateTime(2026, 10, 11, 8, 0),
      sentAt: null,
      status: 'FAILED',
      createdAt: DateTime(2026, 10, 11, 8, 0),
    ),
  ];
}
