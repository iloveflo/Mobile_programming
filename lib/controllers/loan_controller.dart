import 'package:flutter/foundation.dart';

import '../models/collateral_model.dart';
import '../models/loan_model.dart';
import '../repositories/interfaces/loan_repository.dart';

/// Bộ điều khiển trung tâm quản lý danh mục và chi tiết các khoản vay (LoanController)
class LoanController extends ChangeNotifier {
  final LoanRepository _loanRepository;

  LoanController(this._loanRepository);

  // ================= Quản lý Trạng thái =================
  bool _isLoading = false;
  String? _errorMessage;

  List<LoanModel> _loans = [];
  LoanModel? _selectedLoan;
  List<CollateralModel> _collaterals = [];

  LoanStatus _currentFilterStatus = LoanStatus.all;
  String _searchKeyword = '';
  String? _selectedLender;

  // ================= Getters =================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LoanModel> get loans => List.unmodifiable(_loans);
  LoanModel? get selectedLoan => _selectedLoan;
  List<CollateralModel> get collaterals => List.unmodifiable(_collaterals);

  LoanStatus get currentFilterStatus => _currentFilterStatus;
  String get searchKeyword => _searchKeyword;
  String? get selectedLender => _selectedLender;

  // ================= Portfolio Metrics Getters =================

  /// Tổng dư nợ còn lại của các khoản vay đang hoạt động
  double get totalRemainingPrincipal => _loans
      .where((l) => l.isActive)
      .fold(0.0, (sum, l) => sum + l.outstandingAmount);

  /// Tổng số tiền gốc ban đầu của toàn bộ danh mục vay
  double get totalOriginalPrincipal =>
      _loans.fold(0.0, (sum, l) => sum + l.principalAmount);

  /// Tổng số tiền gốc đã thanh toán
  double get totalPaidAmount =>
      (totalOriginalPrincipal - totalRemainingPrincipal).clamp(
        0.0,
        totalOriginalPrincipal,
      );

  /// Tỷ lệ hoàn thành thanh toán danh mục (0.0 -> 1.0)
  double get paidRatio => totalOriginalPrincipal > 0
      ? (totalPaidAmount / totalOriginalPrincipal).clamp(0.0, 1.0)
      : 0.0;

  /// Tổng số tiền ước tính cần thanh toán trong tháng tới
  double get totalMonthlyCommitment => _loans
      .where((l) => l.isActive)
      .fold(0.0, (sum, l) => sum + l.monthlyInstallmentEstimate);

  /// Số lượng khoản vay đang hoạt động
  int get activeLoansCount => _loans.where((l) => l.isActive).length;

  /// Tổng giá trị tài sản thế chấp hiện tại
  double get totalCollateralValue =>
      _collaterals.fold(0.0, (sum, c) => sum + c.value);

  /// Tỷ lệ LTV (Loan-to-Value) tổng thể: Dư nợ / Giá trị tài sản
  double get portfolioLtvRatio {
    if (totalCollateralValue <= 0) return 0.0;
    return (totalRemainingPrincipal / totalCollateralValue).clamp(0.0, 2.0);
  }

  // ================= Bộ lọc & Tìm kiếm =================

  Future<void> setFilterStatus(LoanStatus status) async {
    if (_currentFilterStatus != status) {
      _currentFilterStatus = status;
      await fetchLoans(
        keyword: _searchKeyword,
        status: status,
        lender: _selectedLender,
      );
    }
  }

  Future<void> setSearchKeyword(String query) async {
    _searchKeyword = query;
    await fetchLoans(
      keyword: query,
      status: _currentFilterStatus,
      lender: _selectedLender,
    );
  }

  Future<void> setSelectedLender(String? lender) async {
    _selectedLender = lender;
    await fetchLoans(
      keyword: _searchKeyword,
      status: _currentFilterStatus,
      lender: lender,
    );
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ================= Nghiệp vụ Tác vụ =================

  /// Tải danh sách khoản vay theo các tiêu chí tìm kiếm và lọc
  Future<void> fetchLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _loanRepository.getLoans(
        keyword: keyword ?? _searchKeyword,
        status: status ?? _currentFilterStatus,
        lender: lender ?? _selectedLender,
      );
      _loans = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Chọn nhanh khoản vay để hiển thị tức thì trên màn hình chi tiết trước khi tải
  void selectLoan(LoanModel loan) {
    _selectedLoan = loan;
    notifyListeners();
  }

  /// Lấy thông tin chi tiết một khoản vay và tài sản thế chấp đi kèm
  Future<void> getDetail(String id) async {
    // 1. Tối ưu UX - Instant Cache: Nếu khoản vay đã có sẵn trong danh sách thì hiển thị tức thì
    final cached = _loans.cast<LoanModel?>().firstWhere(
      (l) =>
          l?.id.toString() == id ||
          l?.loanCode.toLowerCase() == id.toLowerCase(),
      orElse: () => null,
    );
    if (cached != null) {
      _selectedLoan = cached;
    } else {
      _isLoading = true;
      notifyListeners();
    }

    _errorMessage = null;

    try {
      // 2. Tải song song thông tin khoản vay và tài sản thế chấp thay vì chờ tuần tự
      final results = await Future.wait([
        _loanRepository.getLoanDetail(id),
        _loanRepository.getCollateralsByLoan(id),
      ]);

      _selectedLoan = results[0] as LoanModel;
      _collaterals = results[1] as List<CollateralModel>;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Tạo mới khoản vay
  Future<bool> createLoan(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _loanRepository.createLoan(data);
      // Chèn vào đầu danh sách hiện tại
      _loans.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật thông tin khoản vay
  Future<bool> updateLoan(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _loanRepository.updateLoan(id, data);
      final index = _loans.indexWhere(
        (l) => l.id.toString() == id || l.loanCode == id,
      );
      if (index != -1) {
        _loans[index] = updated;
      }
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Tất toán khoản vay trước hạn
  Future<bool> settleLoanEarly(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _loanRepository.updateLoan(id, {
        'outstanding_amount': 0.0,
        'status': 'SETTLED',
      });

      final index = _loans.indexWhere(
        (l) => l.id.toString() == id || l.loanCode == id,
      );
      if (index != -1) {
        _loans[index] = updated;
      }
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = updated;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa khoản vay (Chỉ cho phép xóa khi chưa phát sinh giao dịch thanh toán, tuyệt đối không có chế độ đóng khoản vay)
  Future<bool> removeLoan(String id, {bool softDelete = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      LoanModel? loanTarget;
      try {
        loanTarget = _loans.firstWhere(
          (l) => l.id.toString() == id || l.loanCode == id,
        );
      } catch (_) {
        loanTarget = _selectedLoan;
      }

      // Nếu đã phát sinh thanh toán (paidAmount > 0) -> Tuyệt đối không được phép xóa
      if (loanTarget != null && !loanTarget.canHardDelete) {
        throw Exception(
          'Khoản vay này đã phát sinh giao dịch thanh toán nên không thể xóa.',
        );
      }

      await _loanRepository.deleteLoan(id, softDelete: false);
      _loans.removeWhere((l) => l.id.toString() == id || l.loanCode == id);
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xử lý quét tài liệu hợp đồng OCR
  Future<Map<String, dynamic>?> processOcr(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _loanRepository.scanDocumentOcr(imagePath);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Không thể bóc tách tài liệu hợp đồng: ${e.toString().replaceAll('Exception: ', '')}';
      notifyListeners();
      return null;
    }
  }

  /// Lấy danh sách tài sản bảo đảm (theo khoản vay hoặc tất cả của người dùng)
  Future<void> fetchCollaterals([String? loanId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      _collaterals = await _loanRepository.getCollaterals(loanId: loanId);
    } catch (_) {
      if (loanId != null) {
        try {
          _collaterals = await _loanRepository.getCollateralsByLoan(loanId);
        } catch (_) {}
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm mới tài sản bảo đảm bằng tay hoặc từ hồ sơ
  Future<bool> addCollateral({
    required String name,
    required String type,
    required double value,
    String? loanId,
    String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final config = CollateralModel.getConfig(type);
      if (value < config.minValue) {
        throw Exception(
          'Giá trị định giá cho ${config.displayName} tối thiểu là ${config.minFormatted}.',
        );
      }
      if (value > config.maxValue) {
        throw Exception(
          'Giá trị định giá cho ${config.displayName} tối đa là ${config.maxFormatted}.',
        );
      }

      final payload = <String, dynamic>{
        'name': name,
        'type': type,
        'value': value,
      };
      if (loanId != null) payload['loan_id'] = loanId;
      if (description != null) payload['description'] = description;

      final newCollateral = await _loanRepository.addCollateral(payload);

      // Bổ sung ngay vào đầu danh sách để hiển thị tức thì trên giao diện
      _collaterals.removeWhere((c) => c.id == newCollateral.id);
      _collaterals.insert(0, newCollateral);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại toàn bộ dữ liệu trạng thái (dùng khi đăng xuất hoặc chuyển đổi tài khoản)
  void clear() {
    _loans = [];
    _selectedLoan = null;
    _collaterals = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
