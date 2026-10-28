import 'package:flutter/foundation.dart';

import '../models/credit_profile_model.dart';
import '../models/loan_model.dart';
import '../repositories/interfaces/credit_profile_repository.dart';
import '../repositories/interfaces/loan_repository.dart';

/// Bộ điều khiển trung tâm quản lý luồng nghiệp vụ Sức khỏe tín dụng (CreditProfileController)
class CreditProfileController extends ChangeNotifier {
  final CreditProfileRepository _creditProfileRepository;
  final LoanRepository _loanRepository;

  CreditProfileController(this._creditProfileRepository, this._loanRepository);

  // ================= Quản lý Trạng thái =================
  bool _isLoading = false;
  bool _isRecalculating = false;
  String? _errorMessage;
  String? _exceptionCode; // 'EX-01', 'EX-02', 'EX-03', 'EX-04'

  CreditProfileModel? _creditProfile;
  List<LoanModel> _userLoans = [];

  // ================= Getters =================
  bool get isLoading => _isLoading;
  bool get isRecalculating => _isRecalculating;
  String? get errorMessage => _errorMessage;
  String? get exceptionCode => _exceptionCode;
  CreditProfileModel? get creditProfile => _creditProfile;
  List<LoanModel> get userLoans => List.unmodifiable(_userLoans);

  /// Kiểm tra xem có khoản vay nào không (EX-01)
  bool get hasLoans =>
      _userLoans.isNotEmpty ||
      (_creditProfile != null && _creditProfile!.activeLoanCount > 0);

  /// Kiểm tra có đang ở trạng thái EX-01 (Chưa có khoản vay)
  bool get isEmptyState =>
      _exceptionCode == 'EX-01' || (!hasLoans && _creditProfile == null);

  /// Danh sách các chỉ số bị khuyết thiếu dữ liệu (EX-02)
  List<String> get missingDataFactors {
    if (_creditProfile == null) return const [];
    final List<String> factors = [];
    if (_creditProfile!.dtiRatio == null) {
      factors.add(
        'Chưa cập nhật thu nhập hàng tháng (không thể tính tỷ lệ DTI)',
      );
    }
    if (_creditProfile!.ltvRatio == null) {
      factors.add(
        'Chưa có định giá tài sản bảo đảm (không thể tính tỷ lệ LTV)',
      );
    }
    if (_creditProfile!.creditUtilization == null) {
      factors.add(
        'Chưa có dữ liệu hạn mức thẻ tín dụng (không thể tính tỷ lệ sử dụng hạn mức)',
      );
    }
    if (_creditProfile!.onTimePaymentRate == null) {
      factors.add(
        'Chưa đủ dữ liệu lịch phân kỳ & thanh toán (không thể tính tỷ lệ đúng hạn)',
      );
    }
    return factors;
  }

  /// Có chỉ số nào bị khuyết dữ liệu hay không (EX-02)
  bool get hasMissingData => missingDataFactors.isNotEmpty;

  // ================= Phương thức Hành động =================

  /// Tải hồ sơ sức khỏe tín dụng hiện tại từ Backend (Mục 6)
  Future<void> loadCreditProfile({int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      // 1. Kiểm tra danh sách khoản vay của người dùng
      _userLoans = await _loanRepository.getLoans();

      // EX-01: Nếu người dùng hoàn toàn chưa có khoản vay nào trên hệ thống
      if (_userLoans.isEmpty) {
        _exceptionCode = 'EX-01';
        _creditProfile = null;
        return;
      }

      // 2. Truy xuất hồ sơ CreditProfile
      _creditProfile = await _creditProfileRepository.getCreditProfile(
        userId: userId,
      );

      if (_creditProfile == null) {
        // Có khoản vay nhưng chưa có CreditProfile -> Gọi tính toán tự động
        await recalculate(userId: userId);
        return;
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = msg;
      if (msg.contains('EX-03') || msg.contains('quyền')) {
        _exceptionCode = 'EX-03';
      } else if (msg.contains('EX-04') ||
          msg.contains('Database') ||
          msg.contains('máy chủ')) {
        _exceptionCode = 'EX-04';
      } else {
        _exceptionCode = 'EX-04';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yêu cầu Backend tính toán lại và cập nhật toàn bộ hồ sơ (Mục 7)
  Future<bool> recalculate({int? userId}) async {
    _isRecalculating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _creditProfileRepository.recalculateCreditProfile(
        userId: userId,
      );
      _creditProfile = updated;
      _exceptionCode = null;

      // Cập nhật lại danh sách khoản vay đồng bộ
      _userLoans = await _loanRepository.getLoans();

      _isRecalculating = false;
      notifyListeners();
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = msg;
      if (msg.contains('EX-03') || msg.contains('quyền')) {
        _exceptionCode = 'EX-03';
      } else {
        _exceptionCode = 'EX-04';
      }
      _isRecalculating = false;
      notifyListeners();
      return false;
    }
  }

  /// Xóa bỏ thông báo lỗi
  void clearError() {
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();
  }
}
