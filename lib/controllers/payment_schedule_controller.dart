import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../models/notification_model.dart';
import '../models/notification_preference_model.dart';
import '../models/payment_schedule_model.dart';
import '../repositories/interfaces/payment_schedule_repository.dart';
import 'credit_profile_controller.dart';
import 'loan_controller.dart';

/// Bộ điều khiển Quản lý Lịch thanh toán định kỳ & Nhắc nợ (PaymentScheduleController)
class PaymentScheduleController extends ChangeNotifier {
  final PaymentScheduleRepository _repository;

  PaymentScheduleController(this._repository);

  List<PaymentScheduleModel> _schedules = [];
  PaymentScheduleModel? _selectedSchedule;
  NotificationPreferenceModel? _preference;
  List<NotificationModel> _notifications = [];

  static const int defaultPageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isUpdatingPreference = false;
  bool _isPaying = false;
  String? _errorMessage;
  String? _exceptionCode;

  String _filter = 'ALL'; // ALL, UPCOMING, OVERDUE, PAID
  String _period = 'ALL'; // ALL, 1M, 3M, 6M, 1Y
  int? _selectedLoanId;
  int _currentPage = 1;
  int _totalMatching = 0;
  bool _hasMore = false;
  ScheduleSummaryModel? _summary;
  int? _lastUserId;
  int? _lastLoanId;

  // ================= Getters =================

  List<PaymentScheduleModel> get schedules => List.unmodifiable(_schedules);

  PaymentScheduleModel? get selectedSchedule => _selectedSchedule;

  NotificationPreferenceModel? get preference => _preference;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get hasMore => _hasMore;

  bool get isUpdatingPreference => _isUpdatingPreference;

  bool get isPaying => _isPaying;

  String? get errorMessage => _errorMessage;

  String? get exceptionCode => _exceptionCode;

  String get currentFilter => _filter;

  String get currentPeriod => _period;

  int? get selectedLoanId => _selectedLoanId;

  int get totalMatching =>
      _summary != null ? _totalMatching : filteredSchedules.length;

  /// Kiểm tra trạng thái trống (EX-01: Chưa có lịch phân kỳ)
  bool get isEmptyState =>
      !_isLoading &&
      _schedules.isEmpty &&
      _exceptionCode == 'EX-01' &&
      (_summary == null || _summary!.totalCount == 0);

  /// Danh sách các kỳ thanh toán sau khi áp dụng bộ lọc (Mục 5.2 & Mục 12)
  List<PaymentScheduleModel> get filteredSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _schedules.where((s) {
      if (_selectedLoanId != null && s.loanId != _selectedLoanId) {
        return false;
      }

      final dueDay = DateTime(s.dueDate.year, s.dueDate.month, s.dueDate.day);
      switch (_filter) {
        case 'PAID':
          return s.status == 'PAID';
        case 'OVERDUE':
          return s.status == 'OVERDUE' ||
              (s.status != 'PAID' && dueDay.isBefore(today));
        case 'UPCOMING':
          // Chưa đến hạn: tất cả các kỳ chưa thanh toán có hạn từ hôm nay trở đi
          return s.status != 'PAID' &&
              s.status != 'OVERDUE' &&
              !dueDay.isBefore(today);
        case 'ALL':
        default:
          return true;
      }
    }).toList();
  }

  /// Số kỳ chưa đến hạn
  int get upcomingCount {
    if (_summary != null) return _summary!.upcomingCount;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _schedules.where((s) {
      final dueDay = DateTime(s.dueDate.year, s.dueDate.month, s.dueDate.day);
      return s.status != 'PAID' &&
          s.status != 'OVERDUE' &&
          !dueDay.isBefore(today);
    }).length;
  }

  /// Số kỳ đã quá hạn
  int get overdueCount {
    if (_summary != null) return _summary!.overdueCount;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _schedules.where((s) {
      final dueDay = DateTime(s.dueDate.year, s.dueDate.month, s.dueDate.day);
      return s.status == 'OVERDUE' ||
          (s.status != 'PAID' && dueDay.isBefore(today));
    }).length;
  }

  /// Số kỳ đã thanh toán
  int get paidCount {
    if (_summary != null) return _summary!.paidCount;
    return _schedules.where((s) => s.status == 'PAID').length;
  }

  /// Tổng số tiền đến hạn trong tháng hiện tại
  double get currentMonthDueAmount {
    if (_summary != null) return _summary!.currentMonthDueAmount;
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

  /// Tải danh sách lịch phân kỳ theo trang & bộ lọc (Luồng 5: Xem lịch thanh toán)
  Future<void> loadSchedules({
    int? userId,
    int? loanId,
    int pageSize = defaultPageSize,
    bool preserveExisting = false,
  }) async {
    _lastUserId = userId;
    _lastLoanId = loanId ?? _selectedLoanId;
    if (!preserveExisting) {
      _isLoading = true;
    }
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final result = await _repository.getPaymentSchedulesPage(
        userId: userId,
        loanId: _lastLoanId,
        status: _filter,
        period: _period,
        page: 1,
        limit: pageSize,
      );
      _schedules = result.items;
      _summary = result.summary;
      _currentPage = result.page;
      _totalMatching = result.total;
      _hasMore = result.hasMore;

      if (result.summary.totalCount == 0 && _schedules.isEmpty) {
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

  /// Tải thêm các kỳ tiếp theo khi người dùng cuộn xuống cuối danh sách
  Future<void> loadMoreSchedules({
    int? userId,
    int? loanId,
    int pageSize = defaultPageSize,
  }) async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _repository.getPaymentSchedulesPage(
        userId: userId ?? _lastUserId,
        loanId: loanId ?? _lastLoanId,
        status: _filter,
        period: _period,
        page: _currentPage + 1,
        limit: pageSize,
      );
      final existingIds = _schedules.map((s) => s.id).toSet();
      final nextItems = result.items
          .where((item) => !existingIds.contains(item.id))
          .toList();
      _schedules = [..._schedules, ...nextItems];
      _summary = result.summary;
      _currentPage = result.page;
      _totalMatching = result.total;
      _hasMore = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
    } finally {
      _isLoadingMore = false;
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
    if (_isPaying) return false;
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

      await loadSchedules(
        userId: userId ?? _lastUserId,
        loanId: _lastLoanId,
        preserveExisting: true,
      );

      _isPaying = false;
      notifyListeners();
      try {
        if (GetIt.I.isRegistered<LoanController>()) {
          GetIt.I<LoanController>().fetchLoans();
        }
        if (GetIt.I.isRegistered<CreditProfileController>()) {
          GetIt.I<CreditProfileController>().recalculate(userId: userId);
        }
      } catch (_) {}
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

  /// Xóa một thông báo cụ thể
  Future<bool> deleteNotification(int notificationId, {int? userId}) async {
    try {
      await _repository.deleteNotification(notificationId, userId: userId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Xóa toàn bộ thông báo của người dùng
  Future<bool> clearNotifications({int? userId}) async {
    try {
      await _repository.clearNotifications(userId: userId);
      _notifications.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      notifyListeners();
      return false;
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

  /// Thay đổi bộ lọc trạng thái hiển thị và tải trang đầu từ Backend
  void setFilter(
    String filter, {
    int? userId,
    int? loanId,
    bool reload = true,
  }) {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
      if (reload) {
        loadSchedules(
          userId: userId ?? _lastUserId,
          loanId: loanId ?? _lastLoanId,
          preserveExisting: true,
        );
      }
    }
  }

  /// Thay đổi bộ lọc khoảng thời gian (ALL, 1M, 3M, 6M, 1Y)
  void setPeriod(
    String period, {
    int? userId,
    int? loanId,
    bool reload = true,
  }) {
    if (_period != period) {
      _period = period;
      notifyListeners();
      if (reload) {
        loadSchedules(
          userId: userId ?? _lastUserId,
          loanId: loanId ?? _lastLoanId,
          preserveExisting: true,
        );
      }
    }
  }

  /// Lọc theo khoản vay cụ thể
  void setSelectedLoan(int? loanId, {int? userId, bool reload = true}) {
    if (_selectedLoanId != loanId) {
      _selectedLoanId = loanId;
      notifyListeners();
      if (reload) {
        loadSchedules(
          userId: userId ?? _lastUserId,
          loanId: loanId,
          preserveExisting: true,
        );
      }
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
