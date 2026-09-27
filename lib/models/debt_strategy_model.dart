class DebtStrategyModel {
  final int id;
  final int userId;
  final String strategyType;
  final double extraPayment;
  final double? estimatedInterestSaved;
  final int? estimatedMonthsSaved;
  final DateTime? createdAt;

  const DebtStrategyModel({
    required this.id,
    required this.userId,
    required this.strategyType,
    required this.extraPayment,
    this.estimatedInterestSaved,
    this.estimatedMonthsSaved,
    this.createdAt,
  });

  factory DebtStrategyModel.fromJson(Map<String, dynamic> json) {
    return DebtStrategyModel(
      id: json['strategy_id'] as int,
      userId: json['user_id'] as int,
      strategyType: json['strategy_type'] as String,
      extraPayment: (json['extra_payment'] as num?)?.toDouble() ?? 0,
      estimatedInterestSaved: (json['estimated_interest_saved'] as num?)
          ?.toDouble(),
      estimatedMonthsSaved: json['estimated_months_saved'] as int?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'strategy_id': id,
    'user_id': userId,
    'strategy_type': strategyType,
    'extra_payment': extraPayment,
    'estimated_interest_saved': estimatedInterestSaved,
    'estimated_months_saved': estimatedMonthsSaved,
    'created_at': createdAt?.toIso8601String(),
  };
}
