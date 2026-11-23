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

  factory CreditReportModel.fromJson(Map<String, dynamic> rawJson) {
    final dynamic nested = rawJson['data'];
    final Map<String, dynamic> json = nested is Map<String, dynamic>
        ? nested
        : (nested is Map ? Map<String, dynamic>.from(nested) : rawJson);

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val, [double? fallback]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      return DateTime.tryParse(val.toString())?.toLocal();
    }

    final bool isBackendDto =
        json.containsKey('risk_tier') || json.containsKey('calculated_at');
    double? normalizeRatio(double? v) =>
        (v != null && (isBackendDto || v > 1.5)) ? v / 100.0 : v;

    return CreditReportModel(
      id: parseInt(json['report_id'] ?? json['id']),
      userId: parseInt(json['user_id'] ?? json['userId']),
      creditScore: parseNullableInt(
        json['credit_score'] ?? json['creditScore'],
      ),
      dtiRatio: normalizeRatio(
        parseDouble(json['dti_ratio'] ?? json['dtiRatio']),
      ),
      ltvRatio: normalizeRatio(
        parseDouble(json['ltv_ratio'] ?? json['ltvRatio']),
      ),
      creditUtilization: parseDouble(
        json['credit_utilization'] ??
            json['creditUtilization'] ??
            json['credit_utilization_ratio'],
      ),
      onTimePaymentRate: parseDouble(
        json['on_time_payment_rate'] ??
            json['onTimePaymentRate'] ??
            json['payment_history_score'],
      ),
      totalDebt:
          parseDouble(json['total_debt'] ?? json['totalDebt'], 0.0) ?? 0.0,
      overdueAmount:
          parseDouble(json['overdue_amount'] ?? json['overdueAmount'], 0.0) ??
          0.0,
      riskLevel: (json['risk_level'] ?? json['risk_tier'] ?? json['riskLevel'])
          ?.toString(),
      reportPeriod: (json['report_period'] ?? json['reportPeriod'])?.toString(),
      generatedAt: parseDate(
        json['generated_at'] ?? json['calculated_at'] ?? json['generatedAt'],
      ),
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
