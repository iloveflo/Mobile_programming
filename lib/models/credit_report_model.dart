class CreditReportModel {
  final int id;
  final int userId;
  final int? creditScore;
  final double? dtiRatio;
  final double? ltvRatio;
  final double? creditUtilization;
  final double? onTimePaymentRate;
  final double totalDebt;
  final double overdueAmount;
  final String? riskLevel;
  final String? reportPeriod;
  final DateTime? generatedAt;

  const CreditReportModel({
    required this.id,
    required this.userId,
    this.creditScore,
    this.dtiRatio,
    this.ltvRatio,
    this.creditUtilization,
    this.onTimePaymentRate,
    required this.totalDebt,
    required this.overdueAmount,
    this.riskLevel,
    this.reportPeriod,
    this.generatedAt,
  });

  factory CreditReportModel.fromJson(Map<String, dynamic> json) {
    return CreditReportModel(
      id: json['report_id'] as int,
      userId: json['user_id'] as int,
      creditScore: json['credit_score'] as int?,
      dtiRatio: (json['dti_ratio'] as num?)?.toDouble(),
      ltvRatio: (json['ltv_ratio'] as num?)?.toDouble(),
      creditUtilization: (json['credit_utilization'] as num?)?.toDouble(),
      onTimePaymentRate: (json['on_time_payment_rate'] as num?)?.toDouble(),
      totalDebt: (json['total_debt'] as num?)?.toDouble() ?? 0,
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0,
      riskLevel: json['risk_level'] as String?,
      reportPeriod: json['report_period'] as String?,
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.parse(json['generated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'report_id': id,
    'user_id': userId,
    'credit_score': creditScore,
    'dti_ratio': dtiRatio,
    'ltv_ratio': ltvRatio,
    'credit_utilization': creditUtilization,
    'on_time_payment_rate': onTimePaymentRate,
    'total_debt': totalDebt,
    'overdue_amount': overdueAmount,
    'risk_level': riskLevel,
    'report_period': reportPeriod,
    'generated_at': generatedAt?.toIso8601String(),
  };

  CreditReportModel copyWith({
    int? id,
    int? userId,
    int? creditScore,
    double? dtiRatio,
    double? ltvRatio,
    double? creditUtilization,
    double? onTimePaymentRate,
    double? totalDebt,
    double? overdueAmount,
    String? riskLevel,
    String? reportPeriod,
    DateTime? generatedAt,
    bool clearScore = false,
    bool clearDti = false,
    bool clearLtv = false,
    bool clearUtilization = false,
    bool clearOnTime = false,
  }) {
    return CreditReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditScore: clearScore ? null : (creditScore ?? this.creditScore),
      dtiRatio: clearDti ? null : (dtiRatio ?? this.dtiRatio),
      ltvRatio: clearLtv ? null : (ltvRatio ?? this.ltvRatio),
      creditUtilization: clearUtilization
          ? null
          : (creditUtilization ?? this.creditUtilization),
      onTimePaymentRate: clearOnTime
          ? null
          : (onTimePaymentRate ?? this.onTimePaymentRate),
      totalDebt: totalDebt ?? this.totalDebt,
      overdueAmount: overdueAmount ?? this.overdueAmount,
      riskLevel: riskLevel ?? this.riskLevel,
      reportPeriod: reportPeriod ?? this.reportPeriod,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
