import '../../models/notification_model.dart';
import '../../models/notification_preference_model.dart';
import '../../models/payment_schedule_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ Lịch thanh toán & Nhắc nợ (PaymentScheduleRepository)
abstract class PaymentScheduleRepository {
  /// Truy xuất toàn bộ danh sách các kỳ phân kỳ thanh toán của người dùng,
  /// sắp xếp tăng dần theo ngày đến hạn (due_date).
  Future<List<PaymentScheduleModel>> getPaymentSchedules({
    int? userId,
    int? loanId,
  });

  /// Lấy thông tin chi tiết của một kỳ thanh toán cụ thể theo [scheduleId].
  /// Ném ngoại lệ phân quyền (EX-02) nếu kỳ thanh toán không thuộc tài khoản của người dùng.
  Future<PaymentScheduleModel?> getScheduleDetail(
    int scheduleId, {
    int? userId,
  });

  /// Ghi nhận hoàn tất nghĩa vụ thanh toán cho kỳ [scheduleId].
  Future<PaymentScheduleModel> markScheduleAsPaid(
    int scheduleId, {
    int? userId,
  });

  /// Truy xuất hồ sơ thiết lập kênh nhắc nợ và số ngày nhắc trước hạn của người dùng.
  Future<NotificationPreferenceModel> getNotificationPreference({int? userId});

  /// Cập nhật cấu hình NotificationPreference (Bật/tắt Push, Email, SMS, số ngày nhắc trước).
  /// Kiểm tra hợp lệ (EX-04): Ném lỗi nếu bật kênh Email/SMS nhưng thiếu thông tin liên hệ trong hồ sơ.
  Future<NotificationPreferenceModel> updateNotificationPreference(
    NotificationPreferenceModel preference, {
    String? userEmail,
    String? userPhone,
  });

  /// Truy xuất danh sách thông báo nhắc nợ (Notification) thuộc quyền sở hữu của người dùng hiện tại.
  Future<List<NotificationModel>> getNotifications({int? userId});

  /// Đồng bộ và làm mới các thông báo nhắc nợ khi lịch phân kỳ có sự biến động (Mục 10).
  /// Tự động vô hiệu hóa các thông báo PENDING cũ gắn với lịch cũ và tái lập lịch mới.
  Future<int> syncSchedulesAndNotifications({int? userId});
}
