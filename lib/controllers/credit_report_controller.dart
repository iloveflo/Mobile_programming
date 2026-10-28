import 'package:flutter/foundation.dart';

import '../models/credit_report_model.dart';
import '../repositories/interfaces/credit_report_repository.dart';

/// Bộ điều khiển Quản lý Báo cáo Tín dụng Định kỳ (CreditReportController)
/// Đảm nhiệm lưu trữ trạng thái danh sách báo cáo, ảnh chụp chi tiết, và tính toán chuỗi xu hướng
class CreditReportController extends ChangeNotifier {
  final CreditReportRepository _repository;

  CreditReportController(this._repository);

  List<CreditReportModel> _reports = [];
  CreditReportModel? _selectedReport;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  String? _exceptionCode;

  // ================= Getters =================

  List<CreditReportModel> get reports => List.unmodifiable(_reports);

  CreditReportModel? get selectedReport => _selectedReport;

  bool get isLoading => _isLoading;

  bool get isGenerating => _isGenerating;

  String? get errorMessage => _errorMessage;

  String? get exceptionCode => _exceptionCode;

  /// Kiểm tra trạng thái trống (EX-01: Chưa có báo cáo nào)
  bool get isEmptyState =>
      !_isLoading && _reports.isEmpty && _exceptionCode == 'EX-01';

  /// Danh sách báo cáo theo trình tự thời gian tăng dần (cũ nhất -> mới nhất) để vẽ biểu đồ và phân tích xu hướng
  List<CreditReportModel> get trendReports {
    final list = List<CreditReportModel>.from(_reports);
    list.sort((a, b) {
      final dateA = a.generatedAt ?? DateTime(1970);
      final dateB = b.generatedAt ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
    return list;
  }

  /// Báo cáo gần nhất trong hệ thống
  CreditReportModel? get latestReport =>
      _reports.isNotEmpty ? _reports.first : null;

  /// Báo cáo liền trước báo cáo gần nhất (dùng để so sánh biến động kỳ gần nhất)
  CreditReportModel? get previousReport =>
      _reports.length > 1 ? _reports[1] : null;

  /// Biến động điểm tín dụng giữa kỳ mới nhất và kỳ liền trước
  int? get scoreDelta {
    if (latestReport?.creditScore == null ||
        previousReport?.creditScore == null) {
      return null;
    }
    return latestReport!.creditScore! - previousReport!.creditScore!;
  }

  /// Biến động tổng dư nợ giữa kỳ mới nhất và kỳ liền trước (số âm nghĩa là dư nợ đã giảm)
  double? get debtDelta {
    if (latestReport == null || previousReport == null) {
      return null;
    }
    return latestReport!.totalDebt - previousReport!.totalDebt;
  }

  // ================= Public Actions =================

  /// Tải danh sách các kỳ báo cáo tín dụng của người dùng (Luồng 2)
  Future<void> loadReports({int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final results = await _repository.getCreditReports(userId: userId);
      _reports = results;

      if (_reports.isEmpty) {
        _exceptionCode = 'EX-01'; // Trạng thái chưa có báo cáo
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Truy xuất chi tiết ảnh chụp một bản ghi báo cáo tín dụng (Luồng 3)
  Future<bool> selectReport(int reportId, {int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final report = await _repository.getCreditReportDetail(
        reportId,
        userId: userId,
      );
      _selectedReport = report;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _selectedReport = null;
      _resolveExceptionCode(_errorMessage);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Khởi tạo một kỳ báo cáo tín dụng mới (Luồng 1)
  Future<bool> generateNewReport({
    int? userId,
    required String reportPeriod,
  }) async {
    _isGenerating = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final newReport = await _repository.generateReport(
        userId: userId,
        reportPeriod: reportPeriod,
      );

      // Thêm báo cáo mới vào đầu danh sách và chọn xem ngay
      _reports.insert(0, newReport);
      _selectedReport = newReport;
      _exceptionCode = null;
      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _resolveExceptionCode(_errorMessage);
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại chi tiết đang chọn
  void clearSelection() {
    _selectedReport = null;
    notifyListeners();
  }

  // ================= Private Exception Resolver =================

  void _resolveExceptionCode(String? error) {
    if (error == null) return;
    final lower = error.toLowerCase();
    if (lower.contains('quyền') || lower.contains('403')) {
      _exceptionCode = 'EX-03';
    } else if (lower.contains('không tìm thấy') || lower.contains('404')) {
      _exceptionCode = 'EX-02';
    } else if (lower.contains('chưa đầy đủ') ||
        lower.contains('thiếu') ||
        lower.contains('400')) {
      _exceptionCode = 'EX-04';
    } else if (lower.contains('cơ sở dữ liệu') ||
        lower.contains('sự cố') ||
        lower.contains('500')) {
      _exceptionCode = 'EX-05';
    }
  }
}
