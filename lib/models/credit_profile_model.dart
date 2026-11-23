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

  factory CreditProfileModel.fromJson(Map<String, dynamic> rawJson) {
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

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
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

    return CreditProfileModel(
      id: parseInt(json['profile_id'] ?? json['id']),
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
      activeLoanCount: parseInt(
        json['active_loan_count'] ?? json['activeLoanCount'],
      ),
      riskLevel: (json['risk_level'] ?? json['risk_tier'] ?? json['riskLevel'])
          ?.toString(),
      updatedAt: parseDate(
        json['updated_at'] ?? json['calculated_at'] ?? json['updatedAt'],
      ),
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

  CreditProfileModel copyWith({
    int? id,
    int? userId,
    int? creditScore,
    double? dtiRatio,
    bool clearDti = false,
    double? ltvRatio,
    bool clearLtv = false,
    double? creditUtilization,
    bool clearUtilization = false,
    double? onTimePaymentRate,
    bool clearPaymentRate = false,
    int? activeLoanCount,
    String? riskLevel,
    DateTime? updatedAt,
  }) {
    return CreditProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      creditScore: creditScore ?? this.creditScore,
      dtiRatio: clearDti ? null : (dtiRatio ?? this.dtiRatio),
      ltvRatio: clearLtv ? null : (ltvRatio ?? this.ltvRatio),
      creditUtilization: clearUtilization
          ? null
          : (creditUtilization ?? this.creditUtilization),
      onTimePaymentRate: clearPaymentRate
          ? null
          : (onTimePaymentRate ?? this.onTimePaymentRate),
      activeLoanCount: activeLoanCount ?? this.activeLoanCount,
      riskLevel: riskLevel ?? this.riskLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
