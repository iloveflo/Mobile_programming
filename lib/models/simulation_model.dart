/// 4 Kịch bản mô phỏng trả nợ theo tài liệu đặc tả
enum SimulationScenarioType {
  extraPayment(
    code: 'EXTRA_PAYMENT',
    title: 'Trả thêm một khoản',
    description:
        'Thanh toán bổ sung bớt nợ gốc để giảm tiền lãi và rút ngắn thời gian vay.',
  ),
  changePayment(
    code: 'CHANGE_PAYMENT',
    title: 'Đổi tiền trả mỗi kỳ',
    description:
        'Điều chỉnh số tiền thanh toán định kỳ hàng tháng để kiểm tra thời gian tất toán.',
  ),
  changeInterestRate(
    code: 'CHANGE_INTEREST_RATE',
    title: 'Thay đổi lãi suất',
    description:
        'Giả định sự biến động tăng/giảm lãi suất thị trường lên nghĩa vụ tài chính.',
  ),
  earlyPayoff(
    code: 'EARLY_PAYOFF',
    title: 'Trả trước hạn',
    description:
        'Tất toán toàn bộ khoản vay sớm để dự toán phí phạt và tiền lãi tiết kiệm được.',
  );

  final String code;
  final String title;
  final String description;

  const SimulationScenarioType({
    required this.code,
    required this.title,
    required this.description,
  });

  static SimulationScenarioType fromCode(String code) {
    for (final t in values) {
      if (t.code == code.toUpperCase()) return t;
    }
    return SimulationScenarioType.extraPayment;
  }
}

/// Mô hình Kịch bản Mô phỏng Trả nợ FinCredit (SimulationModel)
class SimulationModel {
  final int id;
  final int userId;
  final int loanId;
  final double extraPayment;
  final double earlyPaymentFee;
  final double estimatedInterest;
  final double estimatedInterestSaved;
  final int monthsReduced;
  final double totalSaving;
  final String scenarioType; // 'EXTRA_PAYMENT', 'CHANGE_PAYMENT', etc.
  final String? scenarioName;
  final String status; // 'SIMULATION_REFERENCE'
  final DateTime? createdAt;

  const SimulationModel({
    required this.id,
    required this.userId,
    required this.loanId,
    required this.extraPayment,
    required this.earlyPaymentFee,
    required this.estimatedInterest,
    required this.estimatedInterestSaved,
    required this.monthsReduced,
    required this.totalSaving,
    this.scenarioType = 'EXTRA_PAYMENT',
    this.scenarioName,
    this.status = 'SIMULATION_REFERENCE',
    this.createdAt,
  });

  SimulationScenarioType get type =>
      SimulationScenarioType.fromCode(scenarioType);

  factory SimulationModel.fromJson(Map<String, dynamic> json) {
    return SimulationModel(
      id: json['simulation_id'] as int? ?? json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 1,
      loanId: json['loan_id'] as int? ?? 0,
      extraPayment: (json['extra_payment'] as num?)?.toDouble() ?? 0,
      earlyPaymentFee: (json['early_payment_fee'] as num?)?.toDouble() ?? 0,
      estimatedInterest: (json['estimated_interest'] as num?)?.toDouble() ?? 0,
      estimatedInterestSaved:
          (json['estimated_interest_saved'] as num?)?.toDouble() ?? 0,
      monthsReduced: json['months_reduced'] as int? ?? 0,
      totalSaving: (json['total_saving'] as num?)?.toDouble() ?? 0,
      scenarioType:
          (json['scenario_type'] as String?)?.toUpperCase() ?? 'EXTRA_PAYMENT',
      scenarioName: json['scenario_name'] as String?,
      status: json['status'] as String? ?? 'SIMULATION_REFERENCE',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'simulation_id': id,
    'user_id': userId,
    'loan_id': loanId,
    'extra_payment': extraPayment,
    'early_payment_fee': earlyPaymentFee,
    'estimated_interest': estimatedInterest,
    'estimated_interest_saved': estimatedInterestSaved,
    'months_reduced': monthsReduced,
    'total_saving': totalSaving,
    'scenario_type': scenarioType,
    if (scenarioName != null) 'scenario_name': scenarioName,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  SimulationModel copyWith({
    int? id,
    int? userId,
    int? loanId,
    double? extraPayment,
    double? earlyPaymentFee,
    double? estimatedInterest,
    double? estimatedInterestSaved,
    int? monthsReduced,
    double? totalSaving,
    String? scenarioType,
    String? scenarioName,
    String? status,
    DateTime? createdAt,
  }) {
    return SimulationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loanId: loanId ?? this.loanId,
      extraPayment: extraPayment ?? this.extraPayment,
      earlyPaymentFee: earlyPaymentFee ?? this.earlyPaymentFee,
      estimatedInterest: estimatedInterest ?? this.estimatedInterest,
      estimatedInterestSaved:
          estimatedInterestSaved ?? this.estimatedInterestSaved,
      monthsReduced: monthsReduced ?? this.monthsReduced,
      totalSaving: totalSaving ?? this.totalSaving,
      scenarioType: scenarioType ?? this.scenarioType,
      scenarioName: scenarioName ?? this.scenarioName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Kết quả đối chiếu chi tiết giữa Kế hoạch hiện tại và Kịch bản mô phỏng (Mục 11)
class SimulationComparisonResult {
  final SimulationScenarioType scenarioType;
  final String loanName;

  // Dư nợ còn lại
  final double currentBalance;
  final double simulatedBalance;

  // Tổng lãi phải trả
  final double currentTotalInterest;
  final double simulatedTotalInterest;
  final double interestSaved;

  // Số kỳ thanh toán còn lại
  final int currentRemainingTerms;
  final int simulatedRemainingTerms;
  final int monthsReduced;

  // Số tiền trả mỗi kỳ
  final double currentMonthlyPayment;
  final double simulatedMonthlyPayment;

  // Lãi suất
  final double currentInterestRate;
  final double simulatedInterestRate;

  // Tổng số tiền phải trả (Gốc + Lãi + Phí)
  final double currentTotalPayment;
  final double simulatedTotalPayment;
  final double totalCostDifference;

  // Phí phát sinh (nếu có)
  final double currentFees;
  final double simulatedFees;

  // Thời gian tất toán dự kiến
  final DateTime currentPayoffDate;
  final DateTime simulatedPayoffDate;

  const SimulationComparisonResult({
    required this.scenarioType,
    required this.loanName,
    required this.currentBalance,
    required this.simulatedBalance,
    required this.currentTotalInterest,
    required this.simulatedTotalInterest,
    required this.interestSaved,
    required this.currentRemainingTerms,
    required this.simulatedRemainingTerms,
    required this.monthsReduced,
    required this.currentMonthlyPayment,
    required this.simulatedMonthlyPayment,
    required this.currentInterestRate,
    required this.simulatedInterestRate,
    required this.currentTotalPayment,
    required this.simulatedTotalPayment,
    required this.totalCostDifference,
    required this.currentFees,
    required this.simulatedFees,
    required this.currentPayoffDate,
    required this.simulatedPayoffDate,
  });
}
