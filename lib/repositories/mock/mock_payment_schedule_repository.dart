import '../../mock_data/loan_mock_data.dart';
import '../../mock_data/notification_mock_data.dart';
import '../../mock_data/notification_preference_mock_data.dart';
import '../../mock_data/payment_schedule_mock_data.dart';
import '../../models/notification_model.dart';
import '../../models/notification_preference_model.dart';
import '../../models/payment_schedule_model.dart';
import '../interfaces/payment_schedule_repository.dart';

/// Triển khai Mock In-Memory cho PaymentScheduleRepository
class MockPaymentScheduleRepository implements PaymentScheduleRepository {
  /// Cờ giả lập ngoại lệ EX-02: Không có quyền truy cập kỳ thanh toán của tài khoản khác (403 Forbidden)
  bool shouldSimulateUnauthorized = false;

  /// Cờ giả lập ngoại lệ EX-06: Sự cố kết nối hoặc lỗi cơ sở dữ liệu
  bool shouldSimulateDatabaseError = false;

  /// Cờ giả lập ngoại lệ EX-05: Gửi thông báo thất bại
  bool shouldSimulateSendFailure = false;

  @override
  Future<List<PaymentScheduleModel>> getPaymentSchedules({
    int? userId,
    int? loanId,
  }) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Dữ liệu lịch thanh toán không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố kết nối cơ sở dữ liệu khi truy vấn lịch phân kỳ.');
    }

    final targetUserId = userId ?? 1;

    // Lấy danh sách ID các khoản vay thuộc quyền sở hữu của người dùng (Mục 5.1 Bước 4)
    final userLoanIds = LoanMockData.loansDatabase
        .where((l) => l.userId == targetUserId)
        .map((l) => l.id)
        .toSet();

    // Lọc theo loanId cụ thể hoặc toàn bộ các khoản vay của người dùng
    var schedules = PaymentScheduleMockData.paymentSchedulesDatabase.where((s) {
      if (!userLoanIds.contains(s.loanId)) return false;
      if (loanId != null && s.loanId != loanId) return false;
      return true;
    }).toList();

    // Tự động phân loại kỳ quá hạn nếu chưa thanh toán và ngày đến hạn đã qua (Mục 7.1)
    final now = DateTime.now();
    schedules = schedules.map((s) {
      if (s.status == 'PENDING' && s.dueDate.isBefore(now)) {
        return s.copyWith(status: 'OVERDUE');
      }
      return s;
    }).toList();

    // Sắp xếp thứ tự tăng dần của ngày đến hạn (due_date) theo Mục 5.1 Bước 6
    schedules.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return schedules;
  }

  @override
  Future<PaymentScheduleModel?> getScheduleDetail(
    int scheduleId, {
    int? userId,
  }) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Kỳ thanh toán không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Sự cố cơ sở dữ liệu khi truy xuất chi tiết kỳ thanh toán.',
      );
    }

    final targetUserId = userId ?? 1;

    final schedule = PaymentScheduleMockData.paymentSchedulesDatabase
        .cast<PaymentScheduleModel?>()
        .firstWhere((s) => s?.id == scheduleId, orElse: () => null);

    if (schedule == null) return null;

    // Kiểm tra phân quyền sở hữu đối với khoản vay tương ứng (EX-02)
    final loan = LoanMockData.loansDatabase.cast<dynamic>().firstWhere(
      (l) => l.id == schedule.loanId,
      orElse: () => null,
    );

    if (loan == null || loan.userId != targetUserId) {
      throw Exception(
        'Kỳ thanh toán không thuộc quyền truy cập của người dùng.',
      );
    }

    return schedule;
  }

  @override
  Future<PaymentScheduleModel> markScheduleAsPaid(
    int scheduleId, {
    int? userId,
  }) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Kỳ thanh toán không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi ghi nhận thanh toán kỳ.');
    }

    final index = PaymentScheduleMockData.paymentSchedulesDatabase.indexWhere(
      (s) => s.id == scheduleId,
    );

    if (index < 0) {
      throw Exception('Không tìm thấy kỳ thanh toán trong hệ thống.');
    }

    final old = PaymentScheduleMockData.paymentSchedulesDatabase[index];
    final updated = old.copyWith(status: 'PAID', remainingBalance: 0.0);
    PaymentScheduleMockData.paymentSchedulesDatabase[index] = updated;

    // Tự động hủy các thông báo nhắc nợ PENDING liên kết với kỳ này (Mục 7.1: Đã hoàn thành)
    for (
      int i = 0;
      i < NotificationMockData.notificationsDatabase.length;
      i++
    ) {
      final notif = NotificationMockData.notificationsDatabase[i];
      if (notif.scheduleId == scheduleId && notif.status == 'PENDING') {
        NotificationMockData.notificationsDatabase[i] = notif.copyWith(
          status: 'CANCELLED',
        );
      }
    }

    return updated;
  }

  @override
  Future<NotificationPreferenceModel> getNotificationPreference({
    int? userId,
  }) async {
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi tải thiết lập thông báo.');
    }

    final targetUserId = userId ?? 1;
    final match = NotificationPreferenceMockData.notificationPreferencesDatabase
        .cast<NotificationPreferenceModel?>()
        .firstWhere((p) => p?.userId == targetUserId, orElse: () => null);

    if (match != null) return match;

    // Thiết lập mặc định theo đặc tả: push=true, email=true, sms=false, reminder_days=3
    return NotificationPreferenceModel(
      id: 1,
      userId: targetUserId,
      pushEnabled: true,
      emailEnabled: true,
      smsEnabled: false,
      balanceFluctuationEnabled: true,
      monthlyStatementEnabled: true,
      reminderDays: 3,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<NotificationPreferenceModel> updateNotificationPreference(
    NotificationPreferenceModel preference, {
    String? userEmail,
    String? userPhone,
  }) async {
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi cập nhật thiết lập thông báo.');
    }

    // EX-04: Thiếu thông tin gửi Email hoặc SMS khi kênh đó được bật
    if (preference.emailEnabled &&
        (userEmail == null || userEmail.trim().isEmpty)) {
      throw Exception(
        'Thiếu thông tin địa chỉ email trong hồ sơ cá nhân khi bật kênh thông báo qua Email.',
      );
    }

    if (preference.smsEnabled &&
        (userPhone == null || userPhone.trim().isEmpty)) {
      throw Exception(
        'Thiếu thông tin số điện thoại trong hồ sơ cá nhân khi bật kênh thông báo qua tin nhắn SMS.',
      );
    }

    final index = NotificationPreferenceMockData.notificationPreferencesDatabase
        .indexWhere((p) => p.userId == preference.userId);

    final updated = preference.copyWith(updatedAt: DateTime.now());

    if (index >= 0) {
      NotificationPreferenceMockData.notificationPreferencesDatabase[index] =
          updated;
    } else {
      NotificationPreferenceMockData.notificationPreferencesDatabase.add(
        updated,
      );
    }

    return updated;
  }

  @override
  Future<List<NotificationModel>> getNotifications({int? userId}) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Dữ liệu thông báo không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi truy vấn danh sách thông báo.');
    }

    final targetUserId = userId ?? 1;

    final results = NotificationMockData.notificationsDatabase
        .where((n) => n.userId == targetUserId)
        .toList();

    // Sắp xếp thời gian mới nhất lên đầu
    results.sort((a, b) {
      final dateA = a.createdAt ?? a.scheduledAt ?? DateTime(1970);
      final dateB = b.createdAt ?? b.scheduledAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return results;
  }

  @override
  Future<int> syncSchedulesAndNotifications({int? userId}) async {
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi đồng bộ thông báo nhắc nợ.');
    }

    final targetUserId = userId ?? 1;
    final preference = await getNotificationPreference(userId: targetUserId);

    // Bước 2 & 3: Quét và hủy các thông báo PENDING cũ (Mục 10)
    int cancelledCount = 0;
    for (
      int i = 0;
      i < NotificationMockData.notificationsDatabase.length;
      i++
    ) {
      final n = NotificationMockData.notificationsDatabase[i];
      if (n.userId == targetUserId && n.status == 'PENDING') {
        NotificationMockData.notificationsDatabase[i] = n.copyWith(
          status: 'CANCELLED',
        );
        cancelledCount++;
      }
    }

    // Bước 4 & 5: Đọc các kỳ chưa thanh toán và tái lập lịch nhắc theo reminderDays
    final schedules = await getPaymentSchedules(userId: targetUserId);
    final pendingSchedules = schedules
        .where((s) => s.status != 'PAID')
        .toList();

    int nextId =
        (NotificationMockData.notificationsDatabase
            .map((n) => n.id)
            .fold<int>(0, (max, id) => id > max ? id : max)) +
        1;

    for (final schedule in pendingSchedules) {
      final scheduledAt = schedule.dueDate.subtract(
        Duration(days: preference.reminderDays),
      );

      if (preference.pushEnabled) {
        NotificationMockData.notificationsDatabase.add(
          NotificationModel(
            id: nextId++,
            userId: targetUserId,
            scheduleId: schedule.id,
            type: schedule.status == 'OVERDUE'
                ? 'OVERDUE_ALERT'
                : 'PAYMENT_REMINDER',
            channel: 'PUSH',
            title: schedule.status == 'OVERDUE'
                ? 'Cảnh báo nợ quá hạn'
                : 'Nhắc lịch thanh toán kỳ ${schedule.installmentNumber}',
            message:
                'Kỳ thanh toán số tiền ${schedule.totalAmount.round()} đ sẽ đến hạn vào ${schedule.dueDate.day}/${schedule.dueDate.month}/${schedule.dueDate.year}.',
            scheduledAt: scheduledAt,
            sentAt: null,
            status: 'PENDING',
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    return cancelledCount;
  }
}
