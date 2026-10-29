import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/loan_model.dart';
import '../models/simulation_model.dart';
import '../repositories/interfaces/loan_repository.dart';
import '../repositories/interfaces/simulation_repository.dart';

/// Bộ điều khiển trung tâm quản lý luồng nghiệp vụ Mô phỏng trả nợ (SimulationController)
class SimulationController extends ChangeNotifier {
  final SimulationRepository _simulationRepository;
  final LoanRepository _loanRepository;

  SimulationController(this._simulationRepository, this._loanRepository);

  // ================= Quản lý Trạng thái =================
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _exceptionCode; // 'EX-01', 'EX-02', 'EX-03', 'EX-04', 'EX-05'

  final List<LoanModel> _validLoans = [];
  LoanModel? _selectedLoan;

  SimulationScenarioType _selectedScenario =
      SimulationScenarioType.extraPayment;

  // Tham số giả định theo 4 kịch bản (Mục 5.2)
  double _extraPayment = 20000000.0; // Kịch bản 1: Trả thêm 20 triệu
  double _newMonthlyPayment = 7000000.0; // Kịch bản 2: Đổi sang 7 triệu/kỳ
  double _newInterestRate = 0.08; // Kịch bản 3: Lãi suất giả định 8%/năm
  int _earlyPayoffMonths = 12; // Kịch bản 4: Mốc tất toán sớm sau 12 tháng
  double _earlyPaymentFeeRate = 0.015; // Kịch bản 4: Phí phạt trả sớm 1.5%

  SimulationComparisonResult? _comparisonResult;
  final List<SimulationModel> _savedSimulations = [];

  // ================= Getters =================
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get exceptionCode => _exceptionCode;

  List<LoanModel> get validLoans => List.unmodifiable(_validLoans);
  LoanModel? get selectedLoan => _selectedLoan;
  SimulationScenarioType get selectedScenario => _selectedScenario;

  double get extraPayment => _extraPayment;
  double get newMonthlyPayment => _newMonthlyPayment;
  double get newInterestRate => _newInterestRate;
  int get earlyPayoffMonths => _earlyPayoffMonths;
  double get earlyPaymentFeeRate => _earlyPaymentFeeRate;

  SimulationComparisonResult? get comparisonResult => _comparisonResult;
  List<SimulationModel> get savedSimulations =>
      List.unmodifiable(_savedSimulations);

  // ================= Tải dữ liệu ban đầu =================
  Future<void> loadData({int? preferredLoanId, int userId = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final allLoans = await _loanRepository.getLoans();
      _validLoans.clear();

      for (final loan in allLoans) {
        if (loan.status.toUpperCase() != 'CLOSED' &&
            loan.outstandingAmount > 0) {
          _validLoans.add(loan);
        }
      }

      // EX-01: Không có khoản vay khả dụng
      if (_validLoans.isEmpty) {
        _exceptionCode = 'EX-01';
        _errorMessage = 'Chưa có khoản vay nào khả dụng để thực hiện mô phỏng.';
        _selectedLoan = null;
        _comparisonResult = null;
        return;
      }

      // Chọn khoản vay ưu tiên hoặc mặc định khoản đầu tiên
      if (preferredLoanId != null) {
        _selectedLoan = _validLoans.firstWhere(
          (l) => l.id == preferredLoanId,
          orElse: () => _validLoans.first,
        );
      } else {
        _selectedLoan = _validLoans.first;
      }

      _syncDefaultInputsForSelectedLoan();

      // Tải danh sách kịch bản đã lưu (SIMULATION_REFERENCE)
      _savedSimulations.clear();
      final loadedSims = await _simulationRepository.getSimulations(
        userId: userId,
      );
      _savedSimulations.addAll(loadedSims);

      // Tính toán mô phỏng
      _calculateSimulation();
    } catch (e) {
      _exceptionCode = 'EX-04';
      _errorMessage =
          'Lỗi tính toán mô phỏng: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= Thao tác chọn và gán tham số =================

  void selectLoan(LoanModel loan) {
    if (_selectedLoan?.id != loan.id) {
      _selectedLoan = loan;
      _syncDefaultInputsForSelectedLoan();
      _calculateSimulation();
      notifyListeners();
    }
  }

  void selectScenario(SimulationScenarioType scenario) {
    if (_selectedScenario != scenario) {
      _selectedScenario = scenario;
      _calculateSimulation();
      notifyListeners();
    }
  }

  void setExtraPayment(double amount) {
    _extraPayment = amount;
    _calculateSimulation();
    notifyListeners();
  }

  void setNewMonthlyPayment(double amount) {
    _newMonthlyPayment = amount;
    _calculateSimulation();
    notifyListeners();
  }

  void setNewInterestRate(double rate) {
    _newInterestRate = rate;
    _calculateSimulation();
    notifyListeners();
  }

  void setEarlyPayoffMonths(int months) {
    _earlyPayoffMonths = months;
    _calculateSimulation();
    notifyListeners();
  }

  void setEarlyPaymentFeeRate(double feeRate) {
    _earlyPaymentFeeRate = feeRate;
    _calculateSimulation();
    notifyListeners();
  }

  void _syncDefaultInputsForSelectedLoan() {
    final loan = _selectedLoan;
    if (loan == null) return;

    // Gợi ý trả thêm bằng 10% dư nợ hoặc tối đa 20tr
    _extraPayment = min(
      20000000.0,
      (loan.outstandingAmount * 0.1).clamp(1000000.0, loan.outstandingAmount),
    );

    // Tiền trả hàng tháng ước tính hiện tại
    final r = loan.interestRate / 12.0;
    final p = loan.outstandingAmount;
    final n = loan.termMonths > 0 ? loan.termMonths : 12;
    final double baselineMonthly = r > 0
        ? (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        : (p / n);

    _newMonthlyPayment = (baselineMonthly * 1.25)
        .roundToDouble(); // Gợi ý trả tăng 25%
    _newInterestRate = (loan.interestRate - 0.015).clamp(
      0.01,
      0.40,
    ); // Gợi ý giảm 1.5%
    _earlyPayoffMonths = (n / 2).ceil().clamp(1, n);
    _earlyPaymentFeeRate = loan.earlyPaymentFeeRate;
  }

  // ================= Thuật toán Tính toán Mô phỏng (Mục 7, 8, 9, 10, 11) =================

  void _calculateSimulation() {
    _exceptionCode = null;
    _errorMessage = null;

    final loan = _selectedLoan;
    if (loan == null) {
      _comparisonResult = null;
      return;
    }

    // EX-02: Kiểm tra dữ liệu khoản vay cơ sở
    if (loan.outstandingAmount <= 0 ||
        loan.termMonths <= 0 ||
        loan.interestRate < 0) {
      _exceptionCode = 'EX-02';
      _errorMessage =
          'Khoản vay bị thiếu dữ liệu cơ sở (lãi suất, kỳ hạn hoặc dư nợ không hợp lệ).';
      _comparisonResult = null;
      return;
    }

    final double p = loan.outstandingAmount;
    final double r = loan.interestRate / 12.0;
    final int n = loan.termMonths;

    // Tính toán kế hoạch hiện tại (Baseline)
    final double baselineMonthly = r > 0
        ? (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1)
        : (p / n);
    final double baselineTotalInterest = max(0.0, (baselineMonthly * n) - p);
    final double baselineTotalPayment = p + baselineTotalInterest;
    final DateTime baselinePayoffDate = loan.startDate.add(
      Duration(days: n * 30),
    );

    try {
      switch (_selectedScenario) {
        // -------------------------------------------------------------
        // Kịch bản 1: Trả thêm một khoản (Mục 7)
        // -------------------------------------------------------------
        case SimulationScenarioType.extraPayment:
          // EX-03: Kiểm tra tính hợp lệ
          if (_extraPayment <= 0 || _extraPayment > p) {
            _exceptionCode = 'EX-03';
            _errorMessage =
                'Số tiền trả thêm phải lớn hơn 0 và không được vượt quá dư nợ hiện tại.';
            _comparisonResult = null;
            return;
          }

          final double newBalance = p - _extraPayment;
          int simMonths = n;
          double simTotalInterest = 0.0;

          if (newBalance > 0 && r > 0) {
            // Giữ nguyên mức trả định kỳ baselineMonthly, tính số kỳ rút ngắn
            final val = 1 - (newBalance * r / baselineMonthly);
            if (val > 0) {
              simMonths = (-log(val) / log(1 + r)).ceil().clamp(1, n);
              simTotalInterest = max(
                0.0,
                (baselineMonthly * simMonths) - newBalance,
              );
            }
          }

          final double interestSaved = max(
            0.0,
            baselineTotalInterest - simTotalInterest,
          );
          final int monthsReduced = max(0, n - simMonths);
          final double simTotalPayment =
              p + simTotalInterest; // Gốc P + Lãi mới
          final double totalDiff = baselineTotalPayment - simTotalPayment;

          _comparisonResult = SimulationComparisonResult(
            scenarioType: _selectedScenario,
            loanName: loan.name,
            currentBalance: p,
            simulatedBalance: newBalance,
            currentTotalInterest: baselineTotalInterest,
            simulatedTotalInterest: simTotalInterest,
            interestSaved: interestSaved,
            currentRemainingTerms: n,
            simulatedRemainingTerms: simMonths,
            monthsReduced: monthsReduced,
            currentMonthlyPayment: baselineMonthly,
            simulatedMonthlyPayment: baselineMonthly,
            currentInterestRate: loan.interestRate,
            simulatedInterestRate: loan.interestRate,
            currentTotalPayment: baselineTotalPayment,
            simulatedTotalPayment: simTotalPayment,
            totalCostDifference: totalDiff,
            currentFees: 0.0,
            simulatedFees: 0.0,
            currentPayoffDate: baselinePayoffDate,
            simulatedPayoffDate: loan.startDate.add(
              Duration(days: simMonths * 30),
            ),
          );
          break;

        // -------------------------------------------------------------
        // Kịch bản 2: Thay đổi số tiền trả mỗi kỳ (Mục 8)
        // -------------------------------------------------------------
        case SimulationScenarioType.changePayment:
          final double minInterestPerMonth = p * r;
          if (_newMonthlyPayment <= minInterestPerMonth) {
            _exceptionCode = 'EX-03';
            _errorMessage =
                'Số tiền trả mỗi kỳ không đủ bù tiền lãi phát sinh mỗi tháng (${minInterestPerMonth.round()} đ).';
            _comparisonResult = null;
            return;
          }

          int simMonths = n;
          double simTotalInterest = 0.0;

          if (r > 0) {
            final val = 1 - (p * r / _newMonthlyPayment);
            if (val > 0) {
              simMonths = (-log(val) / log(1 + r)).ceil().clamp(1, 480);
              simTotalInterest = max(0.0, (_newMonthlyPayment * simMonths) - p);
            }
          } else {
            simMonths = (p / _newMonthlyPayment).ceil();
          }

          final double interestSaved = baselineTotalInterest - simTotalInterest;
          final int monthsReduced = n - simMonths;
          final double simTotalPayment = p + simTotalInterest;
          final double totalDiff = baselineTotalPayment - simTotalPayment;

          _comparisonResult = SimulationComparisonResult(
            scenarioType: _selectedScenario,
            loanName: loan.name,
            currentBalance: p,
            simulatedBalance: p,
            currentTotalInterest: baselineTotalInterest,
            simulatedTotalInterest: simTotalInterest,
            interestSaved: interestSaved,
            currentRemainingTerms: n,
            simulatedRemainingTerms: simMonths,
            monthsReduced: monthsReduced,
            currentMonthlyPayment: baselineMonthly,
            simulatedMonthlyPayment: _newMonthlyPayment,
            currentInterestRate: loan.interestRate,
            simulatedInterestRate: loan.interestRate,
            currentTotalPayment: baselineTotalPayment,
            simulatedTotalPayment: simTotalPayment,
            totalCostDifference: totalDiff,
            currentFees: 0.0,
            simulatedFees: 0.0,
            currentPayoffDate: baselinePayoffDate,
            simulatedPayoffDate: loan.startDate.add(
              Duration(days: simMonths * 30),
            ),
          );
          break;

        // -------------------------------------------------------------
        // Kịch bản 3: Thay đổi lãi suất (Mục 9)
        // -------------------------------------------------------------
        case SimulationScenarioType.changeInterestRate:
          if (_newInterestRate <= 0 || _newInterestRate > 1.0) {
            _exceptionCode = 'EX-03';
            _errorMessage =
                'Tỷ lệ lãi suất giả định phải nằm trong khoảng từ 0.1% đến 100%/năm.';
            _comparisonResult = null;
            return;
          }

          final double newR = _newInterestRate / 12.0;
          final double simMonthly = newR > 0
              ? (p * newR * pow(1 + newR, n)) / (pow(1 + newR, n) - 1)
              : (p / n);
          final double simTotalInterest = max(0.0, (simMonthly * n) - p);
          final double simTotalPayment = p + simTotalInterest;
          final double interestSaved = baselineTotalInterest - simTotalInterest;
          final double totalDiff = baselineTotalPayment - simTotalPayment;

          _comparisonResult = SimulationComparisonResult(
            scenarioType: _selectedScenario,
            loanName: loan.name,
            currentBalance: p,
            simulatedBalance: p,
            currentTotalInterest: baselineTotalInterest,
            simulatedTotalInterest: simTotalInterest,
            interestSaved: interestSaved,
            currentRemainingTerms: n,
            simulatedRemainingTerms: n,
            monthsReduced: 0,
            currentMonthlyPayment: baselineMonthly,
            simulatedMonthlyPayment: simMonthly,
            currentInterestRate: loan.interestRate,
            simulatedInterestRate: _newInterestRate,
            currentTotalPayment: baselineTotalPayment,
            simulatedTotalPayment: simTotalPayment,
            totalCostDifference: totalDiff,
            currentFees: 0.0,
            simulatedFees: 0.0,
            currentPayoffDate: baselinePayoffDate,
            simulatedPayoffDate: baselinePayoffDate,
          );
          break;

        // -------------------------------------------------------------
        // Kịch bản 4: Trả trước hạn (Mục 10)
        // -------------------------------------------------------------
        case SimulationScenarioType.earlyPayoff:
          if (_earlyPayoffMonths <= 0 || _earlyPayoffMonths >= n) {
            _exceptionCode = 'EX-03';
            _errorMessage =
                'Thời điểm tất toán sớm phải từ kỳ 1 đến kỳ ${n - 1}.';
            _comparisonResult = null;
            return;
          }

          // Dư nợ còn lại tại thời điểm tất toán sớm
          double balanceAtEarlyPayoff = p;
          double interestPaidUntilPayoff = 0.0;
          for (int m = 1; m <= _earlyPayoffMonths; m++) {
            final double monthlyInterest = balanceAtEarlyPayoff * r;
            final double principalPortion = baselineMonthly - monthlyInterest;
            interestPaidUntilPayoff += monthlyInterest;
            balanceAtEarlyPayoff = max(
              0.0,
              balanceAtEarlyPayoff - principalPortion,
            );
          }

          final double earlyFee = balanceAtEarlyPayoff * _earlyPaymentFeeRate;
          final double totalSimPayment =
              (baselineMonthly * _earlyPayoffMonths) +
              balanceAtEarlyPayoff +
              earlyFee;
          final double interestWillSave = max(
            0.0,
            baselineTotalPayment - totalSimPayment,
          );
          final double totalDiff = baselineTotalPayment - totalSimPayment;

          _comparisonResult = SimulationComparisonResult(
            scenarioType: _selectedScenario,
            loanName: loan.name,
            currentBalance: p,
            simulatedBalance: 0.0, // Tất toán toàn bộ
            currentTotalInterest: baselineTotalInterest,
            simulatedTotalInterest: interestPaidUntilPayoff,
            interestSaved: interestWillSave,
            currentRemainingTerms: n,
            simulatedRemainingTerms: _earlyPayoffMonths,
            monthsReduced: n - _earlyPayoffMonths,
            currentMonthlyPayment: baselineMonthly,
            simulatedMonthlyPayment: baselineMonthly,
            currentInterestRate: loan.interestRate,
            simulatedInterestRate: loan.interestRate,
            currentTotalPayment: baselineTotalPayment,
            simulatedTotalPayment: totalSimPayment,
            totalCostDifference: totalDiff,
            currentFees: 0.0,
            simulatedFees: earlyFee,
            currentPayoffDate: baselinePayoffDate,
            simulatedPayoffDate: loan.startDate.add(
              Duration(days: _earlyPayoffMonths * 30),
            ),
          );
          break;
      }
    } catch (e) {
      _exceptionCode = 'EX-04';
      _errorMessage = 'Lỗi ngoại lệ trong thuật toán tính toán: $e';
      _comparisonResult = null;
    }
  }

  // ================= Lưu kịch bản tham khảo (Mục 12) =================

  Future<bool> saveCurrentSimulation({
    String? customName,
    int userId = 1,
  }) async {
    final comp = _comparisonResult;
    final loan = _selectedLoan;
    if (comp == null || loan == null) return false;

    _isSaving = true;
    _errorMessage = null;
    _exceptionCode = null;
    notifyListeners();

    try {
      final name = customName ?? '${comp.scenarioType.title} - ${loan.name}';
      final model = SimulationModel(
        id: 0,
        userId: userId,
        loanId: loan.id,
        extraPayment: _extraPayment,
        earlyPaymentFee: comp.simulatedFees,
        estimatedInterest: comp.simulatedTotalInterest,
        estimatedInterestSaved: comp.interestSaved,
        monthsReduced: comp.monthsReduced,
        totalSaving: comp.totalCostDifference > 0
            ? comp.totalCostDifference
            : 0,
        scenarioType: comp.scenarioType.code,
        scenarioName: name,
        status: 'SIMULATION_REFERENCE',
        createdAt: DateTime.now(),
      );

      final saved = await _simulationRepository.saveSimulation(model);
      _savedSimulations.insert(0, saved);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      // EX-05: Sự cố Backend / Database khi lưu kịch bản
      _exceptionCode = 'EX-05';
      _errorMessage =
          '[EX-05] Sự cố lưu trữ kịch bản tham khảo: ${e.toString().replaceAll('Exception: ', '')}';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteSimulation(int simulationId) async {
    try {
      await _simulationRepository.deleteSimulation(simulationId);
      _savedSimulations.removeWhere((s) => s.id == simulationId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Không thể xóa kịch bản: $e';
      notifyListeners();
    }
  }
}
