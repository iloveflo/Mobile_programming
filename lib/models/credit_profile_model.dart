class CreditProfileModel {
  final int id;
  final int userId;
  final int? creditScore;
  final double? dtiRatio;
  final double? ltvRatio;
  final double? creditUtilization;
  final double? onTimePaymentRate;
  final int activeLoanCount;
  final String? riskLevel;
  final DateTime? updatedAt;

  const CreditProfileModel({
    required this.id,
    required this.userId,
    this.creditScore,
    this.dtiRatio,
    this.ltvRatio,
    this.creditUtilization,
    this.onTimePaymentRate,
    required this.activeLoanCount,
    this.riskLevel,
    this.updatedAt,
  });

  factory CreditProfileModel.fromJson(Map<String, dynamic> json) {
    return CreditProfileModel(
      id: json['profile_id'] as int,
      userId: json['user_id'] as int,
      creditScore: json['credit_score'] as int?,
      dtiRatio: (json['dti_ratio'] as num?)?.toDouble(),
      ltvRatio: (json['ltv_ratio'] as num?)?.toDouble(),
      creditUtilization: (json['credit_utilization'] as num?)?.toDouble(),
      onTimePaymentRate: (json['on_time_payment_rate'] as num?)?.toDouble(),
      activeLoanCount: json['active_loan_count'] as int? ?? 0,
      riskLevel: json['risk_level'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'profile_id': id,
    'user_id': userId,
    'credit_score': creditScore,
    'dti_ratio': dtiRatio,
    'ltv_ratio': ltvRatio,
    'credit_utilization': creditUtilization,
    'on_time_payment_rate': onTimePaymentRate,
    'active_loan_count': activeLoanCount,
    'risk_level': riskLevel,
    'updated_at': updatedAt?.toIso8601String(),
  };
}
