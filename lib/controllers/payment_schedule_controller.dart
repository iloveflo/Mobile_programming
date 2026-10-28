import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../models/notification_preference_model.dart';
import '../models/payment_schedule_model.dart';
import '../repositories/interfaces/payment_schedule_repository.dart';

/// Bộ điều khiển Quản lý Lịch thanh toán định kỳ & Nhắc nợ (PaymentScheduleController)
class PaymentScheduleController extends ChangeNotifier {
  final PaymentScheduleRepository _repository;

  PaymentScheduleController(this._repository);

  List<PaymentScheduleModel> _schedules = [];
  PaymentScheduleModel? _selectedSchedule;
  NotificationPreferenceModel? _preference;
  List<NotificationModel> _notifications = [];

  bool _isLoading = false;
  bool _isUpdatingPreference = false;
  bool _isPaying = false;
  String? _errorMessage;
  String? _exceptionCode;

  String _filter = 'ALL'; // ALL, UPCOMING, OVERDUE, PAID
  int? _selectedLoanId;

  // ================= Getters =================

  List<PaymentScheduleModel> get schedules => List.unmodifiable(_schedules);

  PaymentScheduleModel? get selectedSchedule => _selectedSchedule;

  NotificationPreferenceModel? get preference => _preference;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  bool get isUpdatingPreference => _isUpdatingPreference;

  bool get isPaying => _isPaying;

  String? get errorMessage => _errorMessage;

  String? get exceptionCode => _exceptionCode;

  String get currentFilter => _filter;

  int? get selectedLoanId => _selectedLoanId;

  /// Kiểm tra trạng thái trống (EX-01: Chưa có lịch phân kỳ)
  bool get isEmptyState =>
      !_isLoading && _schedules.isEmpty && _exceptionCode == 'EX-01';

  /// Danh sách các kỳ thanh toán sau khi áp dụng bộ lọc (Mục 5.2 & Mục 12)
  List<PaymentScheduleModel> get filteredSchedules {
    final now = DateTime.now();

    return _schedules.where((s) {
      if (_selectedLoanId != null && s.loanId != _selectedLoanId) {
        return false;
      }

      switch (_filter) {
        case 'PAID':
          return s.status == 'PAID';
        case 'OVERDUE':
          return s.status == 'OVERDUE' ||
              (s.status != 'PAID' && s.dueDate.isBefore(now));
        case 'UPCOMING':
          // Sắp đến hạn: trong vòng reminderDays hoặc 7 ngày tới và chưa thanh toán
          final reminderDays = _preference?.reminderDays ?? 3;
          final threshold = now.add(Duration(days: reminderDays));
          return s.status != 'PAID' &&
              s.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
              s.dueDate.isBefore(threshold);
        case 'ALL':
        default:
          return true;
      }
    }).toList();
  }

  /// Số kỳ sắp đến hạn
  int get upcomingCount {
    final now = DateTime.now();
    final reminderDays = _preference?.reminderDays ?? 3;
    final threshold = now.add(Duration(days: reminderDays));

    return _schedules
        .where(
          (s) =>
              s.status != 'PAID' &&
              s.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
              s.dueDate.isBefore(threshold),
        )
        .length;
  }

  /// Số kỳ đã quá hạn
  int get overdueCount {
    final now = DateTime.now();
    return _schedules
        .where(
          (s) =>
              s.status == 'OVERDUE' ||
              (s.status != 'PAID' && s.dueDate.isBefore(now)),
        )
        .length;
  }

  /// Số kỳ đã thanh toán
  int get paidCount {
    return _schedules.where((s) => s.status == 'PAID').length;
  }

  /// Tổng số tiền đến hạn trong tháng hiện tại
  double get currentMonthDueAmount {
    final now = DateTime.now();
    return _schedules
        .where(
          (s) =>
              s.status != 'PAID' &&
              s.dueDate.month == now.month &&
              s.dueDate.year == now.year,
        )
        .fold(0.0, (sum, s) => sum + s.totalAmount);
  }

  // ================= Public Actions =================

  /// Tải toàn bộ danh sách lịch phân kỳ (Luồng 5: Xem lịch thanh toán)
  Future<void> loadSchedules({int? userId, int? loanId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final results = await _repository.getPaymentSchedules(
        userId: userId,
        loanId: loanId,
      );
      _schedules = results;

      if (_schedules.isEmpty) {
        _exceptionCode = 'EX-01'; // Chưa có lịch phân kỳ
      }

      // Tải kèm cấu hình thông báo nếu chưa có
      _preference ??= await _repository.getNotificationPreference(
        userId: userId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Truy xuất chi tiết một kỳ thanh toán cụ thể (Luồng 5.2 & Luồng 9)
  Future<bool> selectSchedule(int scheduleId, {int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final schedule = await _repository.getScheduleDetail(
        scheduleId,
        userId: userId,
      );
      _selectedSchedule = schedule;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _selectedSchedule = null;
      _resolveExceptionCode(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ghi nhận hoàn thành thanh toán cho kỳ (Luồng 7: Kỳ đã thanh toán)
  Future<bool> markAsPaid(int scheduleId, {int? userId}) async {
    _isPaying = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.markScheduleAsPaid(
        scheduleId,
        userId: userId,
      );

      final index = _schedules.indexWhere((s) => s.id == scheduleId);
      if (index >= 0) {
        _schedules[index] = updated;
      }
      if (_selectedSchedule?.id == scheduleId) {
        _selectedSchedule = updated;
      }

      _isPaying = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      _isPaying = false;
      notifyListeners();
      return false;
    }
  }

  /// Tải cấu hình thông báo (Mục 8: Cài đặt nhắc nợ)
  Future<void> loadNotificationPreference({int? userId}) async {
    try {
      _preference = await _repository.getNotificationPreference(userId: userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      notifyListeners();
    }
  }

  /// Cập nhật cấu hình thông báo (Mục 8)
  Future<bool> updatePreference(
    NotificationPreferenceModel newPref, {
    String? userEmail,
    String? userPhone,
  }) async {
    _isUpdatingPreference = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final updated = await _repository.updateNotificationPreference(
        newPref,
        userEmail: userEmail,
        userPhone: userPhone,
      );
      _preference = updated;
      _isUpdatingPreference = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      _isUpdatingPreference = false;
      notifyListeners();
      return false;
    }
  }

  /// Tải danh sách thông báo (Mục 9: Xem danh sách thông báo)
  Future<void> loadNotifications({int? userId}) async {
    try {
      final list = await _repository.getNotifications(userId: userId);
      _notifications = list;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      notifyListeners();
    }
  }

  /// Đồng bộ lịch phân kỳ và tái tạo thông báo (Mục 10)
  Future<int> syncSchedules({int? userId}) async {
    try {
      final count = await _repository.syncSchedulesAndNotifications(
        userId: userId,
      );
      await loadSchedules(userId: userId);
      await loadNotifications(userId: userId);
      return count;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      return 0;
    }
  }

  /// Thay đổi bộ lọc hiển thị
  void setFilter(String filter) {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
    }
  }

  /// Lọc theo khoản vay cụ thể
  void setSelectedLoan(int? loanId) {
    if (_selectedLoanId != loanId) {
      _selectedLoanId = loanId;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedSchedule = null;
    notifyListeners();
  }

  // ================= Private Exception Resolver =================

  void _resolveExceptionCode(String? error) {
    if (error == null) return;
    final lower = error.toLowerCase();
    if (lower.contains('quyền') || lower.contains('403')) {
      _exceptionCode = 'EX-02';
    } else if (lower.contains('email') ||
        lower.contains('số điện thoại') ||
        lower.contains('thiếu')) {
      _exceptionCode = 'EX-04';
    } else if (lower.contains('thất bại') || lower.contains('failed')) {
      _exceptionCode = 'EX-05';
    } else if (lower.contains('kết nối') ||
        lower.contains('cơ sở dữ liệu') ||
        lower.contains('500')) {
      _exceptionCode = 'EX-06';
    }
  }
}
