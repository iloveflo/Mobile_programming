import 'loan_model.dart';

/// Loại chiến lược tối ưu trả nợ
enum DebtStrategyType {
  snowball(
    code: 'SNOWBALL',
    title: 'Snowball (Dư nợ nhỏ trước)',
    description:
        'Ưu tiên trả khoản nợ có quy mô nhỏ nhất trước để giải phóng áp lực tâm lý.',
  ),
  avalanche(
    code: 'AVALANCHE',
    title: 'Avalanche (Lãi suất cao trước)',
    description:
        'Ưu tiên trả khoản nợ có mức lãi suất cao nhất trước để tiết kiệm tiền lãi tối đa.',
  );

  final String code;
  final String title;
  final String description;

  const DebtStrategyType({
    required this.code,
    required this.title,
    required this.description,
  });

  static DebtStrategyType fromCode(String code) {
    if (code.toUpperCase() == 'SNOWBALL') return DebtStrategyType.snowball;
    return DebtStrategyType.avalanche;
  }
}

/// Mô hình Kế hoạch Chiến lược Tối ưu Trả nợ FinCredit
class DebtStrategyModel {
  final int id;
  final int userId;
  final String strategyType;
  final double extraPayment;
  final double? estimatedInterestSaved;
  final int? estimatedMonthsSaved;
  final String status; // 'ACTIVE', 'INACTIVE', 'CANCELLED'
  final DateTime? createdAt;

  const DebtStrategyModel({
    required this.id,
    required this.userId,
    required this.strategyType,
    required this.extraPayment,
    this.estimatedInterestSaved,
    this.estimatedMonthsSaved,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  DebtStrategyType get type => DebtStrategyType.fromCode(strategyType);

  factory DebtStrategyModel.fromJson(Map<String, dynamic> json) {
    return DebtStrategyModel(
      id: json['strategy_id'] as int? ?? json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 1,
      strategyType:
          (json['strategy_type'] as String?)?.toUpperCase() ?? 'AVALANCHE',
      extraPayment: (json['extra_payment'] as num?)?.toDouble() ?? 0,
      estimatedInterestSaved: (json['estimated_interest_saved'] as num?)
          ?.toDouble(),
      estimatedMonthsSaved: json['estimated_months_saved'] as int?,
      status: (json['status'] as String?)?.toUpperCase() ?? 'ACTIVE',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'strategy_id': id,
    'user_id': userId,
    'strategy_type': strategyType,
    'extra_payment': extraPayment,
    'estimated_interest_saved': estimatedInterestSaved,
    'estimated_months_saved': estimatedMonthsSaved,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  DebtStrategyModel copyWith({
    int? id,
    int? userId,
    String? strategyType,
    double? extraPayment,
    double? estimatedInterestSaved,
    int? estimatedMonthsSaved,
    String? status,
    DateTime? createdAt,
  }) {
    return DebtStrategyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      strategyType: strategyType ?? this.strategyType,
      extraPayment: extraPayment ?? this.extraPayment,
      estimatedInterestSaved:
          estimatedInterestSaved ?? this.estimatedInterestSaved,
      estimatedMonthsSaved: estimatedMonthsSaved ?? this.estimatedMonthsSaved,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Từng mục khoản nợ trong kế hoạch phân bổ ưu tiên
class DebtPlanItem {
  final LoanModel loan;
  final int priorityOrder;
  final double currentBalance;
  final double interestRate;
  final double monthlyPayment;
  final int estimatedMonthsToPayoff;
  final double estimatedTotalInterest;

  const DebtPlanItem({
    required this.loan,
    required this.priorityOrder,
    required this.currentBalance,
    required this.interestRate,
    required this.monthlyPayment,
    required this.estimatedMonthsToPayoff,
    required this.estimatedTotalInterest,
  });
}

/// Kết quả phân tích mô phỏng chiến lược tối ưu hoàn chỉnh
class DebtStrategyPlanResult {
  final DebtStrategyType strategyType;
  final List<DebtPlanItem> items;
  final double totalDebt;
  final double totalInterest;
  final int totalMonths;
  final double totalCost;
  final double interestSaved;
  final int monthsSaved;
  final double extraPayment;

  const DebtStrategyPlanResult({
    required this.strategyType,
    required this.items,
    required this.totalDebt,
    required this.totalInterest,
    required this.totalMonths,
    required this.totalCost,
    required this.interestSaved,
    required this.monthsSaved,
    required this.extraPayment,
  });

  /// Khoản nợ đang đứng ưu tiên số 1
  DebtPlanItem? get primaryTarget => items.isNotEmpty ? items.first : null;
}
