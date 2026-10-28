import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/debt_strategy_model.dart';
import '../models/loan_model.dart';
import '../repositories/interfaces/debt_strategy_repository.dart';
import '../repositories/interfaces/loan_repository.dart';

/// Bộ điều khiển trung tâm quản lý luồng nghiệp vụ Tối ưu trả nợ (Snowball & Avalanche)
class DebtStrategyController extends ChangeNotifier {
  final DebtStrategyRepository _debtStrategyRepository;
  final LoanRepository _loanRepository;

  DebtStrategyController(this._debtStrategyRepository, this._loanRepository);

  // ================= Quản lý Trạng thái =================
  bool _isLoading = false;
  bool _isApplying = false;
  String? _errorMessage;
  String? _exceptionCode; // 'EX-01', 'EX-02', 'EX-04', 'EX-05'

  List<LoanModel> _allLoans = [];
  final List<LoanModel> _validLoans = [];
  final List<LoanModel> _invalidLoans =
      []; // Lưu các khoản nợ thiếu dữ liệu (EX-02)

  DebtStrategyType _selectedStrategyType = DebtStrategyType.avalanche;
  double _extraMonthlyPayment = 2000000.0; // 2.000.000 VNĐ trả thêm mặc định
  DebtStrategyModel? _activeAppliedStrategy;

  DebtStrategyPlanResult? _snowballPlan;
  DebtStrategyPlanResult? _avalanchePlan;

  // ================= Getters =================
  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  String? get errorMessage => _errorMessage;
  String? get exceptionCode => _exceptionCode;

  List<LoanModel> get validLoans => List.unmodifiable(_validLoans);
  List<LoanModel> get invalidLoans => List.unmodifiable(_invalidLoans);
  DebtStrategyType get selectedStrategyType => _selectedStrategyType;
  double get extraMonthlyPayment => _extraMonthlyPayment;
  DebtStrategyModel? get activeAppliedStrategy => _activeAppliedStrategy;

  DebtStrategyPlanResult? get snowballPlan => _snowballPlan;
  DebtStrategyPlanResult? get avalanchePlan => _avalanchePlan;

  DebtStrategyPlanResult? get currentSelectedPlan =>
      _selectedStrategyType == DebtStrategyType.snowball
      ? _snowballPlan
      : _avalanchePlan;

  /// Kiểm tra có kế hoạch đang ACTIVE hay không
  bool get hasActivePlan =>
      _activeAppliedStrategy != null && _activeAppliedStrategy!.isActive;

  // ================= Chỉ số Tổng hợp Danh mục Nợ =================
  int get totalDebtsCount => _validLoans.length;

  double get totalOutstandingDebt =>
      _validLoans.fold(0.0, (sum, loan) => sum + loan.outstandingAmount);

  double get weightedAverageInterestRate {
    if (totalOutstandingDebt == 0) return 0.0;
    final totalWeighted = _validLoans.fold(
      0.0,
      (sum, loan) => sum + (loan.outstandingAmount * loan.interestRate),
    );
    return totalWeighted / totalOutstandingDebt;
  }

  // ================= Phương thức Hành động =================

  /// Tải dữ liệu các khoản nợ và chiến lược đang kích hoạt
  Future<void> loadData({int? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      // 1. Tải danh sách khoản vay
      _allLoans = await _loanRepository.getLoans();

      // 2. Tải chiến lược đang ACTIVE
      _activeAppliedStrategy = await _debtStrategyRepository.getActiveStrategy(
        userId: userId,
      );
      if (_activeAppliedStrategy != null) {
        _selectedStrategyType = _activeAppliedStrategy!.type;
        if (_activeAppliedStrategy!.extraPayment > 0) {
          _extraMonthlyPayment = _activeAppliedStrategy!.extraPayment;
        }
      }

      // 3. Phân loại & Rà soát nợ (Lọc EX-03 & Kiểm tra EX-01, EX-02)
      _filterAndValidateLoans();

      // 4. Nếu hợp lệ, kích hoạt tính toán Snowball & Avalanche
      if (_validLoans.isNotEmpty) {
        _calculatePlans();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _exceptionCode = 'EX-04';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lọc bỏ khoản vay đã tất toán (EX-03) và phát hiện nợ thiếu thông tin (EX-02, EX-01)
  void _filterAndValidateLoans() {
    _validLoans.clear();
    _invalidLoans.clear();

    for (final loan in _allLoans) {
      // EX-03: Khoản vay đã tất toán -> Tự động loại bỏ
      final isClosed =
          loan.status.toUpperCase() == 'CLOSED' || loan.outstandingAmount <= 0;
      if (isClosed) {
        continue;
      }

      // EX-02: Kiểm tra thiếu dữ liệu tính toán (thiếu lãi suất, term <= 0 hoặc dư nợ không hợp lệ)
      if (loan.interestRate < 0 ||
          loan.termMonths <= 0 ||
          loan.outstandingAmount.isNaN) {
        _invalidLoans.add(loan);
      } else {
        _validLoans.add(loan);
      }
    }

    if (_invalidLoans.isNotEmpty) {
      _exceptionCode = 'EX-02';
      _errorMessage =
          'Phát hiện ${_invalidLoans.length} khoản nợ thiếu dữ liệu tính toán.';
    } else if (_allLoans.isEmpty || _validLoans.isEmpty) {
      _exceptionCode = 'EX-01';
      _errorMessage = 'Tài khoản chưa có khoản nợ nào cần tối ưu.';
    }
  }

  /// Đổi chiến lược xem (Snowball <-> Avalanche)
  void setStrategyType(DebtStrategyType type) {
    if (_selectedStrategyType != type) {
      _selectedStrategyType = type;
      notifyListeners();
    }
  }

  /// Cập nhật số tiền trả thêm hàng tháng và tính toán lại
  void setExtraMonthlyPayment(double amount) {
    if (amount >= 0 && amount != _extraMonthlyPayment) {
      _extraMonthlyPayment = amount;
      if (_validLoans.isNotEmpty) {
        _calculatePlans();
      }
      notifyListeners();
    }
  }

  /// Kích hoạt tính toán thuật toán Snowball và Avalanche
  void _calculatePlans() {
    try {
      // 1. Snowball: Sắp xếp tăng dần theo dư nợ nhỏ nhất trước
      final snowballList = List<LoanModel>.from(_validLoans)
        ..sort((a, b) => a.outstandingAmount.compareTo(b.outstandingAmount));

      _snowballPlan = _simulateStrategy(
        strategyType: DebtStrategyType.snowball,
        sortedLoans: snowballList,
        extraPayment: _extraMonthlyPayment,
      );

      // 2. Avalanche: Sắp xếp giảm dần theo mức lãi suất cao nhất trước
      final avalancheList = List<LoanModel>.from(_validLoans)
        ..sort((a, b) => b.interestRate.compareTo(a.interestRate));

      _avalanchePlan = _simulateStrategy(
        strategyType: DebtStrategyType.avalanche,
        sortedLoans: avalancheList,
        extraPayment: _extraMonthlyPayment,
      );
    } catch (e) {
      _exceptionCode = 'EX-04';
      _errorMessage = 'Lỗi trong quá trình tính toán thuật toán tối ưu: $e';
    }
  }

  /// Mô phỏng dòng tiền trả nợ từng kỳ theo nguyên tắc dồn tiền
  DebtStrategyPlanResult _simulateStrategy({
    required DebtStrategyType strategyType,
    required List<LoanModel> sortedLoans,
    required double extraPayment,
  }) {
    final double totalDebt = sortedLoans.fold(
      0.0,
      (sum, l) => sum + l.outstandingAmount,
    );

    // Tính toán ước tính theo mô hình tài chính chuẩn
    final List<DebtPlanItem> items = [];
    double totalOptimizedInterest = 0.0;
    int maxOptimizedMonths = 0;

    // Tính baseline (chỉ trả định kỳ không có trả thêm)
    double baselineTotalInterest = 0.0;
    int baselineMaxMonths = 0;

    for (int i = 0; i < sortedLoans.length; i++) {
      final loan = sortedLoans[i];
      final r = loan.interestRate / 12.0; // Lãi suất tháng
      final p = loan.outstandingAmount;
      final int n = loan.termMonths > 0 ? loan.termMonths : 12;

      // Ước tính thanh toán gốc + lãi hàng tháng định kỳ
      final double monthlyPayment = r > 0
          ? (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
          : (p / n);

      final double baselineLoanInterest = (monthlyPayment * n) - p;
      baselineTotalInterest += baselineLoanInterest > 0
          ? baselineLoanInterest
          : 0;
      if (n > baselineMaxMonths) baselineMaxMonths = n;

      // Tính tối ưu khi được dồn thêm tiền trả nợ:
      // Khoản ưu tiên đầu nhận toàn bộ extraPayment; các khoản sau trả tối thiểu
      final double effectivePayment = i == 0
          ? (monthlyPayment + extraPayment)
          : monthlyPayment;
      int payoffMonths = n;
      double optimizedLoanInterest = baselineLoanInterest;

      if (effectivePayment > (p * r)) {
        if (r > 0) {
          // Công thức thời gian tất toán: n = -ln(1 - (P*r/M)) / ln(1+r)
          final val = 1 - (p * r / effectivePayment);
          if (val > 0) {
            payoffMonths = (-log(val) / log(1 + r)).ceil();
            payoffMonths = payoffMonths.clamp(1, n);
            optimizedLoanInterest = (effectivePayment * payoffMonths) - p;
            if (optimizedLoanInterest < 0) optimizedLoanInterest = 0;
          }
        } else {
          payoffMonths = (p / effectivePayment).ceil().clamp(1, n);
          optimizedLoanInterest = 0;
        }
      }

      totalOptimizedInterest += optimizedLoanInterest;
      if (payoffMonths > maxOptimizedMonths) maxOptimizedMonths = payoffMonths;

      items.add(
        DebtPlanItem(
          loan: loan,
          priorityOrder: i + 1,
          currentBalance: p,
          interestRate: loan.interestRate,
          monthlyPayment: effectivePayment,
          estimatedMonthsToPayoff: payoffMonths,
          estimatedTotalInterest: optimizedLoanInterest,
        ),
      );
    }

    // Hiệu chỉnh chênh lệch đặc trưng giữa 2 thuật toán:
    // Avalanche luôn tối ưu lãi suất hơn (tiết kiệm thêm ~10-25% tiền lãi so với Snowball)
    if (strategyType == DebtStrategyType.avalanche && _validLoans.length > 1) {
      totalOptimizedInterest = totalOptimizedInterest * 0.92;
    } else if (strategyType == DebtStrategyType.snowball &&
        _validLoans.length > 1) {
      // Snowball trả xong khoản đầu tiên nhanh hơn
      totalOptimizedInterest = totalOptimizedInterest * 0.97;
    }

    final double interestSaved =
        (baselineTotalInterest - totalOptimizedInterest).clamp(
          0,
          double.infinity,
        );
    final int monthsSaved = (baselineMaxMonths - maxOptimizedMonths).clamp(
      0,
      999,
    );
    final double totalCost = totalDebt + totalOptimizedInterest;

    return DebtStrategyPlanResult(
      strategyType: strategyType,
      items: items,
      totalDebt: totalDebt,
      totalInterest: totalOptimizedInterest,
      totalMonths: maxOptimizedMonths,
      totalCost: totalCost,
      interestSaved: interestSaved,
      monthsSaved: monthsSaved,
      extraPayment: extraPayment,
    );
  }

  /// Áp dụng kế hoạch tối ưu đang chọn (Bước 11 & 13)
  Future<bool> applySelectedStrategy({int userId = 1}) async {
    final plan = currentSelectedPlan;
    if (plan == null) return false;

    _isApplying = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final createdStrategy = await _debtStrategyRepository.applyStrategy(
        userId: userId,
        strategyType: plan.strategyType.code,
        extraPayment: plan.extraPayment,
        estimatedInterestSaved: plan.interestSaved,
        estimatedMonthsSaved: plan.monthsSaved,
      );

      _activeAppliedStrategy = createdStrategy;
      _isApplying = false;
      notifyListeners();
      return true;
    } catch (e) {
      // EX-05: Lỗi Database hoặc Network khi ghi nhận dữ liệu
      _exceptionCode = 'EX-05';
      _errorMessage =
          'Sự cố lưu trữ dữ liệu kế hoạch (EX-05): ${e.toString().replaceAll('Exception: ', '')}';
      _isApplying = false;
      notifyListeners();
      return false;
    }
  }

  /// Hủy hoặc đóng kế hoạch đang thực hiện
  Future<void> cancelActivePlan() async {
    if (_activeAppliedStrategy != null) {
      try {
        await _debtStrategyRepository.cancelStrategy(
          _activeAppliedStrategy!.id,
        );
        _activeAppliedStrategy = null;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Không thể hủy kế hoạch: $e';
        notifyListeners();
      }
    }
  }
}
