import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../models/collateral_model.dart';
import '../models/loan_document_model.dart';
import '../models/loan_model.dart';
import '../repositories/interfaces/loan_repository.dart';
import 'credit_profile_controller.dart';
import 'payment_schedule_controller.dart';

/// Bộ điều khiển trung tâm quản lý danh mục và chi tiết các khoản vay (LoanController)
class LoanController extends ChangeNotifier {
  final LoanRepository _loanRepository;

  LoanController(this._loanRepository);

  // ================= Quản lý Trạng thái =================
  bool _isLoading = false;
  String? _errorMessage;

  List<LoanModel> _allLoans = [];
  List<LoanModel> _loans = [];
  LoanModel? _selectedLoan;
  List<CollateralModel> _collaterals = [];
  List<CollateralModel> _portfolioCollaterals = [];
  List<LoanDocumentModel> _loanDocuments = [];

  LoanStatus _currentFilterStatus = LoanStatus.all;
  String _searchKeyword = '';
  String? _selectedLender;

  // ================= Getters =================
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<LoanModel> get allLoans => List.unmodifiable(_allLoans);
  List<LoanModel> get loans => List.unmodifiable(_loans);
  LoanModel? get selectedLoan => _selectedLoan;
  List<CollateralModel> get collaterals => List.unmodifiable(_collaterals);
  List<CollateralModel> get portfolioCollaterals => List.unmodifiable(
    _portfolioCollaterals.isNotEmpty ? _portfolioCollaterals : _collaterals,
  );
  List<LoanDocumentModel> get loanDocuments =>
      List.unmodifiable(_loanDocuments);

  LoanStatus get currentFilterStatus => _currentFilterStatus;
  String get searchKeyword => _searchKeyword;
  String? get selectedLender => _selectedLender;

  // ================= Portfolio Metrics Getters =================

  /// Tổng dư nợ còn lại của các khoản vay đang hoạt động (gồm cả ACTIVE và OVERDUE)
  double get totalRemainingPrincipal => _allLoans
      .where((l) => l.isActive || l.isOverdue)
      .fold(0.0, (sum, l) => sum + l.outstandingAmount);

  /// Tổng số tiền gốc ban đầu của toàn bộ danh mục vay
  double get totalOriginalPrincipal =>
      _allLoans.fold(0.0, (sum, l) => sum + l.principalAmount);

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
  double get totalMonthlyCommitment => _allLoans
      .where((l) => l.isActive || l.isOverdue)
      .fold(0.0, (sum, l) => sum + l.monthlyInstallmentEstimate);

  /// Số lượng khoản vay đang còn nghĩa vụ (ACTIVE hoặc OVERDUE)
  int get activeLoansCount =>
      _allLoans.where((l) => l.isActive || l.isOverdue).length;

  /// Tổng giá trị tài sản thế chấp hiện tại (theo danh sách đang hiển thị)
  double get totalCollateralValue =>
      _collaterals.fold(0.0, (sum, c) => sum + c.value);

  /// Tổng giá trị toàn bộ tài sản bảo đảm của người dùng (không bị ghi đè khi xem chi tiết 1 khoản vay)
  double get portfolioCollateralValue =>
      portfolioCollaterals.fold(0.0, (sum, c) => sum + c.value);

  /// Tổng dư nợ của các khoản vay có tài sản bảo đảm (không gộp nợ tín chấp)
  double get portfolioSecuredDebt {
    if (_collaterals.isEmpty) return 0.0;
    final linkedIds = <String>{};
    for (final c in _collaterals) {
      for (final id in c.linkedLoanIds) {
        linkedIds.add(id);
      }
      if (c.loanId != null) {
        linkedIds.add(c.loanId.toString());
      }
    }
    final activeLoans = _allLoans.where((l) => l.isActive || l.isOverdue);
    if (linkedIds.isNotEmpty) {
      return activeLoans
          .where((l) => linkedIds.contains(l.id.toString()))
          .fold(0.0, (sum, l) => sum + l.outstandingAmount);
    }
    return activeLoans
        .where((l) => l.loanTypeKey == 'MORTGAGE' || l.loanTypeKey == 'CAR')
        .fold(0.0, (sum, l) => sum + l.outstandingAmount);
  }

  /// Tỷ lệ LTV (Loan-to-Value) tổng thể trên các khoản vay có TSBĐ: Dư nợ có TSBĐ / Giá trị tài sản
  double get portfolioLtvRatio {
    if (totalCollateralValue <= 0) return 0.0;
    return (portfolioSecuredDebt / totalCollateralValue).clamp(0.0, 2.0);
  }

  // ================= Bộ lọc & Tìm kiếm =================

  void _applyFilters() {
    var results = List<LoanModel>.from(_allLoans);

    if (_searchKeyword.trim().isNotEmpty) {
      final query = _searchKeyword.trim().toLowerCase();
      results = results.where((loan) {
        return loan.name.toLowerCase().contains(query) ||
            loan.loanCode.toLowerCase().contains(query) ||
            loan.lenderName.toLowerCase().contains(query);
      }).toList();
    }

    switch (_currentFilterStatus) {
      case LoanStatus.active:
        results = results.where((l) => l.isActive).toList();
        break;
      case LoanStatus.closed:
        results = results.where((l) => l.isClosed).toList();
        break;
      case LoanStatus.overdue:
        results = results.where((l) => l.isOverdue).toList();
        break;
      case LoanStatus.all:
        break;
    }

    if (_selectedLender != null &&
        _selectedLender!.trim().isNotEmpty &&
        _selectedLender != 'Tất cả') {
      final lender = _selectedLender!.trim().toLowerCase();
      results = results
          .where((l) => l.lenderName.toLowerCase() == lender)
          .toList();
    }

    _loans = results;
  }

  Future<void> setFilterStatus(LoanStatus status) async {
    if (_currentFilterStatus != status) {
      _currentFilterStatus = status;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> setSearchKeyword(String query) async {
    _searchKeyword = query;
    _applyFilters();
    notifyListeners();
  }

  Future<void> setSelectedLender(String? lender) async {
    _selectedLender = lender;
    _applyFilters();
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ================= Nghiệp vụ Tác vụ =================

  /// Tải danh sách khoản vay đầy đủ từ repository và áp dụng bộ lọc hiện tại
  Future<void> fetchLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    if (keyword != null) _searchKeyword = keyword;
    if (status != null) _currentFilterStatus = status;
    if (lender != null) _selectedLender = lender;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _loanRepository.getLoans();
      _allLoans = results;
      _applyFilters();
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
    final cached = _allLoans.cast<LoanModel?>().firstWhere(
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
      _allLoans.insert(0, created);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      _syncDependentControllers();
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
      final index = _allLoans.indexWhere(
        (l) => l.id.toString() == id || l.loanCode == id,
      );
      if (index != -1) {
        _allLoans[index] = updated;
      }
      _applyFilters();
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = updated;
      }
      _isLoading = false;
      notifyListeners();
      _syncDependentControllers();
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

      final index = _allLoans.indexWhere(
        (l) => l.id.toString() == id || l.loanCode == id,
      );
      if (index != -1) {
        _allLoans[index] = updated;
      }
      _applyFilters();
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = updated;
      }

      _isLoading = false;
      notifyListeners();
      _syncDependentControllers();
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
        loanTarget = _allLoans.firstWhere(
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
      _allLoans.removeWhere((l) => l.id.toString() == id || l.loanCode == id);
      _applyFilters();
      if (_selectedLoan?.id.toString() == id || _selectedLoan?.loanCode == id) {
        _selectedLoan = null;
      }

      _isLoading = false;
      notifyListeners();
      final deletedId = int.tryParse(id);
      if (deletedId != null &&
          GetIt.I.isRegistered<PaymentScheduleController>()) {
        final schedCtrl = GetIt.I<PaymentScheduleController>();
        if (schedCtrl.selectedLoanId == deletedId) {
          schedCtrl.setSelectedLoan(null, reload: false);
        }
      }
      _syncDependentControllers();
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
    _errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _loanRepository.getCollaterals(loanId: loanId);
      _collaterals = fetched;
      if (loanId == null) {
        _portfolioCollaterals = fetched;
      }
    } catch (e) {
      if (loanId != null) {
        try {
          _collaterals = await _loanRepository.getCollateralsByLoan(loanId);
        } catch (inner) {
          _errorMessage = inner.toString().replaceAll('Exception: ', '');
        }
        try {
          _loanDocuments = await _loanRepository.getLoanDocuments(loanId);
        } catch (_) {}
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy danh sách hồ sơ tài liệu lưu trữ của hợp đồng vay trên Cloudflare R2
  Future<void> fetchLoanDocuments(String loanId) async {
    try {
      _loanDocuments = await _loanRepository.getLoanDocuments(loanId);
      notifyListeners();
    } catch (_) {
      _loanDocuments = [];
    }
  }

  /// Thêm mới tài sản bảo đảm bằng tay hoặc từ hồ sơ
  Future<bool> addCollateral({
    required String name,
    required String type,
    required double value,
    String? loanId,
    String? description,
    String? legalDocumentUrl,
    String? certificateNumber,
    String? valuationDate,
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
      if (legalDocumentUrl != null && legalDocumentUrl.isNotEmpty) {
        payload['legal_document_url'] = legalDocumentUrl;
      }
      if (certificateNumber != null && certificateNumber.isNotEmpty) {
        payload['certificate_number'] = certificateNumber;
      }
      if (valuationDate != null && valuationDate.isNotEmpty) {
        payload['valuation_date'] = valuationDate;
      }

      final newCollateral = await _loanRepository.addCollateral(payload);

      // Bổ sung ngay vào đầu danh sách để hiển thị tức thì trên giao diện
      _collaterals.removeWhere((c) => c.id == newCollateral.id);
      _collaterals.insert(0, newCollateral);
      _portfolioCollaterals.removeWhere((c) => c.id == newCollateral.id);
      _portfolioCollaterals.insert(0, newCollateral);

      _isLoading = false;
      notifyListeners();
      _syncDependentControllers();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xóa tài sản bảo đảm (kiểm tra ràng buộc khoản vay ở backend)
  Future<bool> deleteCollateral(int assetId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loanRepository.deleteCollateral(assetId);
      _collaterals.removeWhere((c) => c.id == assetId);
      _portfolioCollaterals.removeWhere((c) => c.id == assetId);
      _isLoading = false;
      notifyListeners();
      _syncDependentControllers();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _syncDependentControllers() {
    try {
      if (GetIt.I.isRegistered<PaymentScheduleController>()) {
        GetIt.I<PaymentScheduleController>().loadSchedules();
      }
      if (GetIt.I.isRegistered<CreditProfileController>()) {
        GetIt.I<CreditProfileController>().recalculate();
      }
    } catch (_) {}
  }

  /// Đặt lại toàn bộ dữ liệu trạng thái (dùng khi đăng xuất hoặc chuyển đổi tài khoản)
  void clear() {
    _loans = [];
    _selectedLoan = null;
    _collaterals = [];
    _portfolioCollaterals = [];
    _loanDocuments = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
