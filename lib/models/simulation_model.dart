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
    this.createdAt,
  });

  factory SimulationModel.fromJson(Map<String, dynamic> json) {
    return SimulationModel(
      id: json['simulation_id'] as int,
      userId: json['user_id'] as int,
      loanId: json['loan_id'] as int,
      extraPayment: (json['extra_payment'] as num?)?.toDouble() ?? 0,
      earlyPaymentFee: (json['early_payment_fee'] as num?)?.toDouble() ?? 0,
      estimatedInterest: (json['estimated_interest'] as num?)?.toDouble() ?? 0,
      estimatedInterestSaved:
          (json['estimated_interest_saved'] as num?)?.toDouble() ?? 0,
      monthsReduced: json['months_reduced'] as int? ?? 0,
      totalSaving: (json['total_saving'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
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
    'created_at': createdAt?.toIso8601String(),
  };
}
